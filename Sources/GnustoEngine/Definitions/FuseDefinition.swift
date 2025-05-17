import Foundation

/// Defines the static properties of a game fuse.
///
/// Fuses are timed events that trigger an action after a specific number of game turns.
/// This definition provides the blueprint for creating runtime `Fuse` instances.
public struct FuseDefinition: Identifiable, Equatable, Hashable, Sendable {
    /// The unique identifier for this fuse definition.
    public let id: FuseID

    /// The initial number of turns before the fuse triggers.
    public let initialTurns: Int

    /// The action to perform when the fuse triggers.
    ///
    /// This closure is executed within the context of the `GameEngine`'s actor.
    /// It receives the `GameEngine` instance, allowing it to interact with the game state and IO.
    public let action: @Sendable (_ engine: GameEngine) async -> Void // Added @MainActor

    /// Initializes a new fuse definition.
    ///
    /// - Parameters:
    ///   - id: The unique identifier for the fuse. Must match a corresponding `FuseID`.
    ///   - initialTurns: The number of turns the fuse lasts. Must be positive.
    ///   - action: The closure to execute when the fuse triggers. Must run on MainActor.
    public init(
        id: FuseID,
        initialTurns: Int,
        action: @escaping @Sendable (GameEngine) async -> Void
    ) {
        precondition(initialTurns > 0, "FuseDefinition must have a positive initial duration.")
        self.id = id
        self.initialTurns = initialTurns
        self.action = action
    }

    // MARK: - Equatable Conformance

    public static func == (lhs: FuseDefinition, rhs: FuseDefinition) -> Bool {
        lhs.id == rhs.id && lhs.initialTurns == rhs.initialTurns
    }

    // MARK: - Hashable Conformance

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(initialTurns)
        // Note: Closures are not hashable.
        // Hashing is based on id and initialTurns only.
    }
}
