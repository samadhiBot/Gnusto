import CustomDump
import Foundation

/// A type-safe, unique identifier for an `Item` in the game world.
///
/// `ItemID` serves as the primary key for items, used to store and retrieve item data
/// in `GameState.items` and to refer to items in the `Vocabulary`, `SyntaxRule`s,
/// and game logic. Each item in a game must have a unique `ItemID`.
///
/// It is `Codable` for game state persistence and `ExpressibleByStringLiteral` for
/// convenient initialization (e.g., `let lanternID: ItemID = "brassLantern"`).
public struct ItemID: RawRepresentable, Hashable, Codable, Sendable {
    /// The underlying string value of the item identifier (e.g., "brassLantern").
    public let rawValue: String

    /// Initializes an `ItemID` with a raw string value.
    /// - Parameter rawValue: The string value for the ID.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Convenience initializer for backward compatibility.
    /// - Parameter rawValue: The string value for the ID.
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    /// Creates a new ItemID from a decoder.
    /// Required for `Codable` conformance.
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(String.self)
    }

    /// Encodes this ItemID into the given encoder.
    /// Required for `Codable` conformance.
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}

extension ItemID: Comparable {
    public static func < (lhs: ItemID, rhs: ItemID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension ItemID: CustomDumpStringConvertible {
    public var customDumpDescription: String {
        ".\(rawValue)"
    }
}

extension ItemID: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}

extension ItemID: ExpressibleByStringLiteral {
    /// Initializes an `ItemID` using a string literal.
    /// - Parameter value: The string literal representing the item ID.
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}

// MARK: - Standard Item IDs
public extension ItemID {
    /// Represents the player character as an item.
    static let player = ItemID("player")
}
