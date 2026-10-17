import Foundation
import Testing
@testable import DuoAngle

@MainActor
struct AngleTargetTests {
    private func defaults() -> UserDefaults {
        UserDefaults(suiteName: "AngleTargetTests.\(UUID().uuidString)")!
    }

    @Test func addSortAndRejectDuplicatesIncludingDisabled() throws {
        let store = AngleTargetStore(defaults: defaults())
        let high = try store.add(120)
        let low = try store.add(45)
        #expect(store.targets.map(\.angle) == [45, 120])
        #expect(high.isEnabled && low.isEnabled)
        try store.setEnabled(false, for: high.id)
        #expect(throws: AngleTargetStore.Error.duplicateAngle) { try store.add(120) }
    }

    @Test func rejectsInvalidAnglesAndKeepsBounds() throws {
        let store = AngleTargetStore(defaults: defaults())
        #expect(throws: AngleTargetStore.Error.invalidAngle) { try store.add(-1) }
        #expect(throws: AngleTargetStore.Error.invalidAngle) { try store.add(181) }
        _ = try store.add(0)
        _ = try store.add(180)
        #expect(store.targets.map(\.angle) == [0, 180])
    }

    @Test func editPreservesIdentityAndEnabledState() throws {
        let store = AngleTargetStore(defaults: defaults())
        let target = try store.add(90)
        try store.setEnabled(false, for: target.id)
        try store.edit(target.id, angle: 91)
        #expect(store.targets == [AngleTarget(id: target.id, angle: 91, isEnabled: false)])
        try store.edit(target.id, angle: 91)
        #expect(throws: AngleTargetStore.Error.duplicateAngle) {
            _ = try store.add(91)
        }
    }

    @Test func deletionAndPersistenceRoundTrip() throws {
        let suite = defaults()
        let first = AngleTargetStore(defaults: suite)
        let target = try first.add(135)
        try first.setEnabled(false, for: target.id)
        let second = AngleTargetStore(defaults: suite)
        #expect(second.targets == [AngleTarget(id: target.id, angle: 135, isEnabled: false)])
        try second.delete(target.id)
        #expect(AngleTargetStore(defaults: suite).targets.isEmpty)
    }

    @Test func corruptDataRequiresExplicitRecovery() throws {
        let suite = defaults()
        suite.set(Data("broken".utf8), forKey: AngleTargetStore.storageKey)
        let store = AngleTargetStore(defaults: suite)
        #expect(store.isStorageCorrupted)
        #expect(throws: AngleTargetStore.Error.storageCorrupted) { try store.add(90) }
        #expect(suite.data(forKey: AngleTargetStore.storageKey) == Data("broken".utf8))
        store.recoverCorruptedStorage()
        #expect(!store.isStorageCorrupted)
        _ = try store.add(90)
        #expect(AngleTargetStore(defaults: suite).targets.map(\.angle) == [90])
    }

    @Test func unexpectedStoredTypeIsNotOverwritten() {
        let suite = defaults()
        suite.set("unexpected", forKey: AngleTargetStore.storageKey)
        let store = AngleTargetStore(defaults: suite)
        #expect(store.isStorageCorrupted)
        #expect(throws: AngleTargetStore.Error.storageCorrupted) { try store.add(45) }
        #expect(suite.string(forKey: AngleTargetStore.storageKey) == "unexpected")
    }

    @Test func stationaryCurrentAngleRemainsEligible() {
        let now = Date()
        let snapshot = HingeMeasurementSnapshot(
            angleRadians: AngleMath.radians(fromDegrees: 119.6),
            status: .partiallyOpen, timestamp: now, isAvailable: true
        )
        #expect(CurrentAngleSelection.angle(from: snapshot) == 120)
        let stationary = HingeMeasurementSnapshot(
            angleRadians: snapshot.angleRadians, status: snapshot.status,
            timestamp: now.addingTimeInterval(-30), isAvailable: snapshot.isAvailable
        )
        #expect(CurrentAngleSelection.angle(from: stationary) == 120)
    }

    @Test func currentAngleRejectsInvalidStatesAndAngles() {
        let now = Date()
        let closed = HingeMeasurementSnapshot(angleRadians: nil, status: .closed, timestamp: now, isAvailable: false)
        #expect(CurrentAngleSelection.angle(from: closed) == nil)
        let unknown = HingeMeasurementSnapshot(angleRadians: .pi / 2, status: .unknown, timestamp: now, isAvailable: true)
        #expect(CurrentAngleSelection.angle(from: unknown) == nil)
        let missing = HingeMeasurementSnapshot(angleRadians: nil, status: .partiallyOpen, timestamp: now, isAvailable: false)
        #expect(CurrentAngleSelection.angle(from: missing) == nil)
        let unavailable = HingeMeasurementSnapshot(angleRadians: .pi / 2, status: .partiallyOpen, timestamp: now, isAvailable: false)
        #expect(CurrentAngleSelection.angle(from: unavailable) == nil)
        for radians in [Double.nan, .infinity, AngleMath.radians(fromDegrees: -1), AngleMath.radians(fromDegrees: 181)] {
            let invalid = HingeMeasurementSnapshot(angleRadians: radians, status: .partiallyOpen, timestamp: now, isAvailable: true)
            #expect(CurrentAngleSelection.angle(from: invalid) == nil)
        }
        let fullyOpen = HingeMeasurementSnapshot(angleRadians: .pi, status: .fullyOpen, timestamp: now, isAvailable: true)
        #expect(CurrentAngleSelection.angle(from: fullyOpen) == 180)
    }

    @Test func observationSessionMustReceiveANewMeasurementAfterInvalidation() {
        let manager = HingeMeasurementManager()
        manager.receive(angleRadians: .pi / 2, status: .partiallyOpen)
        #expect(CurrentAngleSelection.angle(from: manager.snapshot) == 90)
        manager.clear()
        #expect(CurrentAngleSelection.angle(from: manager.snapshot) == nil)
        #expect(CurrentAngleSelection.angle(from: manager.snapshot) == nil)
        manager.receive(angleRadians: .pi, status: .fullyOpen)
        #expect(CurrentAngleSelection.angle(from: manager.snapshot) == 180)
    }

    @Test func currentAngleStillUsesExistingDuplicateValidation() throws {
        let store = AngleTargetStore(defaults: defaults())
        _ = try store.add(128)
        let snapshot = HingeMeasurementSnapshot(
            angleRadians: AngleMath.radians(fromDegrees: 128),
            status: .partiallyOpen, timestamp: Date(), isAvailable: true
        )
        let selectedAngle = try #require(CurrentAngleSelection.angle(from: snapshot))
        #expect(store.contains(selectedAngle))
        #expect(throws: AngleTargetStore.Error.duplicateAngle) { try store.add(selectedAngle) }
    }
}
