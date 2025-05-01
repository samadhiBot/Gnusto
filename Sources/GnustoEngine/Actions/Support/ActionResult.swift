import Foundation

/// Result of an action execution with enhanced information.
public struct ActionResult: Sendable {
    /// Whether the action was successful.
    public let success: Bool

    /// Message to display to the player.
    public let message: String

    /// Any state changes that occurred.
    public let stateChanges: [StateChange]

    /// Any side effects that need to be processed.
    public let sideEffects: [SideEffect]

    /// Creates a new action result.
    /// - Parameters:
    ///   - success: Whether the action was successful.
    ///   - message: Message to display to the player.
    ///   - stateChanges: Any state changes that occurred.
    ///   - sideEffects: Any side effects to be processed.
    public init(
        success: Bool,
        message: String,
        stateChanges: [StateChange] = [],
        sideEffects: [SideEffect] = []
    ) {
        self.success = success
        self.message = message
        self.stateChanges = stateChanges
        self.sideEffects = sideEffects
    }
}


