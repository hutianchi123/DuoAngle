import Foundation
import UIKit

enum DeviceCapability {
    case supported
    case unsupported
    case unknown
}

/// UIHinge reports measurements, not a public hardware-capability query.
/// Keep production detection unknown rather than infer capability from a missing sample.
enum DeviceCapabilityResolver {
    static var detected: DeviceCapability {
        capability(for: UIDevice.current.userInterfaceIdiom)
    }

    static func capability(for interfaceIdiom: UIUserInterfaceIdiom) -> DeviceCapability {
        if interfaceIdiom == .pad {
            return .unsupported
        }

        // UIHinge exposes measurements, not a public capability query.
        // Keep iPhone detection conservative when no hinge sample is available.
        return .unknown
    }

    #if DEBUG
    static var debugOverride: DeviceCapability? {
        let arguments = ProcessInfo.processInfo.arguments
        let argumentValue = arguments.firstIndex(of: "-foldmetry-device-capability")
            .flatMap { arguments.indices.contains($0 + 1) ? arguments[$0 + 1] : nil }
        let value = argumentValue ?? ProcessInfo.processInfo.environment["FOLDMETRY_DEVICE_CAPABILITY"]
        let capability: DeviceCapability?
        switch value {
        case "supported": capability = .supported
        case "unsupported": capability = .unsupported
        case "unknown": capability = .unknown
        default: capability = nil
        }
        return capability
    }
    #else
    static let debugOverride: DeviceCapability? = nil
    #endif
}
