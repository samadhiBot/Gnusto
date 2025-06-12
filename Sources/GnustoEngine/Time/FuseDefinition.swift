import Foundation

/// Defines the behavior of a timed event, known as a "fuse", scheduled to occur
/// after a specific number of game turns.
///
/// Fuses are classic ZIL features used to implement delayed actions or events.
/// For example, a fuse might be lit on a stick of dynamite, causing an explosion
/// after a set number of turns, or a magical spell might wear off after a duration.
///
/// You create `FuseDefinition` instances and register them with the
/// `GameBlueprint` when setting up your game.
/// To start a timed event, you would then use a game command or side effect to activate
/// the fuse by its ID, at which point the `GameEngine` begins tracking its `initialTurns`.
/// When the turn counter for an active fuse reaches zero, its `action` is executed.
public struct FuseDefinition: Sendable {
    /// The initial number of game turns from when the fuse is activated until it triggers.
    /// This must be a positive integer.
    public let initialTurns: Int

    /// Indicates whether this fuse should automatically restart with its `initialTurns`
    /// after its action has been executed. If `false` (the default), the fuse triggers once
    /// and is then removed. If `true`, it will reactivate itself.
    public let repeats: Bool

    /// The action to execute when the fuse's timer reaches zero.
    ///
    /// This closure is executed on the `GameEngine`'s actor context, allowing you to
    /// safely query and modify the `GameState` through the provided `GameEngine` instance.
    /// The closure can return an `ActionResult` with a message to display to the player
    /// and any side effects to process, or `nil` if no player-visible output is needed.
    ///
    /// - Parameter engine: The `GameEngine` instance, providing access to game state and
    ///                     mutation methods.
    /// - Returns: An optional `ActionResult` containing a message and/or side effects, or `nil`
    ///            for silent execution.
    public var action: @Sendable (GameEngine) async -> ActionResult?

    /// Initializes a new fuse definition.
    ///
    /// - Parameters:
    ///   - initialTurns: The number of turns from activation until the fuse triggers (must be > 0).
    ///   - repeats: Whether the fuse reactivates itself after triggering. Defaults to `false`.
    ///   - action: The closure to execute when the fuse triggers. It receives the `GameEngine`
    ///             instance and can return an `ActionResult` with a message and side effects.
    public init(
        initialTurns: Int,
        repeats: Bool = false,
        action: @escaping @Sendable (GameEngine) async -> ActionResult?
    ) {
        precondition(initialTurns > 0, "Fuse must have a positive initial turn count.")
        self.initialTurns = initialTurns
        self.repeats = repeats
        self.action = action
    }
}
