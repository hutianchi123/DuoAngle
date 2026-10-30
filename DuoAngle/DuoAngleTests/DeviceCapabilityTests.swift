import UIKit
import XCTest
@testable import DuoAngle

final class DeviceCapabilityTests: XCTestCase {
    func testIPadIsExplicitlyUnsupported() {
        assertCapability(.unsupported, for: .pad)
    }

    func testIPhoneWithoutCapabilitySignalRemainsUnknown() {
        assertCapability(.unknown, for: .phone)
    }

    private func assertCapability(
        _ expected: DeviceCapability,
        for idiom: UIUserInterfaceIdiom,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        switch (expected, DeviceCapabilityResolver.capability(for: idiom)) {
        case (.supported, .supported), (.unsupported, .unsupported), (.unknown, .unknown):
            break
        default:
            XCTFail("Unexpected capability for interface idiom \(idiom)", file: file, line: line)
        }
    }
}
