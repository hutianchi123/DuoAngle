import SwiftUI
import UIKit

struct HingeDebuggerView: UIViewControllerRepresentable {
    let provider: any HingeMeasurementProviding

    func makeUIViewController(context: Context) -> HingeDebuggerViewController {
        HingeDebuggerViewController(provider: provider)
    }

    func updateUIViewController(_ viewController: HingeDebuggerViewController, context: Context) {}
}

@MainActor
final class HingeDebuggerViewController: UIViewController {
    private let angleLabel = UILabel()
    private let radiansLabel = UILabel()
    private let postureLabel = UILabel()
    private let providerLabel = UILabel()
    private let availabilityLabel = UILabel()
    private let provider: any HingeMeasurementProviding

    init(provider: any HingeMeasurementProviding) {
        self.provider = provider
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let titleLabel = UILabel()
        titleLabel.text = "Duo Angle Debugger"
        titleLabel.font = .preferredFont(forTextStyle: .headline)

        angleLabel.font = .systemFont(ofSize: 48, weight: .medium)
        angleLabel.text = "Unavailable"
        postureLabel.text = "Posture: unknown"
        [titleLabel, angleLabel, postureLabel, providerLabel].forEach { $0.textColor = .white }
        availabilityLabel.text = "No hinge data in this hierarchy"
        availabilityLabel.textColor = .lightGray
        availabilityLabel.numberOfLines = 0

        providerLabel.text = "Provider: \(provider.sourceName)"
        let stack = UIStackView(arrangedSubviews: [titleLabel, angleLabel, radiansLabel, postureLabel, providerLabel, availabilityLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])

        provider.onUpdate = { [weak self] snapshot in
            self?.apply(snapshot)
        }
        apply(provider.currentMeasurement)
        provider.start()
    }

    private func apply(_ snapshot: HingeMeasurementSnapshot) {
        if let angleDegrees = snapshot.angleDegrees {
            angleLabel.text = String(format: "%.2f°", angleDegrees)
        } else {
            angleLabel.text = "Unavailable"
        }
        radiansLabel.text = snapshot.angleRadians.map { String(format: "Radians: %.6f", $0) } ?? "Radians: —"
        postureLabel.text = "Posture: \(snapshot.status.rawValue)"
        availabilityLabel.text = snapshot.isAvailable ? "Live UIKit hinge data" : "No hinge data in this hierarchy"
    }

}
