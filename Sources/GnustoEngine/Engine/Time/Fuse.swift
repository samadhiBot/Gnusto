import Foundation

/// Represents a timed event scheduled to occur after a specific number of turns.
public struct Fuse: Identifiable {

    /// A unique identifier for the fuse.
    public typealias ID = String // Simple string ID for now

    /// The unique ID of this fuse instance.
    public let id: ID

    /// The number of game turns remaining until the fuse triggers.
    public internal(set) var turnsRemaining: Int

    /// The action to execute when the fuse timer reaches zero.
    /// This closure runs on the GameEngine's actor context.
    /// **Note:** This closure itself is not directly Codable. Persistence requires
    /// associating this fuse's ID with a specific game action during serialization.
    @MainActor public var action: (GameEngine) async -> Void

    /// Initializes a new fuse.
    /// - Parameters:
    ///   - id: A unique identifier for the fuse.
    ///   - turns: The number of turns before the fuse triggers.
    ///   - action: The closure to execute when the fuse triggers.
    @MainActor
    public init(id: ID, turns: Int, action: @escaping @MainActor (GameEngine) async -> Void) {
        precondition(turns > 0, "Fuse must have a positive duration.")
        self.id = id
        self.turnsRemaining = turns
        self.action = action
    }
}

// Basic Equatable and Hashable conformance based on ID
extension Fuse: Equatable {
    public static func == (lhs: Fuse, rhs: Fuse) -> Bool {
        lhs.id == rhs.id
    }
}

extension Fuse: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
