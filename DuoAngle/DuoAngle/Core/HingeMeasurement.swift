import Foundation

nonisolated enum HingeStatus: String, Equatable, Sendable {
    case unknown
    case closed
    case partiallyOpen
    case fullyOpen
}

nonisolated struct HingeMeasurementSnapshot: Equatable, Sendable {
    let angleRadians: Double?
    let status: HingeStatus
    let timestamp: Date
    let isAvailable: Bool

    var angleDegrees: Double? {
        angleRadians.map(AngleMath.degrees(fromRadians:))
    }
}

@MainActor
protocol HingeMeasurementProviding: AnyObject {
    var sourceName: String { get }
    var currentMeasurement: HingeMeasurementSnapshot { get }
    var onUpdate: ((HingeMeasurementSnapshot) -> Void)? { get set }
    func start()
    func stop()
}
