import Foundation
import Testing
@testable import DuoAngle

@MainActor
struct SupportProductManagerTests {
    @Test func loadsLocalizedProductPrice() async {
        let service = SupportPurchaseServiceFake()
        service.loadResults = [.success(.init(id: SupportProductConfiguration.productID, displayPrice: "¥5.00", isConsumable: true))]
        let manager = SupportProductManager(service: service)

        await manager.loadProduct()

        #expect(manager.state == .productAvailable)
        #expect(manager.localizedPrice == "¥5.00")
    }

    @Test func unavailableProductCanBeRetried() async {
        let service = SupportPurchaseServiceFake()
        service.loadResults = [
            .success(nil),
            .success(.init(id: SupportProductConfiguration.productID, displayPrice: "CN¥5.00", isConsumable: true))
        ]
        let manager = SupportProductManager(service: service)

        await manager.loadProduct()
        #expect(manager.state == .unavailable)
        #expect(manager.localizedPrice == nil)

        await manager.retryLoadingProduct()
        #expect(manager.state == .productAvailable)
        #expect(manager.localizedPrice == "CN¥5.00")
    }

    @Test func verifiedPurchaseSucceedsAndFinishesOnce() async {
        let service = configuredService()
        service.purchaseResults = [.success(.success(.init(id: 101, productID: SupportProductConfiguration.productID, isVerified: true)))]
        let manager = SupportProductManager(service: service)
        await manager.loadProduct()

        await manager.purchase()

        #expect(manager.state == .succeeded)
        #expect(service.finishedTransactionIDs == [101])
    }

    @Test func unverifiedPurchaseIsRejectedWithoutFinishing() async {
        let service = configuredService()
        service.purchaseResults = [.success(.success(.init(id: 102, productID: SupportProductConfiguration.productID, isVerified: false)))]
        let manager = SupportProductManager(service: service)
        await manager.loadProduct()

        await manager.purchase()

        #expect(manager.state == .failed(message: "购买无法验证，请稍后重试"))
        #expect(service.finishedTransactionIDs.isEmpty)
    }

    @Test func pendingPurchaseDoesNotReportSuccess() async {
        let service = configuredService()
        service.purchaseResults = [.success(.pending)]
        let manager = SupportProductManager(service: service)
        await manager.loadProduct()

        await manager.purchase()

        #expect(manager.state == .pending)
        #expect(service.finishedTransactionIDs.isEmpty)
    }

    @Test func cancellationReturnsSilentlyToProduct() async {
        let service = configuredService()
        service.purchaseResults = [.success(.userCancelled)]
        let manager = SupportProductManager(service: service)
        await manager.loadProduct()

        await manager.purchase()

        #expect(manager.state == .productAvailable)
        #expect(manager.errorMessage == nil)
    }

    @Test func purchaseErrorShowsSafeMessage() async {
        let service = configuredService()
        service.purchaseResults = [.failure(TestFailure())]
        let manager = SupportProductManager(service: service)
        await manager.loadProduct()

        await manager.purchase()

        #expect(manager.state == .failed(message: "购买未能完成，请稍后重试"))
    }

    @Test func duplicatePurchaseTapIsIgnoredWhilePurchasing() async {
        let service = configuredService()
        service.suspendPurchase = true
        let manager = SupportProductManager(service: service)
        await manager.loadProduct()

        let firstPurchase = Task { await manager.purchase() }
        await Task.yield()
        await manager.purchase()
        #expect(service.purchaseCallCount == 1)

        service.resumePurchase(with: .success(.init(id: 103, productID: SupportProductConfiguration.productID, isVerified: true)))
        await firstPurchase.value
    }

    @Test func repeatPurchaseIsAllowedAfterAcknowledgingSuccess() async {
        let service = configuredService()
        service.purchaseResults = [
            .success(.success(.init(id: 104, productID: SupportProductConfiguration.productID, isVerified: true))),
            .success(.success(.init(id: 105, productID: SupportProductConfiguration.productID, isVerified: true)))
        ]
        let manager = SupportProductManager(service: service)
        await manager.loadProduct()

        await manager.purchase()
        manager.acknowledgeSuccess()
        await manager.purchase()

        #expect(manager.state == .succeeded)
        #expect(service.finishedTransactionIDs == [104, 105])
    }

    @Test func duplicateTransactionDeliveriesAreProcessedOnce() async {
        let service = configuredService()
        let transaction = SupportTransactionDelivery(id: 106, productID: SupportProductConfiguration.productID, isVerified: true)
        service.purchaseResults = [.success(.success(transaction))]
        let manager = SupportProductManager(service: service)
        await manager.loadProduct()

        await manager.purchase()
        await manager.handleTransactionUpdate(transaction)

        #expect(service.finishedTransactionIDs == [106])
    }

    @Test func productLoadDoesNotOverwriteVerifiedUpdate() async {
        let service = SupportPurchaseServiceFake()
        service.suspendLoad = true
        let manager = SupportProductManager(service: service)

        let loading = Task { await manager.loadProduct() }
        while service.loadCallCount == 0 { await Task.yield() }
        #expect(manager.state == .loadingProduct)
        await manager.handleTransactionUpdate(.init(
            id: 109,
            productID: SupportProductConfiguration.productID,
            isVerified: true
        ))
        #expect(manager.state == .succeeded)
        service.resumeLoad(with: .init(
            id: SupportProductConfiguration.productID,
            displayPrice: "¥5.00",
            isConsumable: true
        ))
        await loading.value

        #expect(manager.state == .succeeded)
        #expect(manager.localizedPrice == "¥5.00")
        #expect(service.finishedTransactionIDs == [109])
    }

    @Test func startHandlesUnfinishedTransactionsAndStopCancelsListener() async {
        let service = configuredService()
        service.unfinished = [
            .init(id: 107, productID: SupportProductConfiguration.productID, isVerified: true),
            .init(id: 108, productID: SupportProductConfiguration.productID, isVerified: false)
        ]
        let manager = SupportProductManager(service: service)

        await manager.start()
        while !service.listenerStarted { await Task.yield() }
        #expect(service.finishedTransactionIDs == [107])
        #expect(manager.state != .succeeded)

        manager.stop()
        for _ in 0..<10 where !service.listenerWasCancelled { await Task.yield() }
        #expect(service.listenerWasCancelled)
    }

    private func configuredService() -> SupportPurchaseServiceFake {
        let service = SupportPurchaseServiceFake()
        service.loadResults = [.success(.init(id: SupportProductConfiguration.productID, displayPrice: "¥5.00", isConsumable: true))]
        return service
    }
}

private struct TestFailure: Error {}

@MainActor
private final class SupportPurchaseServiceFake: SupportPurchaseServicing {
    var loadResults: [Result<SupportProductDetails?, Error>] = []
    var purchaseResults: [Result<SupportPurchaseOutcome, Error>] = []
    var unfinished: [SupportTransactionDelivery] = []
    var finishedTransactionIDs: [UInt64] = []
    var purchaseCallCount = 0
    var loadCallCount = 0
    var suspendLoad = false
    var suspendPurchase = false
    var listenerStarted = false
    var listenerWasCancelled = false

    private var purchaseContinuation: CheckedContinuation<SupportPurchaseOutcome, Error>?
    private var loadContinuation: CheckedContinuation<SupportProductDetails?, Error>?

    func loadProduct(identifier: String) async throws -> SupportProductDetails? {
        loadCallCount += 1
        if suspendLoad {
            return try await withCheckedThrowingContinuation { loadContinuation = $0 }
        }
        return try loadResults.removeFirst().get()
    }

    func purchase(productID: String) async throws -> SupportPurchaseOutcome {
        purchaseCallCount += 1
        if suspendPurchase {
            return try await withCheckedThrowingContinuation { purchaseContinuation = $0 }
        }
        return try purchaseResults.removeFirst().get()
    }

    func unfinishedTransactions() async -> [SupportTransactionDelivery] {
        unfinished
    }

    func transactionUpdates() -> AsyncStream<SupportTransactionDelivery> {
        listenerStarted = true
        return AsyncStream { continuation in
            continuation.onTermination = { [self] _ in
                Task { @MainActor in listenerWasCancelled = true }
            }
        }
    }

    func finish(transactionID: UInt64) async {
        finishedTransactionIDs.append(transactionID)
    }

    func discard(transactionID: UInt64) {}

    func resumePurchase(with result: SupportPurchaseOutcome) {
        suspendPurchase = false
        purchaseContinuation?.resume(returning: result)
        purchaseContinuation = nil
    }

    func resumeLoad(with product: SupportProductDetails?) {
        suspendLoad = false
        loadContinuation?.resume(returning: product)
        loadContinuation = nil
    }
}
