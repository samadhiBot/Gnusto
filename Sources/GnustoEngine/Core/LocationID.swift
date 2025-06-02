import Foundation

/// A type-safe, unique identifier for a `Location` in the game world.
///
/// `LocationID` serves as the primary key for locations, used to store and retrieve
/// location data in `GameState.locations`, to define `Exit` destinations, and to refer
/// to locations in the `Vocabulary` and game logic. Each location in a game must have
/// a unique `LocationID`.
///
/// It is `Codable` for game state persistence and `ExpressibleByStringLiteral` for
/// convenient initialization (e.g., `let clearingID: LocationID = "forestClearing"`).
public struct LocationID: GnustoID {
    /// The underlying string value of the location identifier (e.g., "forestClearing").
    public let rawValue: String

    /// Initializes a `LocationID` with a raw string value.
    /// - Parameter rawValue: The string value for the ID.
    public init(rawValue: String) {
        assert(!rawValue.isEmpty, "Location ID cannot be empty")
        self.rawValue = rawValue
    }
}
