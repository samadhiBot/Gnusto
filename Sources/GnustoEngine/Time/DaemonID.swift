import Foundation

/// A type-safe identifier for a daemon (background process) in the game's time system.
///
/// A daemon is a piece of game logic that runs automatically each turn, typically used
/// for ongoing background processes like NPC behavior, environmental changes, or
/// recurring events.
///
/// It is `Codable` for game state persistence and `ExpressibleByStringLiteral` for
/// convenient initialization (e.g., `let thiefDaemonID: DaemonID = "thief"`).
public struct DaemonID: GnustoID {
    /// The underlying string value of the daemon identifier.
    public let rawValue: String

    /// Initializes a `DaemonID` with a raw string value.
    /// - Parameter rawValue: The string value for the ID.
    public init(rawValue: String) {
        assert(!rawValue.isEmpty, "Daemon ID cannot be empty")
        self.rawValue = rawValue
    }
}
