import Foundation

/// A type-safe identifier for a fuse (timed event) in the game's time system.
///
/// A fuse is a one-time event that triggers after a specific number of turns,
/// typically used for time-limited situations like bombs, timers, or delayed reactions.
///
/// It is `Codable` for game state persistence and `ExpressibleByStringLiteral` for
/// convenient initialization (e.g., `let bombFuseID: FuseID = "bombFuse"`).
public struct FuseID: GnustoID {
    /// The underlying string value of the fuse identifier.
    public let rawValue: String

    /// Initializes a `FuseID` with a raw string value.
    /// - Parameter rawValue: The string value for the ID.
    public init(rawValue: String) {
        assert(!rawValue.isEmpty, "Fuse ID cannot be empty")
        self.rawValue = rawValue
    }
}
