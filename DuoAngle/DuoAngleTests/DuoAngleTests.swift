//
//  DuoAngleTests.swift
//  DuoAngleTests
//
//  Created by 胡天驰 on 9/19/26.
//

import Testing
@testable import DuoAngle

struct DuoAngleTests {

    @Test func angleConversion() {
        #expect(AngleMath.degrees(fromRadians: 0) == 0)
        #expect(abs(AngleMath.degrees(fromRadians: .pi / 6) - 30) < 1e-12)
        #expect(abs(AngleMath.degrees(fromRadians: .pi / 4) - 45) < 1e-12)
        #expect(abs(AngleMath.degrees(fromRadians: .pi / 2) - 90) < 1e-12)
        #expect(abs(AngleMath.degrees(fromRadians: .pi) - 180) < 1e-12)
        #expect(abs(AngleMath.radians(fromDegrees: 90) - (.pi / 2)) < 1e-12)
    }

    @Test func floatingPointTolerance() {
        let slightlyOffPiOverTwo = (.pi / 2) + 1e-13
        #expect(abs(AngleMath.degrees(fromRadians: slightlyOffPiOverTwo) - 90) < 1e-10)
    }

    @Test func normalizationAndClamping() {
        #expect(AngleMath.normalizedDegrees(360) == 0)
        #expect(AngleMath.normalizedDegrees(450) == 90)
        #expect(AngleMath.normalizedDegrees(-90) == 270)
        #expect(AngleMath.clampedDegrees(-1) == 0)
        #expect(AngleMath.clampedDegrees(181) == 180)
    }

    @Test func statusValuesAreStable() {
        #expect(HingeStatus.unknown.rawValue == "unknown")
        #expect(HingeStatus.closed.rawValue == "closed")
        #expect(HingeStatus.partiallyOpen.rawValue == "partiallyOpen")
        #expect(HingeStatus.fullyOpen.rawValue == "fullyOpen")
    }

    @Test @MainActor func mockProviderCanChangeAndStop() {
        let provider = MockHingeMeasurementProvider()
        var updateCount = 0
        provider.onUpdate = { _ in updateCount += 1 }

        provider.setAngleDegrees(135)
        #expect(provider.currentMeasurement.angleDegrees == 135)
        provider.setStatus(.fullyOpen)
        #expect(provider.currentMeasurement.status == .fullyOpen)
        provider.start()
        #expect(provider.isRunning)
        #expect(updateCount > 0)
        provider.stop()
        #expect(!provider.isRunning)

        provider.setUnavailable()
        #expect(!provider.currentMeasurement.isAvailable)
        #expect(provider.currentMeasurement.angleDegrees == nil)
    }

    @Test @MainActor func measurementManagerPreservesPrecisionAndDeduplicates() {
        let manager = HingeMeasurementManager()
        let radians = 89.827 * .pi / 180
        manager.receive(angleRadians: radians, status: .partiallyOpen)
        #expect(manager.snapshot.angleRadians == radians)
        #expect(abs((manager.snapshot.angleDegrees ?? 0) - 89.827) < 1e-10)
        #expect(manager.displayText == "90°")
        #expect(manager.updateCount == 1)
        manager.receive(angleRadians: radians, status: .partiallyOpen)
        #expect(manager.updateCount == 2)
        #expect(manager.snapshot.angleRadians == radians)
    }

    @Test @MainActor func measurementManagerClearsStaleValues() {
        let manager = HingeMeasurementManager()
        manager.receive(angleRadians: .pi / 2, status: .partiallyOpen)
        manager.receive(angleRadians: 0, status: .closed)
        #expect(manager.snapshot.angleRadians == nil)
        #expect(manager.displayText == "请展开以测量角度")
        manager.receive(angleRadians: nil, status: .unknown)
        #expect(manager.snapshot.angleRadians == nil)
        #expect(manager.displayText == "角度暂不可用")
    }

    @Test @MainActor func measurementManagerRejectsInvalidAngles() {
        let manager = HingeMeasurementManager()
        manager.receive(angleRadians: .nan, status: .partiallyOpen)
        #expect(manager.snapshot.angleRadians == nil)
        #expect(manager.displayText == "角度暂不可用")
        manager.receive(angleRadians: .infinity, status: .fullyOpen)
        #expect(manager.snapshot.angleRadians == nil)
    }

}
