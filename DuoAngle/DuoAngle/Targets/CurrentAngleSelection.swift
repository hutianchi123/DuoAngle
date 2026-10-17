import Foundation

enum CurrentAngleSelection {
    static func angle(from snapshot: HingeMeasurementSnapshot) -> Int? {
        guard snapshot.isAvailable,
              snapshot.status == .partiallyOpen || snapshot.status == .fullyOpen,
              let degrees = snapshot.angleDegrees,
              degrees.isFinite,
              (Double(AngleTarget.validAngles.lowerBound)...Double(AngleTarget.validAngles.upperBound)).contains(degrees) else { return nil }
        return Int(degrees.rounded())
    }
}
