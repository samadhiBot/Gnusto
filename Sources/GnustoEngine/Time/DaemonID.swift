import Foundation

/// A unique identifier for a `Daemon`.
public struct DaemonID: Hashable, Comparable, Codable, ExpressibleByStringLiteral, Sendable {
    public let rawValue: String

    /// Initializes an `DaemonID` using a string literal.
    /// - Parameter value: The string literal representing the item ID.
    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    /// Initializes an `DaemonID` with a raw string value.
    /// - Parameter rawValue: The string value for the ID.
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static func < (lhs: DaemonID, rhs: DaemonID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
