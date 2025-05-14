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

extension VerbID {

    // Interactive

    public static let close = VerbID("close")
    public static let drop = VerbID("drop")
    public static let examine = VerbID("examine")
    public static let go = VerbID("go")
    public static let insert = VerbID("insert")
    public static let inventory = VerbID("inventory")
    public static let listen = VerbID("listen")
    public static let lock = VerbID("lock")
    public static let look = VerbID("look")
    public static let open = VerbID("open")
    public static let putOn = VerbID("putOn")
    public static let read = VerbID("read")
    public static let remove = VerbID("remove")
    public static let smell = VerbID("smell")
    public static let take = VerbID("take")
    public static let taste = VerbID("taste")
    public static let thinkAbout = VerbID("thinkAbout")
    public static let touch = VerbID("touch")
    public static let turnOff = VerbID("turnOff")
    public static let turnOn = VerbID("turnOn")
    public static let unlock = VerbID("unlock")
    public static let wear = VerbID("wear")

    // Meta Actions

    public static let brief = VerbID("brief")
    public static let help = VerbID("help")
    public static let quit = VerbID("quit")
    public static let restore = VerbID("restore")
    public static let save = VerbID("save")
    public static let score = VerbID("score")
    public static let verbose = VerbID("verbose")
    public static let wait = VerbID("wait")

    // Debug Action

    #if DEBUG
    public static let debug = VerbID("debug")
    #endif
}
