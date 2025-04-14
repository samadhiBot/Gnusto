import Foundation

/// A unique, canonical identifier for a command verb.
///
/// Verb IDs are typically created from lowercase strings without spaces.
/// They conform to `ExpressibleByStringLiteral` for ease of use.
public struct VerbID: Codable, Hashable, ExpressibleByStringLiteral, Sendable {
    /// The underlying string value of the verb ID.
    public let rawValue: String

    /// Creates a VerbID from a string literal.
    ///
    /// The value is automatically trimmed and lowercased.
    /// - Parameter value: The string literal.
    public init(stringLiteral value: StringLiteralType) {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        assert(!trimmedValue.isEmpty, "Verb.ID cannot be empty.")
        // Could add more assertions, e.g., assert(!trimmedValue.contains(" "), "Verb.ID should not contain spaces.")
        rawValue = trimmedValue
    }

    /// Creates a VerbID from a String.
    ///
    /// This initializer uses the `ExpressibleByStringLiteral` initializer for consistency.
    /// - Parameter value: The string value.
    public init(_ value: String) {
        self = VerbID(stringLiteral: value)
    }
}

extension VerbID: Comparable {
    /// Compares two VerbIDs based on their raw string values.
    public static func < (lhs: VerbID, rhs: VerbID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Canonical action verbs

extension VerbID {
    static let `throw` = VerbID(stringLiteral: "throw")
    static let attack = VerbID(stringLiteral: "attack")
    static let close = VerbID(stringLiteral: "close")
    static let drink = VerbID(stringLiteral: "drink")
    static let drop = VerbID(stringLiteral: "drop")
    static let examine = VerbID(stringLiteral: "examine")
    static let extinguish = VerbID(stringLiteral: "extinguish")
    static let get = VerbID(stringLiteral: "get")
    static let go = VerbID(stringLiteral: "go")
    static let grab = VerbID(stringLiteral: "grab")
    static let help = VerbID(stringLiteral: "help")
    static let hit = VerbID(stringLiteral: "hit")
    static let insert = VerbID(stringLiteral: "insert")
    static let light = VerbID(stringLiteral: "light")
    static let lock = VerbID(stringLiteral: "lock")
    static let look = VerbID(stringLiteral: "look")
    static let open = VerbID(stringLiteral: "open")
    static let pick = VerbID(stringLiteral: "pick")
    static let put = VerbID(stringLiteral: "put")
    static let read = VerbID(stringLiteral: "read")
    static let restore = VerbID(stringLiteral: "restore")
    static let save = VerbID(stringLiteral: "save")
    static let score = VerbID(stringLiteral: "score")
    static let swallow = VerbID(stringLiteral: "swallow")
    static let take = VerbID(stringLiteral: "take")
    static let takeOff = VerbID(stringLiteral: "takeOff")
    static let talk = VerbID(stringLiteral: "talk")
    static let toss = VerbID(stringLiteral: "toss")
    static let turnOff = VerbID(stringLiteral: "turnOff")
    static let turnOn = VerbID(stringLiteral: "turnOn")
    static let unlock = VerbID(stringLiteral: "unlock")
    static let wait = VerbID(stringLiteral: "wait")
    static let walk = VerbID(stringLiteral: "walk")
    static let wear = VerbID(stringLiteral: "wear")
}

// MARK: - Directional verbs

extension VerbID {
    static let north = VerbID(stringLiteral: "north")
    static let northeast = VerbID(stringLiteral: "northeast")
    static let east = VerbID(stringLiteral: "east")
    static let southeast = VerbID(stringLiteral: "southeast")
    static let south = VerbID(stringLiteral: "south")
    static let southwest = VerbID(stringLiteral: "southwest")
    static let west = VerbID(stringLiteral: "west")
    static let northwest = VerbID(stringLiteral: "northwest")
    static let up = VerbID(stringLiteral: "up")
    static let down = VerbID(stringLiteral: "down")
}

// MARK: - Meta verbs

extension VerbID {
    static let inventory = VerbID(stringLiteral: "inventory")
    static let quit = VerbID(stringLiteral: "quit")
    static let undo = VerbID(stringLiteral: "undo")
    static let version = VerbID(stringLiteral: "version")
}
