import Foundation

/// Represents a background task or routine that runs periodically during the game.
public struct Daemon: Identifiable {

    /// A unique identifier for the daemon.
    public typealias ID = String // Simple string ID for now

    /// The unique ID of this daemon instance.
    public let id: ID

    /// How often the daemon should run (e.g., 1 = every turn, 5 = every 5 turns).
    public let frequency: Int

    /// The action to execute when the daemon runs.
    /// This closure runs on the GameEngine's actor context.
    public var action: (GameEngine) async -> Void

    /// Initializes a new daemon.
    /// - Parameters:
    ///   - id: A unique identifier for the daemon.
    ///   - frequency: The number of turns between executions (must be >= 1). Defaults to 1.
    ///   - action: The closure to execute periodically.
    // Mark init as MainActor to match action property isolation
    public init(id: ID, frequency: Int = 1, action: @escaping (GameEngine) async -> Void) {
        precondition(frequency >= 1, "Daemon frequency must be 1 or greater.")
        self.id = id
        self.frequency = frequency
        self.action = action
    }
}

// Basic Equatable and Hashable conformance based on ID
extension Daemon: Equatable {
    public static func == (lhs: Daemon, rhs: Daemon) -> Bool {
        lhs.id == rhs.id
    }
}

extension Daemon: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
