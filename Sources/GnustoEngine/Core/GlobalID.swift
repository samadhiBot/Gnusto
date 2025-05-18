import Foundation

/// A type-safe key for accessing game-specific global variables or flags stored in
/// `GameState.globalState`.
///
/// `GlobalID`s provide a structured way to manage global state that isn't directly tied to
/// specific items or locations. This can include:
/// - Boolean flags indicating story progression (e.g., `GlobalID("metTheKing")`).
/// - Numeric counters for game-wide events (e.g., `GlobalID("dragonsSlain")`).
/// - Configuration settings or miscellaneous state values.
///
/// Using `GlobalID` instead of raw strings helps prevent typos and improves code clarity.
/// It is `Codable` for game state persistence and `ExpressibleByStringLiteral` for ease of use.
public struct GlobalID: RawRepresentable, Hashable, Codable, Sendable {
    public let rawValue: String

    /// Creates a new game state key with the specified string value.
    /// - Parameter rawValue: The string representation of the key.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Creates a new game state key from a decoder.
    /// Required for `Codable` conformance.
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(String.self)
    }

    /// Encodes this game state key into the given encoder.
    /// Required for `Codable` conformance.
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}

// MARK: - ExpressibleByStringLiteral

extension GlobalID: ExpressibleByStringLiteral {
    /// Allows creating a `GameStateKey` directly from a string literal.
    /// - Parameter value: The string literal value.
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}
