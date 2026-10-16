import Foundation
import UIKit

/// Adapter for the public UIKit UIHinge/UIHingeInteraction API available from iOS 27.1.
@MainActor
final class UIHingeMeasurementProvider: NSObject, HingeMeasurementProviding {
    let sourceName = "UIHinge"
    var onUpdate: ((HingeMeasurementSnapshot) -> Void)?
    private(set) var currentMeasurement = HingeMeasurementSnapshot(
        angleRadians: nil,
        status: .unknown,
        timestamp: Date(),
        isAvailable: false
    )
    private var interaction: (any UIInteraction)?
    private weak var hostView: UIView?

    init(hostView: UIView) {
        self.hostView = hostView
        super.init()
    }

    func start() {
        guard #available(iOS 27.1, *) else {
            publishUnavailable()
            return
        }

        guard let hostView else {
            publishUnavailable()
            return
        }

        let interaction = UIHingeInteraction { [weak self] _, update in
            guard let self else { return }
            guard let hinge = update.hinge else {
                self.publishUnavailable()
                return
            }

            let status: HingeStatus
            switch hinge.status {
            case .closed: status = .closed
            case .partiallyOpen: status = .partiallyOpen
            case .fullyOpen: status = .fullyOpen
            default: status = .unknown
            }

            self.publish(.init(
                angleRadians: Double(hinge.angle),
                status: status,
                timestamp: Date(),
                isAvailable: true
            ))
        }

        self.interaction = interaction
        hostView.addInteraction(interaction)
    }

    func stop() {
        if let interaction {
            hostView?.removeInteraction(interaction)
        }
        interaction = nil
    }

    private func publishUnavailable() {
        publish(.init(angleRadians: nil, status: .unknown, timestamp: Date(), isAvailable: false))
    }

    private func publish(_ measurement: HingeMeasurementSnapshot) {
        currentMeasurement = measurement
        onUpdate?(measurement)
    }
}
