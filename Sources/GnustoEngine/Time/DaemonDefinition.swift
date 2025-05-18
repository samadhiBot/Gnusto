import Foundation

/// Defines the behavior of a background task or routine, known as a "daemon",
/// that runs periodically at a specified frequency during the game.
///
/// Daemons are classic ZIL features used to implement recurring game world events,
/// NPC behaviors, or other processes that occur automatically without direct player
/// command. For example, a daemon might make an NPC wander, cause a light source
/// to gradually dim, or check if a certain game condition triggers a special event.
///
/// You create `DaemonDefinition` instances and register them with the
/// `DefinitionRegistry` when setting up your game (typically in `GameBlueprint`).
/// The `GameEngine` then manages active daemons, calling their `action` closures at
/// the appropriate turns based on their `frequency`.
public struct DaemonDefinition: Identifiable, Sendable {

    /// A unique identifier for the daemon definition.
    public typealias ID = DaemonID

    /// The unique ID of this daemon definition.
    public let id: ID

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
    /// - Parameter engine: The `GameEngine` instance, providing access to game state and mutation methods.
    public var action: @Sendable (GameEngine) async -> Void

    /// Initializes a new daemon definition.
    ///
    /// - Parameters:
    ///   - id: The unique `DaemonID` for this daemon definition.
    ///   - frequency: The number of turns between executions (must be >= 1). Defaults to 1 (every turn).
    ///   - action: The closure to execute when the daemon runs. It receives the `GameEngine` instance.
    public init(id: ID, frequency: Int = 1, action: @escaping @Sendable (GameEngine) async -> Void) {
        precondition(frequency >= 1, "Daemon frequency must be 1 or greater.")
        self.id = id
        self.frequency = frequency
        self.action = action
    }
}

// Basic Equatable and Hashable conformance based on ID
extension DaemonDefinition: Equatable {
    public static func == (lhs: DaemonDefinition, rhs: DaemonDefinition) -> Bool {
        lhs.id == rhs.id
    }
}

extension DaemonDefinition: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
