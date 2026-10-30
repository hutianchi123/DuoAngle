import UIKit
import XCTest
@testable import DuoAngle

final class DeviceCapabilityTests: XCTestCase {
    func testIPadIsExplicitlyUnsupported() {
        XCTAssertEqualCapability(.unsupported, DeviceCapabilityResolver.capability(
            for: .pad,
            machineIdentifier: "iPad13,4",
            isSimulator: false
        ))
    }

    func testVerifiedIPhone14ProIsUnsupported() {
        XCTAssertEqualCapability(.unsupported, DeviceCapabilityResolver.capability(
            for: .phone,
            machineIdentifier: "iPhone15,2",
            isSimulator: false
        ))
    }

    func testUnregisteredPhysicalIPhoneIsUnsupported() {
        XCTAssertEqualCapability(.unsupported, DeviceCapabilityResolver.capability(
            for: .phone,
            machineIdentifier: "iPhone99,1",
            isSimulator: false
        ))
    }

    func testMissingPhysicalMachineIdentifierRemainsUnknown() {
        XCTAssertEqualCapability(.unknown, DeviceCapabilityResolver.capability(
            for: .phone,
            machineIdentifier: nil,
            isSimulator: false
        ))
    }

    func testVerifiedIPhoneDuoSimulatorUsesSimulationPath() {
        XCTAssertEqualCapability(.supported, DeviceCapabilityResolver.capability(
            for: .phone,
            machineIdentifier: "iPhone19,4",
            isSimulator: true
        ))
    }

    func testOtherPhoneSimulatorIsUnsupported() {
        XCTAssertEqualCapability(.unsupported, DeviceCapabilityResolver.capability(
            for: .phone,
            machineIdentifier: "iPhone19,2",
            isSimulator: true
        ))
    }

    private func XCTAssertEqualCapability(
        _ expected: DeviceCapability,
        _ actual: DeviceCapability,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        switch (expected, actual) {
        case (.supported, .supported), (.unsupported, .unsupported), (.unknown, .unknown): break
        default: XCTFail("Unexpected device capability", file: file, line: line)
        }
    }
}
