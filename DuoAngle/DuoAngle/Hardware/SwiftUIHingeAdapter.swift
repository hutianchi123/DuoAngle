import SwiftUI

/// Maps the public SwiftUI DeviceHinge context (iOS 27.1+) to app-owned values.
@available(iOS 27.1, *)
enum SwiftUIHingeAdapter {
    static func measurement(from context: DeviceHingeContext) -> (Double?, HingeStatus) {
        guard let hinge = context.hinge else { return (nil, .unknown) }
        let status: HingeStatus
        switch hinge.status {
        case .closed: status = .closed
        case .partiallyOpen: status = .partiallyOpen
        case .fullyOpen: status = .fullyOpen
        default: status = .unknown
        }
        return (hinge.angle.radians, status)
    }
}
