/// A unique identifier for a location within the game world.
public struct LocationID: Hashable, Codable, ExpressibleByStringLiteral, Sendable {
    public let rawValue: String

    /// Initializes a `LocationID` using a string literal.
    /// - Parameter value: The string literal representing the location ID.
    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    /// Initializes a `LocationID` with a raw string value.
    /// - Parameter rawValue: The string value for the ID.
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

/// A unique identifier for an item (GameObject) within the game world.
public struct ItemID: Hashable, Codable, ExpressibleByStringLiteral, Sendable {
    public let rawValue: String

    /// Initializes an `ItemID` using a string literal.
    /// - Parameter value: The string literal representing the item ID.
    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    /// Initializes an `ItemID` with a raw string value.
    /// - Parameter rawValue: The string value for the ID.
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

/// A unique identifier for a verb within the game's vocabulary.
public struct VerbID: Hashable, Codable, ExpressibleByStringLiteral, Sendable {
    public let rawValue: String

    /// Initializes a `VerbID` using a string literal.
    /// - Parameter value: The string literal representing the verb ID.
    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    /// Initializes a `VerbID` with a raw string value.
    /// - Parameter rawValue: The string value for the ID.
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}
