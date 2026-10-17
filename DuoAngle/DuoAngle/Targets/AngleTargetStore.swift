import Foundation
import Observation

@MainActor
@Observable
final class AngleTargetStore {
    enum Error: Swift.Error, Equatable {
        case invalidAngle
        case duplicateAngle
        case targetNotFound
        case storageCorrupted
    }

    static let storageKey = "angleTargets.v1"

    private(set) var targets: [AngleTarget] = []
    private(set) var isStorageCorrupted = false

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        guard let stored = defaults.object(forKey: Self.storageKey) else { return }
        guard let data = stored as? Data else {
            isStorageCorrupted = true
            return
        }
        do {
            let saved = try JSONDecoder().decode([AngleTarget].self, from: data)
            guard saved.allSatisfy({ AngleTarget.validAngles.contains($0.angle) }),
                  Set(saved.map(\.id)).count == saved.count,
                  Set(saved.map(\.angle)).count == saved.count else {
                isStorageCorrupted = true
                return
            }
            targets = saved.sorted { $0.angle < $1.angle }
        } catch {
            isStorageCorrupted = true
        }
    }

    var enabledTargets: [AngleTarget] { targets.filter(\.isEnabled) }

    func contains(_ angle: Int, excluding id: UUID? = nil) -> Bool {
        targets.contains { $0.angle == angle && $0.id != id }
    }

    @discardableResult
    func add(_ angle: Int) throws -> AngleTarget {
        try validate(angle, excluding: nil)
        let target = AngleTarget(angle: angle)
        targets.append(target)
        targets.sort { $0.angle < $1.angle }
        persist()
        return target
    }

    func edit(_ id: UUID, angle: Int) throws {
        guard let index = targets.firstIndex(where: { $0.id == id }) else { throw Error.targetNotFound }
        try validate(angle, excluding: id)
        guard targets[index].angle != angle else { return }
        targets[index].angle = angle
        targets.sort { $0.angle < $1.angle }
        persist()
    }

    func setEnabled(_ enabled: Bool, for id: UUID) throws {
        try ensureWritable()
        guard let index = targets.firstIndex(where: { $0.id == id }) else { throw Error.targetNotFound }
        guard targets[index].isEnabled != enabled else { return }
        targets[index].isEnabled = enabled
        persist()
    }

    func delete(_ id: UUID) throws {
        try ensureWritable()
        guard let index = targets.firstIndex(where: { $0.id == id }) else { throw Error.targetNotFound }
        targets.remove(at: index)
        persist()
    }

    func recoverCorruptedStorage() {
        guard isStorageCorrupted else { return }
        defaults.removeObject(forKey: Self.storageKey)
        targets = []
        isStorageCorrupted = false
    }

    private func validate(_ angle: Int, excluding id: UUID?) throws {
        try ensureWritable()
        guard AngleTarget.validAngles.contains(angle) else { throw Error.invalidAngle }
        guard !contains(angle, excluding: id) else { throw Error.duplicateAngle }
    }

    private func ensureWritable() throws {
        if isStorageCorrupted { throw Error.storageCorrupted }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(targets) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }
}
