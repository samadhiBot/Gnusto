import Foundation

/// A unique identifier for a piece of contextual data relevant to an action.
///
/// Unlike `AttributeID` which identifies stored state, `ContextID` typically identifies
/// transient information calculated or gathered specifically for the current action execution.
public struct ContextID: Hashable, Comparable, Codable, ExpressibleByStringLiteral, Sendable {
    /// The underlying string value of the context identifier.
    /// You typically use this when you need to define or check a specific `ContextID`.
    public let rawValue: String

    /// Initializes a `ContextID` using a string literal.
    ///
    /// This allows you to create a `ContextID` directly from a string, for example:
    /// ```swift
    /// let currentPhase: ContextID = "gamePhase"
    /// ```
    /// - Parameter value: The string literal to use as the raw value for the `ContextID`.
    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    /// Initializes a `ContextID` with a raw string value.
    ///
    /// Use this initializer to create a `ContextID` programmatically from a string variable.
    /// - Parameter rawValue: The string value that uniquely identifies this context key.
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    /// Compares two `ContextID` instances based on their `rawValue`s for ordering.
    /// This is primarily used for sorting or storing `ContextID`s in ordered collections.
    /// - Parameters:
    ///   - lhs: A `ContextID` to compare.
    ///   - rhs: Another `ContextID` to compare.
    /// - Returns: `true` if the `rawValue` of `lhs` lexicographically precedes that of `rhs`;
    ///   otherwise, `false`.
    public static func < (lhs: ContextID, rhs: ContextID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Example Context IDs
// Games can define common context keys.
/*
extension ContextID {
    static let npcMood: ContextID = "npcMood"
    static let justTakenItem: ContextID = "justTakenItem"
    static let turnSequence: ContextID = "turnSequence"
}
*/
