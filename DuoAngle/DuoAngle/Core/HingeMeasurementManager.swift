import Foundation
import Observation
import os

@MainActor
@Observable
final class HingeMeasurementManager {
    private(set) var snapshot = HingeMeasurementSnapshot(
        angleRadians: nil,
        status: .unknown,
        timestamp: .now,
        isAvailable: false
    )
    private(set) var updateCount = 0
    private(set) var lastUpdate: Date?

    @ObservationIgnored private let logger = Logger(subsystem: "DuoAngle", category: "Hinge")

    var displayText: String {
        if snapshot.status == .closed { return String(localized: "请展开以测量角度") }
        guard snapshot.isAvailable, let degrees = snapshot.angleDegrees, degrees.isFinite else {
            return String(localized: "角度暂不可用")
        }
        return "\(Int(degrees.rounded()))°"
    }

    func receive(angleRadians: Double?, status: HingeStatus) {
        updateCount += 1
        lastUpdate = .now

        let validAngle = status == .closed ? nil : angleRadians.flatMap { $0.isFinite ? $0 : nil }
        let available = validAngle != nil
        guard snapshot.status != status || snapshot.angleRadians != validAngle || snapshot.isAvailable != available else {
            return
        }

        if snapshot.status != status {
            logger.info("Hinge state changed: \(self.snapshot.status.rawValue, privacy: .public) to \(status.rawValue, privacy: .public)")
        }
        snapshot = HingeMeasurementSnapshot(
            angleRadians: validAngle,
            status: status,
            timestamp: .now,
            isAvailable: available
        )
    }

    func clear() {
        receive(angleRadians: nil, status: .unknown)
    }
}
