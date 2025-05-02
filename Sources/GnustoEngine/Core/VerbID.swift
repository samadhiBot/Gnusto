import Foundation

/// A unique identifier for a verb within the game's vocabulary.
public struct VerbID: Hashable, Comparable, Codable, ExpressibleByStringLiteral, Sendable {
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

    public static func < (lhs: VerbID, rhs: VerbID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
