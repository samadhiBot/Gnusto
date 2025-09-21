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
    /// The daemon receives its current state and can return both an `ActionResult` for
    /// immediate effects and an updated `DaemonState` to persist between executions.
    ///
    /// - Parameter engine: The `GameEngine` instance, providing access to game state
    ///                     and mutation methods.
    /// - Parameter state: The current `DaemonState` for this daemon instance, containing
    ///                    any persistent data and execution tracking.
    /// - Returns: A tuple containing an optional `ActionResult` with message and/or side
    ///            effects, and an optional updated `DaemonState` to persist. Return `nil`
    ///            for the state to keep it unchanged.
    public var action: @Sendable (GameEngine, DaemonState) async throws -> (ActionResult?, DaemonState?)

    /// Initializes a new daemon definition.
    ///
    /// - Parameters:
    ///   - frequency: The number of turns between executions (must be >= 1).
    ///                Defaults to 1 (every turn).
    ///   - action: The closure to execute when the daemon runs. It receives the `GameEngine`
    ///             instance and current `DaemonState`, and returns a tuple containing an
    ///             optional `ActionResult` and optional updated `DaemonState`.
    public init(
        frequency: Int = 1,
        action:
            @escaping @Sendable (GameEngine, DaemonState) async throws -> (
                ActionResult?, DaemonState?
            )
    ) {
        precondition(frequency >= 1, "Daemon frequency must be 1 or greater.")
        self.frequency = frequency
        self.action = action
    }
}
