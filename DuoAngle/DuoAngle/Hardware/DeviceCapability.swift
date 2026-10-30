import Darwin
import Foundation
import UIKit

enum DeviceCapability {
    case supported
    case unsupported
    case unknown
}

enum DeviceCapabilityResolver {
    static var detected: DeviceCapability {
        capability(
            for: UIDevice.current.userInterfaceIdiom,
            machineIdentifier: machineIdentifier,
            isSimulator: isSimulator
        )
    }

    static func capability(
        for interfaceIdiom: UIUserInterfaceIdiom,
        machineIdentifier: String?,
        isSimulator: Bool
    ) -> DeviceCapability {
        if interfaceIdiom == .pad {
            return .unsupported
        }
        guard interfaceIdiom == .phone else { return .unknown }

        if isSimulator {
            guard let machineIdentifier else { return .unknown }
            return machineIdentifier == "iPhone19,4" ? .supported : .unsupported
        }

        guard let machineIdentifier else { return .unknown }
        return verifiedSupportedPhysicalIPhoneIdentifiers.contains(machineIdentifier)
            ? .supported
            : .unsupported
    }

    // Populate only from a real iPhone Duo's hw.machine output; never copy a
    // simulator model identifier into this physical-device registry.
    private static let verifiedSupportedPhysicalIPhoneIdentifiers: Set<String> = []

    private static var machineIdentifier: String? {
        #if targetEnvironment(simulator)
        return ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"]
        #else
        var size = 0
        guard sysctlbyname("hw.machine", nil, &size, nil, 0) == 0, size > 1 else { return nil }
        var bytes = [CChar](repeating: 0, count: size)
        guard sysctlbyname("hw.machine", &bytes, &size, nil, 0) == 0 else { return nil }
        return String(cString: bytes)
        #endif
    }

    private static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        true
        #else
        false
        #endif
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
