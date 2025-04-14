import Foundation

/// Result of processing an object's response to a command
public struct ResponseResult: Sendable {
    /// Effects to render immediately (text, etc)
    public let effects: [Effect]

    /// Optional closure to update world state
    public let updateState: @Sendable (World) -> Void

    public init(
        effects: [Effect],
        updateState: @escaping @Sendable (World) -> Void = { _ in }
    ) {
        self.effects = effects
        self.updateState = updateState
    }
}
