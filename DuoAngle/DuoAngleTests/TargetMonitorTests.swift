import Foundation
import Testing
@testable import DuoAngle

struct TargetMonitorTests {
    private let session = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!

    private func target(_ angle: Int, id: UUID = UUID(), enabled: Bool = true) -> AngleTarget {
        AngleTarget(id: id, angle: angle, isEnabled: enabled)
    }

    private func sample(_ degrees: Double?, at seconds: TimeInterval, status: HingeStatus = .partiallyOpen) -> HingeMeasurementSnapshot {
        HingeMeasurementSnapshot(
            angleRadians: degrees.map(AngleMath.radians(fromDegrees:)),
            status: status,
            timestamp: Date(timeIntervalSinceReferenceDate: seconds),
            isAvailable: degrees != nil
        )
    }

    private func startedMonitor() -> TargetMonitor {
        var monitor = TargetMonitor()
        monitor.beginSession(session)
        return monitor
    }

    @Test(arguments: [89.0, 90.0, 91.0, 90.125])
    func inclusiveToleranceAndFloatingPointSamplesTrigger(degrees: Double) {
        let item = target(90)
        var monitor = startedMonitor()
        #expect(monitor.process(sample: sample(85, at: 0), targets: [item], sessionID: session).isEmpty)

        let events = monitor.process(sample: sample(degrees, at: 0.1), targets: [item], sessionID: session)

        #expect(events.count == 1)
        #expect(events.first?.targetID == item.id)
        #expect(events.first?.measuredAngle == degrees)
        #expect(events.first?.reason == .enteredTolerance)
    }

    @Test func justOutsideToleranceDoesNotTrigger() {
        let item = target(90)
        var belowMonitor = startedMonitor()
        _ = belowMonitor.process(sample: sample(85, at: 0), targets: [item], sessionID: session)
        #expect(belowMonitor.process(sample: sample(88.999, at: 0.1), targets: [item], sessionID: session).isEmpty)

        var aboveMonitor = startedMonitor()
        _ = aboveMonitor.process(sample: sample(95, at: 0), targets: [item], sessionID: session)
        #expect(aboveMonitor.process(sample: sample(91.001, at: 0.1), targets: [item], sessionID: session).isEmpty)
    }

    @Test func repeatedSamplesRequireRearmBoundaryBeforeSecondEvent() {
        let item = target(90)
        var monitor = startedMonitor()
        _ = monitor.process(sample: sample(85, at: 0), targets: [item], sessionID: session)
        #expect(monitor.process(sample: sample(90, at: 0.1), targets: [item], sessionID: session).count == 1)
        #expect(monitor.process(sample: sample(90.5, at: 0.2), targets: [item], sessionID: session).isEmpty)
        #expect(monitor.process(sample: sample(89.7, at: 0.3), targets: [item], sessionID: session).isEmpty)
        #expect(monitor.process(sample: sample(92.999, at: 0.4), targets: [item], sessionID: session).isEmpty)
        #expect(monitor.process(sample: sample(93, at: 0.5), targets: [item], sessionID: session).isEmpty)
        #expect(monitor.process(sample: sample(90, at: 0.6), targets: [item], sessionID: session).count == 1)
    }

    @Test func firstSampleInsideAndNewOrEditedTargetInsideDoNotTrigger() {
        let id = UUID()
        var item = target(90, id: id)
        var monitor = startedMonitor()
        #expect(monitor.process(sample: sample(90, at: 0), targets: [item], sessionID: session).isEmpty)
        #expect(monitor.process(sample: sample(90.2, at: 0.1), targets: [item], sessionID: session).isEmpty)
        _ = monitor.process(sample: sample(94, at: 0.2), targets: [item], sessionID: session)
        #expect(monitor.process(sample: sample(90, at: 0.3), targets: [item], sessionID: session).count == 1)

        item.angle = 100
        #expect(monitor.process(sample: sample(100, at: 0.4), targets: [item], sessionID: session).isEmpty)
        #expect(monitor.process(sample: sample(100.5, at: 0.5), targets: [item], sessionID: session).isEmpty)
    }

    @Test func enablingTargetAtCurrentAngleRequiresExitAndReentry() {
        let id = UUID()
        var monitor = startedMonitor()
        #expect(monitor.process(sample: sample(90, at: 0), targets: [], sessionID: session).isEmpty)
        let item = target(90, id: id)
        monitor.synchronizeTargets([item], baseline: sample(90, at: 0))
        #expect(monitor.process(sample: sample(90, at: 0.1), targets: [item], sessionID: session).isEmpty)
        _ = monitor.process(sample: sample(93, at: 0.2), targets: [item], sessionID: session)
        #expect(monitor.process(sample: sample(90, at: 0.3), targets: [item], sessionID: session).count == 1)
    }

    @Test(arguments: [(88.6, 91.8), (91.8, 88.6)])
    func boundedCrossingTriggersInBothDirections(pair: (Double, Double)) {
        let item = target(90)
        var monitor = startedMonitor()
        _ = monitor.process(sample: sample(pair.0, at: 0), targets: [item], sessionID: session)

        let events = monitor.process(sample: sample(pair.1, at: 0.1), targets: [item], sessionID: session)

        #expect(events.count == 1)
        #expect(events.first?.reason == .crossedBetweenSamples)
    }

    @Test func uncertainCrossingsAndNonMonotonicSamplesAreRejected() {
        let item = target(90)
        var jumpMonitor = startedMonitor()
        _ = jumpMonitor.process(sample: sample(30, at: 0), targets: [item], sessionID: session)
        #expect(jumpMonitor.process(sample: sample(150, at: 0.1), targets: [item], sessionID: session).isEmpty)

        var slowMonitor = startedMonitor()
        _ = slowMonitor.process(sample: sample(88.6, at: 0), targets: [item], sessionID: session)
        #expect(slowMonitor.process(sample: sample(91.8, at: 1), targets: [item], sessionID: session).isEmpty)

        var reversedTimeMonitor = startedMonitor()
        _ = reversedTimeMonitor.process(sample: sample(88.6, at: 1), targets: [item], sessionID: session)
        #expect(reversedTimeMonitor.process(sample: sample(91.8, at: 0.9), targets: [item], sessionID: session).isEmpty)
    }

    @Test func nonMonotonicDirectHitIsRejectedWithoutChangingState() {
        let item = target(90)
        var monitor = startedMonitor()
        _ = monitor.process(sample: sample(85, at: 10), targets: [item], sessionID: session)
        #expect(monitor.process(sample: sample(90, at: 9), targets: [item], sessionID: session).isEmpty)
        #expect(monitor.process(sample: sample(90, at: 10.1), targets: [item], sessionID: session).count == 1)
    }

    @Test func extremelyLargeFiniteAngleIsRejectedWithoutIntegerConversion() {
        let item = target(90)
        var monitor = startedMonitor()
        #expect(monitor.process(sample: sample(1e20, at: 0), targets: [item], sessionID: session).isEmpty)
        #expect(monitor.process(sample: sample(90, at: 0.1), targets: [item], sessionID: session).isEmpty)
    }

    @Test func invalidMeasurementBreaksCrossingContinuityAndRequiresFreshBaseline() {
        let item = target(90)
        var monitor = startedMonitor()
        _ = monitor.process(sample: sample(88.6, at: 0), targets: [item], sessionID: session)
        #expect(monitor.process(sample: sample(nil, at: 0.1, status: .unknown), targets: [item], sessionID: session).isEmpty)
        #expect(monitor.process(sample: sample(91.8, at: 0.2), targets: [item], sessionID: session).isEmpty)
        #expect(monitor.process(sample: sample(90, at: 0.3), targets: [item], sessionID: session).count == 1)
    }

    @Test(arguments: [HingeStatus.closed, .unknown])
    func closedAndUnknownStatesInvalidateMonitoring(status: HingeStatus) {
        let item = target(90)
        var monitor = startedMonitor()
        _ = monitor.process(sample: sample(85, at: 0), targets: [item], sessionID: session)
        #expect(monitor.process(sample: sample(nil, at: 0.1, status: status), targets: [item], sessionID: session).isEmpty)
        #expect(monitor.process(sample: sample(90, at: 0.2), targets: [item], sessionID: session).isEmpty)
    }

    @Test func resumedSessionTreatsCurrentAngleAsABaseline() {
        let item = target(90)
        var monitor = startedMonitor()
        _ = monitor.process(sample: sample(85, at: 0), targets: [item], sessionID: session)
        monitor.endSession()
        let resumedSession = UUID()
        monitor.beginSession(resumedSession)
        #expect(monitor.process(sample: sample(90, at: 1), targets: [item], sessionID: resumedSession).isEmpty)
        _ = monitor.process(sample: sample(93, at: 1.1), targets: [item], sessionID: resumedSession)
        #expect(monitor.process(sample: sample(90, at: 1.2), targets: [item], sessionID: resumedSession).count == 1)
    }

    @Test func disabledTargetsAndOldSessionsNeverEmit() {
        let disabled = target(90, enabled: false)
        var monitor = startedMonitor()
        _ = monitor.process(sample: sample(85, at: 0), targets: [disabled], sessionID: session)
        #expect(monitor.process(sample: sample(90, at: 0.1), targets: [disabled], sessionID: session).isEmpty)
        let enabled = target(90)
        #expect(monitor.process(sample: sample(85, at: 0.2), targets: [enabled], sessionID: UUID()).isEmpty)
        #expect(monitor.process(sample: sample(90, at: 0.3), targets: [enabled], sessionID: UUID()).isEmpty)
    }

    @Test func targetsMaintainIndependentArmedState() {
        let lower = target(45)
        let upper = target(90)
        var monitor = startedMonitor()
        _ = monitor.process(sample: sample(40, at: 0), targets: [lower, upper], sessionID: session)
        #expect(monitor.process(sample: sample(45, at: 0.1), targets: [lower, upper], sessionID: session).map(\.targetID) == [lower.id])
        #expect(monitor.process(sample: sample(90, at: 0.2), targets: [lower, upper], sessionID: session).map(\.targetID) == [upper.id])
    }
}

@MainActor
struct TargetAlertCoordinatorTests {
    private final class HapticSpy: TargetHapticProviding {
        private(set) var requestCount = 0
        func notifyTargetReached() { requestCount += 1 }
    }

    private func event(id: UUID, target: Double, measured: Double, time: TimeInterval) -> TargetReachedEvent {
        TargetReachedEvent(
            targetID: id,
            targetAngle: target,
            measuredAngle: measured,
            timestamp: Date(timeIntervalSinceReferenceDate: time),
            reason: .enteredTolerance
        )
    }

    @Test func closestTargetWinsWithStableUUIDTieBreakAndOneHaptic() {
        let haptics = HapticSpy()
        let coordinator = TargetAlertCoordinator(haptics: haptics)
        let firstID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let secondID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let selected = coordinator.handle([
            event(id: secondID, target: 91, measured: 90, time: 1),
            event(id: firstID, target: 89, measured: 90, time: 1)
        ])
        #expect(selected?.targetID == firstID)
        #expect(haptics.requestCount == 1)
    }

    @Test func cooldownSuppressesBurstWithoutInventingAnEvent() {
        let haptics = HapticSpy()
        let coordinator = TargetAlertCoordinator(haptics: haptics)
        let first = event(id: UUID(), target: 45, measured: 45, time: 1)
        let second = event(id: UUID(), target: 90, measured: 90, time: 1.2)
        #expect(coordinator.handle([first]) == first)
        #expect(coordinator.handle([second]) == nil)
        #expect(haptics.requestCount == 1)
    }

    @Test func lifecycleResetClearsCooldown() {
        let haptics = HapticSpy()
        let coordinator = TargetAlertCoordinator(haptics: haptics)
        let first = event(id: UUID(), target: 45, measured: 45, time: 1)
        let resumed = event(id: UUID(), target: 90, measured: 90, time: 1.1)
        #expect(coordinator.handle([first]) == first)
        coordinator.reset()
        #expect(coordinator.handle([resumed]) == resumed)
        #expect(haptics.requestCount == 2)
    }

    @Test func feedbackStateTracksOnlyRealSelectedEvent() {
        let feedback = TargetReachedFeedbackState()
        let reached = event(id: UUID(), target: 90, measured: 90.2, time: 1)
        let token = feedback.present(reached)
        #expect(feedback.isVisible)
        #expect(feedback.event == reached)
        feedback.dismiss(ifPresentationID: UUID())
        #expect(feedback.isVisible)
        feedback.dismiss(ifPresentationID: token)
        #expect(!feedback.isVisible)
        #expect(feedback.event == nil)
    }
}
