import Foundation

enum HingeStatus: String, Equatable {
    case unknown
    case closed
    case partiallyOpen
    case fullyOpen
}

struct HingeMeasurementSnapshot: Equatable {
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
