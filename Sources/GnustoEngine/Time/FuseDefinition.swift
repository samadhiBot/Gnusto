import Foundation

/// Defines the behavior of a timed event, known as a "fuse", scheduled to occur
/// after a specific number of game turns.
///
/// Fuses are classic ZIL features used to implement delayed actions or events.
/// For example, a fuse might be lit on a stick of dynamite, causing an explosion
/// after a set number of turns, or a magical spell might wear off after a duration.
///
/// You create `FuseDefinition` instances and register them with the
/// `TimeRegistry` when setting up your game (typically in `GameBlueprint`).
/// To start a timed event, you would then use a game command or side effect to activate
/// the fuse by its ID, at which point the `GameEngine` begins tracking its `initialTurns`.
/// When the turn counter for an active fuse reaches zero, its `action` is executed.
public struct FuseDefinition: Identifiable, Sendable {

    /// A unique identifier for the fuse definition.
    public typealias ID = FuseID

    /// The unique ID of this fuse definition.
    public let id: ID

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
    /// - Parameter engine: The `GameEngine` instance, providing access to game state and mutation methods.
    public var action: @Sendable (GameEngine) async -> Void

    /// Initializes a new fuse definition.
    ///
    /// - Parameters:
    ///   - id: The unique `FuseID` for this fuse definition.
    ///   - initialTurns: The number of turns from activation until the fuse triggers (must be > 0).
    ///   - repeats: Whether the fuse reactivates itself after triggering. Defaults to `false`.
    ///   - action: The closure to execute when the fuse triggers. It receives the `GameEngine` instance.
    public init(
        id: ID,
        initialTurns: Int,
        repeats: Bool = false,
        action: @escaping @Sendable (GameEngine) async -> Void
    ) {
        precondition(initialTurns > 0, "Fuse must have a positive initial turn count.")
        self.id = id
        self.initialTurns = initialTurns
        self.repeats = repeats
        self.action = action
    }
}

// Basic Equatable and Hashable conformance based on ID
extension FuseDefinition: Equatable {
    public static func == (lhs: FuseDefinition, rhs: FuseDefinition) -> Bool {
        lhs.id == rhs.id // Equality based on ID only
    }
}

extension FuseDefinition: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id) // Hashing based on ID only
    }
}
