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

// MARK: - Common Property IDs (Example)
// Define standard property IDs here for discoverability and type safety.
// Games can extend this or define their own.
/*
extension PropertyID {
    static let isLit: PropertyID = "isLit"
    static let fuelLevel: PropertyID = "fuelLevel"
    static let isOpen: PropertyID = "isOpen"
}
*/
