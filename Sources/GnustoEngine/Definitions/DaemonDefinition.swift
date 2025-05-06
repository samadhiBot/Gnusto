/// Defines a Daemon, a process that runs periodically.
public struct DaemonDefinition {
    /// The unique identifier for this daemon.
    public let id: DaemonID

    /// How often the daemon should run, in game turns.
    /// A frequency of 1 runs every turn, 2 every other turn, etc.
    public let frequency: Int

    /// The action to perform when the daemon runs.
    /// The closure receives the `GameEngine` instance.
    public let action: @MainActor @Sendable (GameEngine) async -> Void

    /// Initializes a new Daemon definition.
    /// - Parameters:
    ///   - id: The unique ID for the daemon.
    ///   - frequency: The number of turns between executions (must be >= 1).
    ///   - action: The closure to execute when the daemon runs.
    public init(
        id: DaemonID,
        frequency: Int,
        action: @escaping @MainActor @Sendable (GameEngine) async -> Void
    ) {
        precondition(frequency >= 1, "Daemon frequency must be 1 or greater.")
        self.id = id
        self.frequency = frequency
        self.action = action
    }
}

// Conformance for potential use in Sets/Dictionaries if needed, though ID is primary key
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
