import Foundation

/// Represents the outcome of an `ActionHandler`'s `process` method.
///
/// An `ActionResult` encapsulates all the consequences of a successfully processed action,
/// including any message to be displayed to the player, any changes to the game state,
/// and any side effects that need to be triggered by the `GameEngine`.
///
/// At least one of `message`, `changes`, or `effects` must be non-empty for an
/// `ActionResult` to be valid, enforced by an assertion in the initializers.
public struct ActionResult: Equatable, Sendable {
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

    /// Indicates whether this result should yield control back to the engine for
    /// normal processing.
    ///
    /// When true, the engine will apply any changes/effects but then continue with
    /// standard command processing.
    public let shouldYieldToEngine: Bool

    /// Creates a new `ActionResult` with arrays of state changes and side effects.
    ///
    /// - Parameters:
    ///   - message: An optional message to display to the player.
    ///   - changes: An array of `StateChange`s to be applied.
    ///   - effects: An array of `SideEffect`s to be triggered.
    ///   - shouldYieldToEngine: Whether to yield control back to normal engine processing.
    public init(
        message: String? = nil,
        changes: [StateChange?] = [],
        effects: [SideEffect?] = [],
        shouldYieldToEngine: Bool = false
    ) {
        self.message = message?.isEmpty == false ? message : nil
        self.changes = changes.compactMap(\.self)
        self.effects = effects.compactMap(\.self)
        let hasSomeResult = self.message?.isEmpty == false
                         || self.changes.isNotEmpty
                         || self.effects.isNotEmpty
        self.shouldYieldToEngine = shouldYieldToEngine || !hasSomeResult
    }

    /// Creates a new `ActionResult` with a message and optional state changes.
    ///
    /// - Parameters:
    ///   - message: The message to display to the player.
    ///   - changes: Optional `StateChange`s to be applied.
    public init(
        _ message: String,
        _ changes: StateChange?...
    ) {
        self.init(message: message, changes: changes, shouldYieldToEngine: false)
    }

    /// Creates a new `ActionResult` with only state changes (no message).
    ///
    /// - Parameter changes: Optional `StateChange`s to be applied.
    public init(_ changes: StateChange?...) {
        self.init(changes: changes, shouldYieldToEngine: false)
    }

    /// Creates a new `ActionResult` with only side effects (no message).
    ///
    /// - Parameter effects: Optional `SideEffect`s to be triggered.
    public init(_ effects: SideEffect?...) {
        self.init(effects: effects, shouldYieldToEngine: false)
    }

    /// A special `ActionResult` that indicates the event handler has processed the event
    /// but wants to yield control back to the engine for normal command processing.
    ///
    /// This is useful for event handlers that want to conditionally allow or block actions
    /// while still being part of the event handling chain.
    public static let yield = ActionResult(shouldYieldToEngine: true)

    /// Returns a new `ActionResult` that combines this result with another result.
    ///
    /// This method appends the content of `other` to this `ActionResult` by:
    /// - Joining messages with a paragraph separator
    /// - Concatenating state changes
    /// - Concatenating side effects
    ///
    /// - Parameter other: An optional `ActionResult` to append to this one.
    /// - Returns: A new `ActionResult` containing the merged content of both results.
    public func appending(_ other: ActionResult?) -> ActionResult {
        [self, other].merged()
    }

    /// Returns a new `ActionResult` that combines another result with this result.
    ///
    /// This method prepends the content of `other` to this `ActionResult` by:
    /// - Joining messages with a paragraph separator (other's message first)
    /// - Concatenating state changes (other's changes first)
    /// - Concatenating side effects (other's effects first)
    ///
    /// - Parameter other: An optional `ActionResult` to prepend to this one.
    /// - Returns: A new `ActionResult` containing the merged content of both results.
    public func prepended(by other: ActionResult?) -> ActionResult {
        [other, self].merged()
    }
}

extension Array where Element == ActionResult? {
    /// Merges an array of optional `ActionResult`s into a single `ActionResult`.
    ///
    /// This method combines multiple `ActionResult`s by:
    /// - Joining all non-nil messages with paragraph separators
    /// - Concatenating all state changes from all results
    /// - Concatenating all side effects from all results
    ///
    /// - Returns: A single `ActionResult` containing the merged content of all non-nil results.
    func merged() -> ActionResult {
        let combinedMessage = compactMap(\.?.message).joined(separator: .paragraph)
        return ActionResult(
            message: combinedMessage.isEmpty ? nil : combinedMessage,
            changes: compactMap(\.?.changes).flatMap(\.self),
            effects: compactMap(\.?.effects).flatMap(\.self)
        )
    }
}
