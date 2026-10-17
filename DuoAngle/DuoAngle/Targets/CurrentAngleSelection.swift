import Foundation

enum CurrentAngleSelection {
    static let maximumAge: TimeInterval = 10

    static func angle(
        from snapshot: HingeMeasurementSnapshot,
        lastUpdate: Date?,
        now: Date = .now
    ) -> Int? {
        guard snapshot.isAvailable,
              snapshot.status == .partiallyOpen || snapshot.status == .fullyOpen,
              let lastUpdate,
              (0...maximumAge).contains(now.timeIntervalSince(lastUpdate)),
              let degrees = snapshot.angleDegrees,
              degrees.isFinite,
              (-0.001...180.001).contains(degrees) else { return nil }
        return Int(AngleMath.clampedDegrees(degrees).rounded())
    }
}
