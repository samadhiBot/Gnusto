import Foundation

/// Defines the behavior of a background task or routine, known as a "daemon", that runs
/// periodically at a specified frequency during the game.
///
/// Daemons are classic ZIL features used to implement recurring game world events,
/// NPC behaviors, or other processes that occur automatically without direct player
/// command. For example, a daemon might make an NPC wander, cause a light source
/// to gradually dim, or check if a certain game condition triggers a special event.
///
/// You create `Daemon` instances and register them with the `GameBlueprint` when setting up
/// your game. The `GameEngine` then manages active daemons, calling their `action` closures
/// at the appropriate turns based on their `frequency`.
public struct Daemon: Sendable {
    /// How often the daemon should run, in game turns. For example:
    /// - `1`: The daemon's action runs every turn.
    /// - `5`: The daemon's action runs every 5 turns.
    /// The first execution will occur on a turn number that is a multiple of `frequency`
    /// (and greater than 0).
    public let frequency: Int

    /// The action to execute when the daemon runs.
    ///
    /// This closure is executed on the `GameEngine`'s actor context, allowing you to
    /// safely query and modify the `GameState` through the provided `GameEngine` instance.
    /// The closure can return an `ActionResult` with a message to display to the player
    /// and any side effects to process, or `nil` if no result is needed.
    ///
    /// - Parameter engine: The `GameEngine` instance, providing access to game state
    ///                     and mutation methods.
    /// - Returns: An optional `ActionResult` containing a message and/or side effects,
    ///            or `nil` for silent execution.
    public var action: @Sendable (GameEngine) async throws -> ActionResult?

    /// Initializes a new daemon definition.
    ///
    /// - Parameters:
    ///   - frequency: The number of turns between executions (must be >= 1).
    ///                Defaults to 1 (every turn).
    ///   - action: The closure to execute when the daemon runs. It receives the `GameEngine`
    ///             instance and can return an `ActionResult` with a message and side effects.
    public init(
        frequency: Int = 1,
        action: @escaping @Sendable (GameEngine) async throws -> ActionResult?
    ) {
        precondition(frequency >= 1, "Daemon frequency must be 1 or greater.")
        self.frequency = frequency
        self.action = action
    }
}
