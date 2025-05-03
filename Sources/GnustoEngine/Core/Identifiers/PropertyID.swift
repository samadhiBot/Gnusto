import Foundation

/// A unique identifier for a standard or dynamic property within the game.
public struct PropertyID: Hashable, Comparable, Codable, ExpressibleByStringLiteral, Sendable {
    public let rawValue: String

    /// Initializes a `PropertyID` using a string literal.
    /// - Parameter value: The string literal representing the property ID.
    public init(stringLiteral value: String) {
        // Consider adding validation or normalization if needed (e.g., lowercase)
        self.rawValue = value
    }

    /// Initializes a `PropertyID` with a raw string value.
    /// - Parameter rawValue: The string value for the ID.
    public init(_ rawValue: String) {
        // Consider adding validation or normalization if needed (e.g., lowercase)
        self.rawValue = rawValue
    }

    public static func < (lhs: PropertyID, rhs: PropertyID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Standard Property IDs

public extension PropertyID {
    // --- General ---
    /// Indicates whether an entity is currently considered "lit".
    /// Typically computed based on light sources in scope.
    static let isLit = PropertyID("isLit")

    /// The current carrying capacity of a container item.
    /// Might be computed based on contents or other factors.
    static let currentCapacity = PropertyID("currentCapacity")

    // --- Descriptions ---
    /// The primary, detailed description (ZIL LDESC).
    static let longDescription = PropertyID("longDescription")
    /// The shorter description used in lists or brief mentions (ZIL SDESC).
    static let shortDescription = PropertyID("shortDescription")
    /// The description shown the first time an item is seen in a room (ZIL FDESC). (Item only)
    static let itemFirstDescription = PropertyID("itemFirstDescription")
    /// Text read from an item (ZIL RTEXT/TEXT). (Item only)
    static let itemReadText = PropertyID("itemReadText")
    /// Text read only when item is held (ZIL HTEXT). (Item only)
    static let itemHeldText = PropertyID("itemHeldText")


    // Add other standard property IDs as needed, e.g., for lock states,
    // open/closed states, specific game mechanics, etc.
}
