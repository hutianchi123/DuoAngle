import Foundation
import Observation
import OSLog

enum SupportPurchaseState: Equatable {
    case idle
    case loadingProduct
    case productAvailable
    case purchasing
    case pending
    case succeeded
    case failed(message: String)
    case unavailable
}

@Observable
@MainActor
final class SupportProductManager {
    private(set) var state: SupportPurchaseState = .idle
    private(set) var product: SupportProductDetails?

    var localizedPrice: String? { product?.displayPrice }

    var errorMessage: String? {
        guard case .failed(let message) = state else { return nil }
        return message
    }

    private let service: any SupportPurchaseServicing
    private let logger = Logger(subsystem: "com.TNTstudio.DuoAngle", category: "SupportPurchase")
    private var processedTransactionIDs: Set<UInt64> = []
    private var listenerTask: Task<Void, Never>?
    private var isStarted = false

    init() {
        self.service = StoreKitSupportPurchaseService()
    }

    init(service: any SupportPurchaseServicing) {
        self.service = service
    }

    func start() async {
        guard !isStarted else { return }
        isStarted = true
        listenerTask = Task { [weak self] in
            guard let self else { return }
            for await transaction in service.transactionUpdates() {
                guard !Task.isCancelled else { return }
                await handleTransactionUpdate(transaction)
            }
        }

        let unfinished = await service.unfinishedTransactions()
        for transaction in unfinished {
            await process(transaction, presentsSuccess: false)
        }
    }

    func stop() {
        listenerTask?.cancel()
        listenerTask = nil
        isStarted = false
    }

    func loadProduct() async {
        guard state != .loadingProduct, state != .purchasing else { return }
        state = .loadingProduct
        do {
            guard let loadedProduct = try await service.loadProduct(identifier: SupportProductConfiguration.productID),
                  loadedProduct.id == SupportProductConfiguration.productID,
                  loadedProduct.isConsumable else {
                if state == .loadingProduct {
                    product = nil
                    state = .unavailable
                }
                return
            }
            product = loadedProduct
            if state == .loadingProduct {
                state = .productAvailable
            }
        } catch {
            logger.error("Support product loading failed: \(String(describing: type(of: error)), privacy: .public)")
            if state == .loadingProduct {
                product = nil
                state = .unavailable
            }
        }
    }

    func retryLoadingProduct() async {
        await loadProduct()
    }

    func purchase() async {
        guard product != nil,
              state != .loadingProduct,
              state != .purchasing,
              state != .pending else { return }

        state = .purchasing
        do {
            switch try await service.purchase(productID: SupportProductConfiguration.productID) {
            case .success(let transaction):
                await process(transaction, presentsSuccess: true)
            case .pending:
                state = .pending
            case .userCancelled:
                state = .productAvailable
            }
        } catch {
            logger.error("Support purchase failed: \(String(describing: type(of: error)), privacy: .public)")
            state = .failed(message: String(localized: "购买未能完成，请稍后重试"))
        }
    }

    func acknowledgeSuccess() {
        guard state == .succeeded else { return }
        state = product == nil ? .idle : .productAvailable
    }

    func handleTransactionUpdate(_ transaction: SupportTransactionDelivery) async {
        await process(transaction, presentsSuccess: true)
    }

    private func process(_ transaction: SupportTransactionDelivery, presentsSuccess: Bool) async {
        guard transaction.productID == SupportProductConfiguration.productID else { return }
        guard transaction.isVerified else {
            logger.error("Rejected an unverified support transaction")
            if presentsSuccess {
                state = .failed(message: String(localized: "购买无法验证，请稍后重试"))
            }
            return
        }
        guard processedTransactionIDs.insert(transaction.id).inserted else {
            service.discard(transactionID: transaction.id)
            return
        }

        await service.finish(transactionID: transaction.id)
        if presentsSuccess {
            state = .succeeded
        }
    }
}
