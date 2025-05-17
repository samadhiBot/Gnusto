import Foundation

/// A unique identifier for a piece of contextual data relevant to an action.
///
/// Unlike `AttributeID` which identifies stored state, `ContextID` typically identifies
/// transient information calculated or gathered specifically for the current action execution.
public struct ContextID: Hashable, Comparable, Codable, ExpressibleByStringLiteral, Sendable {
    public let rawValue: String

    /// Initializes a `ContextID` using a string literal.
    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    /// Initializes a `ContextID` with a raw string value.
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

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
