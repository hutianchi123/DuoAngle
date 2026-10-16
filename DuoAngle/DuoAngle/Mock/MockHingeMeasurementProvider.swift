import Foundation

/// Development-only data source. It never claims to represent Duo hardware.
@MainActor
final class MockHingeMeasurementProvider: HingeMeasurementProviding {
    let sourceName = "Mock"
    var onUpdate: ((HingeMeasurementSnapshot) -> Void)?
    private(set) var currentMeasurement: HingeMeasurementSnapshot
    private(set) var isRunning = false
    private var timer: Timer?
    private var direction = 1.0

    init(angleDegrees: Double = 90, status: HingeStatus = .partiallyOpen) {
        currentMeasurement = Self.snapshot(angleDegrees: angleDegrees, status: status)
    }

    func start() {
        stop()
        isRunning = true
        publish(currentMeasurement)
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let nextAngle = (self.currentMeasurement.angleDegrees ?? 90) + self.direction * 5
                if nextAngle >= 180 || nextAngle <= 0 {
                    self.direction *= -1
                }
                self.setAngleDegrees(min(max(nextAngle, 0), 180))
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    func setAngleDegrees(_ angleDegrees: Double) {
        let normalized = AngleMath.clampedDegrees(angleDegrees)
        publish(Self.snapshot(angleDegrees: normalized, status: currentMeasurement.status))
    }

    func setStatus(_ status: HingeStatus) {
        publish(Self.snapshot(angleDegrees: currentMeasurement.angleDegrees, status: status))
    }

    func setUnavailable() {
        publish(.init(angleRadians: nil, status: .unknown, timestamp: Date(), isAvailable: false))
    }

    private func publish(_ measurement: HingeMeasurementSnapshot) {
        currentMeasurement = measurement
        onUpdate?(measurement)
    }

    private static func snapshot(angleDegrees: Double?, status: HingeStatus) -> HingeMeasurementSnapshot {
        .init(
            angleRadians: angleDegrees.map(AngleMath.radians(fromDegrees:)),
            status: status,
            timestamp: Date(),
            isAvailable: angleDegrees != nil
        )
    }
}
