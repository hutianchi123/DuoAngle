import Foundation

nonisolated struct TargetMonitoringConfiguration: Equatable, Sendable {
    static let `default` = TargetMonitoringConfiguration(
        hitTolerance: 1,
        rearmDistance: 3,
        maximumCrossingInterval: 0.35,
        maximumCrossingDisplacement: 12
    )

    let hitTolerance: Double
    let rearmDistance: Double
    let maximumCrossingInterval: TimeInterval
    let maximumCrossingDisplacement: Double

    init(
        hitTolerance: Double,
        rearmDistance: Double,
        maximumCrossingInterval: TimeInterval,
        maximumCrossingDisplacement: Double
    ) {
        precondition(hitTolerance >= 0)
        precondition(rearmDistance > hitTolerance)
        precondition(maximumCrossingInterval > 0)
        precondition(maximumCrossingDisplacement > 0)
        self.hitTolerance = hitTolerance
        self.rearmDistance = rearmDistance
        self.maximumCrossingInterval = maximumCrossingInterval
        self.maximumCrossingDisplacement = maximumCrossingDisplacement
    }
}

nonisolated enum TargetReachedReason: Equatable, Sendable {
    case enteredTolerance
    case crossedBetweenSamples
}

nonisolated struct TargetReachedEvent: Equatable, Sendable {
    let targetID: UUID
    let targetAngle: Double
    let measuredAngle: Double
    let timestamp: Date
    let reason: TargetReachedReason
}

nonisolated struct TargetMonitor {
    private static let comparisonEpsilon = 1e-10
    private enum Phase {
        case awaitingBaseline
        case armed
        case fired
    }

    private struct TargetState {
        var angle: Double
        var phase: Phase
    }

    private struct Sample {
        let angle: Double
        let timestamp: Date
    }

    private let configuration: TargetMonitoringConfiguration
    private var activeSessionID: UUID?
    private var targetStates: [UUID: TargetState] = [:]
    private var previousSample: Sample?

    init(configuration: TargetMonitoringConfiguration = .default) {
        self.configuration = configuration
    }

    mutating func beginSession(_ sessionID: UUID) {
        activeSessionID = sessionID
        targetStates.removeAll(keepingCapacity: true)
        previousSample = nil
    }

    mutating func endSession() {
        activeSessionID = nil
        targetStates.removeAll(keepingCapacity: true)
        previousSample = nil
    }

    mutating func invalidateObservation() {
        targetStates.removeAll(keepingCapacity: true)
        previousSample = nil
    }

    mutating func synchronizeTargets(_ targets: [AngleTarget], baseline: HingeMeasurementSnapshot?) {
        let sample = baseline.flatMap(Self.validSample(from:))
        _ = reconcile(targets: targets, baseline: sample)
    }

    mutating func process(
        sample snapshot: HingeMeasurementSnapshot,
        targets: [AngleTarget],
        sessionID: UUID
    ) -> [TargetReachedEvent] {
        guard sessionID == activeSessionID else { return [] }
        guard let current = Self.validSample(from: snapshot) else {
            invalidateObservation()
            return []
        }
        if let previousSample, current.timestamp <= previousSample.timestamp {
            return []
        }

        let initializedTargetIDs = reconcile(targets: targets, baseline: current)
        var events: [TargetReachedEvent] = []

        for target in targets where target.isEnabled {
            guard !initializedTargetIDs.contains(target.id), var state = targetStates[target.id] else { continue }
            let distance = abs(current.angle - state.angle)

            switch state.phase {
            case .awaitingBaseline:
                state.phase = Self.initialPhase(distance: distance, configuration: configuration)
            case .fired:
                if distance + Self.comparisonEpsilon >= configuration.rearmDistance {
                    state.phase = .armed
                }
            case .armed:
                let reason: TargetReachedReason?
                if distance <= configuration.hitTolerance + Self.comparisonEpsilon {
                    reason = .enteredTolerance
                } else if safelyCrossed(target: state.angle, from: previousSample, to: current) {
                    reason = .crossedBetweenSamples
                } else {
                    reason = nil
                }

                if let reason {
                    events.append(TargetReachedEvent(
                        targetID: target.id,
                        targetAngle: state.angle,
                        measuredAngle: current.angle,
                        timestamp: current.timestamp,
                        reason: reason
                    ))
                    state.phase = .fired
                }
            }

            targetStates[target.id] = state
        }

        previousSample = current
        return events
    }

    private mutating func reconcile(targets: [AngleTarget], baseline: Sample?) -> Set<UUID> {
        let enabledTargets = targets.filter(\.isEnabled)
        let enabledIDs = Set(enabledTargets.map(\.id))
        targetStates = targetStates.filter { enabledIDs.contains($0.key) }
        var initialized: Set<UUID> = []

        for target in enabledTargets {
            let angle = Double(target.angle)
            guard targetStates[target.id]?.angle == angle else {
                let phase: Phase
                if let baseline {
                    phase = Self.initialPhase(
                        distance: abs(baseline.angle - angle),
                        configuration: configuration
                    )
                } else {
                    phase = .awaitingBaseline
                }
                targetStates[target.id] = TargetState(angle: angle, phase: phase)
                initialized.insert(target.id)
                continue
            }
        }

        return initialized
    }

    private func safelyCrossed(target: Double, from previous: Sample?, to current: Sample) -> Bool {
        guard let previous else { return false }
        let elapsed = current.timestamp.timeIntervalSince(previous.timestamp)
        guard elapsed > 0, elapsed <= configuration.maximumCrossingInterval else { return false }
        guard abs(current.angle - previous.angle) <= configuration.maximumCrossingDisplacement else { return false }
        return min(previous.angle, current.angle) <= target && target <= max(previous.angle, current.angle)
    }

    private static func initialPhase(
        distance: Double,
        configuration: TargetMonitoringConfiguration
    ) -> Phase {
        distance <= configuration.hitTolerance + comparisonEpsilon ? .fired : .armed
    }

    private static func validSample(from snapshot: HingeMeasurementSnapshot) -> Sample? {
        guard snapshot.isAvailable,
              snapshot.status == .partiallyOpen || snapshot.status == .fullyOpen,
              let angle = snapshot.angleDegrees,
              angle.isFinite,
              angle >= Double(AngleTarget.validAngles.lowerBound),
              angle <= Double(AngleTarget.validAngles.upperBound) else {
            return nil
        }
        return Sample(angle: angle, timestamp: snapshot.timestamp)
    }
}
