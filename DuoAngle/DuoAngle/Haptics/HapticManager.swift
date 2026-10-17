import UIKit

@MainActor
protocol TargetHapticProviding: AnyObject {
    func notifyTargetReached()
}

@MainActor
final class HapticManager: TargetHapticProviding {
    private let generator = UINotificationFeedbackGenerator()

    func notifyTargetReached() {
        generator.notificationOccurred(.success)
        generator.prepare()
    }
}
