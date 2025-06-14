import Foundation

/// Represents the outcome of an `ActionHandler`'s `process` method.
///
/// An `ActionResult` encapsulates all the consequences of a successfully processed action,
/// including any message to be displayed to the player, any changes to the game state,
/// and any side effects that need to be triggered by the `GameEngine`.
///
/// At least one of `message`, `changes`, or `effects` must be non-empty for an
/// `ActionResult` to be valid, enforced by an assertion in the initializers.
public struct ActionResult: Sendable {
    /// An optional message to be displayed to the player as a direct result of the action.
    ///
    /// If a message is provided, the `GameEngine` typically prints this message and may
    /// consider the action fully handled, potentially skipping default messages associated
    /// with the verb.
    public let message: String?

    /// An array of `StateChange` objects representing modifications to the game world
    /// (e.g., item moved, flag set, score updated).
    ///
    /// The `GameEngine` will attempt to apply these changes to the `GameState` after the
    /// `process` method of the `ActionHandler` returns.
    public let changes: [StateChange]

    /// An array of `SideEffect` objects that should be triggered by the `GameEngine`
    /// after the action is processed (e.g., starting a fuse, activating a daemon).
    public let effects: [SideEffect]

    /// Creates a new `ActionResult` with arrays of state changes and side effects.
    ///
    /// - Parameters:
    ///   - message: An optional message to display to the player.
    ///   - changes: An array of `StateChange`s to be applied.
    ///   - effects: An array of `SideEffect`s to be triggered.
    public init(
        message: String? = nil,
        changes: [StateChange?] = [],
        effects: [SideEffect?] = []
    ) {
        assert(
            message != nil || !changes.isEmpty || !effects.isEmpty,
            "ActionResults must contain at least one message, StateChange, or SideEffect"
        )
        self.message = message
        self.changes = changes.compactMap(\.self)
        self.effects = effects.compactMap(\.self)
    }

    /// Creates a new `ActionResult` with optional single state change and side effect.
    ///
    /// This is a convenience initializer for common cases where an action results in at most
    /// one state change and/or one side effect.
    ///
    /// - Parameters:
    ///   - message: An optional message to display to the player.
    ///   - change: An optional single `StateChange` to be applied.
    ///   - effect: An optional single `SideEffect` to be triggered.
    public init(
        _ message: String? = nil,
        _ change: StateChange? = nil,
        _ effect: SideEffect? = nil
    ) {
        assert(
            message != nil || change != nil || effect != nil,
            "ActionResults must contain at least one message, StateChange, or SideEffect"
        )
        self.message = message
        self.changes = if let change { [change] } else { [] }
        self.effects = if let effect { [effect] } else { [] }
    }

    /// Creates a new `ActionResult` that only contains a message for the player,
    /// with no state changes or side effects.
    ///
    /// - Parameter message: The message to display to the player.
    public init(_ message: String) {
        self.message = message
        self.changes = []
        self.effects = []
    }
}
