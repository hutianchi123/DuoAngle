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

    @Test func currentAngleUsesFreshValidMeasurement() {
        let now = Date()
        let snapshot = HingeMeasurementSnapshot(
            angleRadians: AngleMath.radians(fromDegrees: 119.6),
            status: .partiallyOpen, timestamp: now, isAvailable: true
        )
        #expect(CurrentAngleSelection.angle(from: snapshot, lastUpdate: now, now: now) == 120)
        #expect(CurrentAngleSelection.angle(from: snapshot, lastUpdate: now.addingTimeInterval(-5), now: now) == 120)
        #expect(CurrentAngleSelection.angle(from: snapshot, lastUpdate: now.addingTimeInterval(-20), now: now) == nil)
        let closed = HingeMeasurementSnapshot(angleRadians: nil, status: .closed, timestamp: now, isAvailable: false)
        #expect(CurrentAngleSelection.angle(from: closed, lastUpdate: now, now: now) == nil)
    }
}
