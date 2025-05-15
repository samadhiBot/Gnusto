import CustomDump
import Foundation

/// A unique identifier for a location within the game world.
public struct LocationID: Hashable, Comparable, Codable, ExpressibleByStringLiteral, Sendable {
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

    public static func < (lhs: LocationID, rhs: LocationID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - CustomDumpStringConvertible conformance

extension LocationID: CustomDumpStringConvertible {
    public var customDumpDescription: String {
        ".\(rawValue)"
    }
}
