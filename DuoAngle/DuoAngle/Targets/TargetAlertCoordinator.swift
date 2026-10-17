import Foundation
import Observation

@MainActor
final class TargetAlertCoordinator {
    private let haptics: any TargetHapticProviding
    private let cooldown: TimeInterval
    private var lastAlertTimestamp: Date?

    init(haptics: any TargetHapticProviding, cooldown: TimeInterval = 0.5) {
        self.haptics = haptics
        self.cooldown = cooldown
    }

    func handle(_ events: [TargetReachedEvent]) -> TargetReachedEvent? {
        guard let selected = events.min(by: Self.hasHigherPriority) else { return nil }
        if let lastAlertTimestamp,
           selected.timestamp.timeIntervalSince(lastAlertTimestamp) < cooldown {
            return nil
        }
        lastAlertTimestamp = selected.timestamp
        haptics.notifyTargetReached()
        return selected
    }

    func reset() {
        lastAlertTimestamp = nil
    }

    private static func hasHigherPriority(_ lhs: TargetReachedEvent, _ rhs: TargetReachedEvent) -> Bool {
        let lhsDistance = abs(lhs.measuredAngle - lhs.targetAngle)
        let rhsDistance = abs(rhs.measuredAngle - rhs.targetAngle)
        if lhsDistance != rhsDistance { return lhsDistance < rhsDistance }
        return lhs.targetID.uuidString < rhs.targetID.uuidString
    }
}

@MainActor
@Observable
final class TargetReachedFeedbackState {
    private(set) var event: TargetReachedEvent?
    private(set) var presentationID = UUID()

    var isVisible: Bool { event != nil }

    @discardableResult
    func present(_ event: TargetReachedEvent) -> UUID {
        let id = UUID()
        self.event = event
        presentationID = id
        return id
    }

    func dismiss(ifPresentationID id: UUID) {
        guard presentationID == id else { return }
        event = nil
    }

    func reset() {
        event = nil
        presentationID = UUID()
    }
}
