import StoreKit

struct SupportProductDetails: Equatable, Sendable {
    let id: String
    let displayPrice: String
    let isConsumable: Bool
}

struct SupportTransactionDelivery: Equatable, Sendable {
    let id: UInt64
    let productID: String
    let isVerified: Bool
}

enum SupportPurchaseOutcome: Equatable, Sendable {
    case success(SupportTransactionDelivery)
    case pending
    case userCancelled
}

@MainActor
protocol SupportPurchaseServicing: AnyObject {
    func loadProduct(identifier: String) async throws -> SupportProductDetails?
    func purchase(productID: String) async throws -> SupportPurchaseOutcome
    func unfinishedTransactions() async -> [SupportTransactionDelivery]
    func transactionUpdates() -> AsyncStream<SupportTransactionDelivery>
    func finish(transactionID: UInt64) async
    func discard(transactionID: UInt64)
}

@MainActor
final class StoreKitSupportPurchaseService: SupportPurchaseServicing {
    private var products: [String: Product] = [:]
    private var verifiedTransactions: [UInt64: Transaction] = [:]

    func loadProduct(identifier: String) async throws -> SupportProductDetails? {
        let loadedProducts = try await Product.products(for: [identifier])
        guard let product = loadedProducts.first(where: { $0.id == identifier }) else {
            return nil
        }
        products[identifier] = product
        return SupportProductDetails(
            id: product.id,
            displayPrice: product.displayPrice,
            isConsumable: product.type == .consumable
        )
    }

    func purchase(productID: String) async throws -> SupportPurchaseOutcome {
        let product: Product
        if let cachedProduct = products[productID] {
            product = cachedProduct
        } else if let loadedProduct = try await loadAndCacheProduct(identifier: productID) {
            product = loadedProduct
        } else {
            throw SupportPurchaseServiceError.productUnavailable
        }

        switch try await product.purchase() {
        case .success(let verification):
            return .success(delivery(from: verification))
        case .pending:
            return .pending
        case .userCancelled:
            return .userCancelled
        @unknown default:
            throw SupportPurchaseServiceError.unknownPurchaseResult
        }
    }

    func unfinishedTransactions() async -> [SupportTransactionDelivery] {
        var deliveries: [SupportTransactionDelivery] = []
        for await verification in Transaction.unfinished {
            deliveries.append(delivery(from: verification))
        }
        return deliveries
    }

    func transactionUpdates() -> AsyncStream<SupportTransactionDelivery> {
        AsyncStream { continuation in
            let task = Task { @MainActor [weak self] in
                guard let self else {
                    continuation.finish()
                    return
                }
                for await verification in Transaction.updates {
                    guard !Task.isCancelled else { break }
                    continuation.yield(delivery(from: verification))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func finish(transactionID: UInt64) async {
        guard let transaction = verifiedTransactions.removeValue(forKey: transactionID) else { return }
        await transaction.finish()
    }

    func discard(transactionID: UInt64) {
        verifiedTransactions.removeValue(forKey: transactionID)
    }

    private func loadAndCacheProduct(identifier: String) async throws -> Product? {
        let loadedProducts = try await Product.products(for: [identifier])
        guard let product = loadedProducts.first(where: { $0.id == identifier }) else { return nil }
        products[identifier] = product
        return product
    }

    private func delivery(from result: VerificationResult<Transaction>) -> SupportTransactionDelivery {
        switch result {
        case .verified(let transaction):
            if transaction.productID == SupportProductConfiguration.productID {
                verifiedTransactions[transaction.id] = transaction
            }
            return SupportTransactionDelivery(
                id: transaction.id,
                productID: transaction.productID,
                isVerified: true
            )
        case .unverified(let transaction, _):
            return SupportTransactionDelivery(
                id: transaction.id,
                productID: transaction.productID,
                isVerified: false
            )
        }
    }
}

private enum SupportPurchaseServiceError: Error {
    case productUnavailable
    case unknownPurchaseResult
}

#if DEBUG
@MainActor
final class UITestSupportPurchaseService: SupportPurchaseServicing {
    private var nextTransactionID: UInt64 = 1

    func loadProduct(identifier: String) async throws -> SupportProductDetails? {
        SupportProductDetails(id: identifier, displayPrice: "¥5.00", isConsumable: true)
    }

    func purchase(productID: String) async throws -> SupportPurchaseOutcome {
        defer { nextTransactionID += 1 }
        return .success(.init(id: nextTransactionID, productID: productID, isVerified: true))
    }

    func unfinishedTransactions() async -> [SupportTransactionDelivery] { [] }

    func transactionUpdates() -> AsyncStream<SupportTransactionDelivery> {
        AsyncStream { _ in }
    }

    func finish(transactionID: UInt64) async {}
    func discard(transactionID: UInt64) {}
}
#endif
