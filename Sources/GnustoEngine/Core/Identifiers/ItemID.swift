import Foundation

/// A unique identifier for an item (GameObject) within the game world.
public struct ItemID: Hashable, Comparable, Codable, ExpressibleByStringLiteral, Sendable {
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

    public static func < (lhs: ItemID, rhs: ItemID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Standard Item IDs
public extension ItemID {
    /// Represents the player character as an item.
    static let player = ItemID("player")
}
