import Foundation

nonisolated struct AngleTarget: Identifiable, Codable, Hashable, Sendable {
    static let validAngles = 0...180
    static let defaultAngle = 90

    let id: UUID
    var angle: Int
    var isEnabled: Bool

    init(id: UUID = UUID(), angle: Int, isEnabled: Bool = true) {
        self.id = id
        self.angle = angle
        self.isEnabled = isEnabled
    }
}
