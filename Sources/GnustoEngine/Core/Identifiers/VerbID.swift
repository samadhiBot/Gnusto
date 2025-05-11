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

    static let close = VerbID("close")
    static let drop = VerbID("drop")
    static let examine = VerbID("examine")
    static let go = VerbID("go")
    static let insert = VerbID("insert")
    static let inventory = VerbID("inventory")
    static let listen = VerbID("listen")
    static let lock = VerbID("lock")
    static let look = VerbID("look")
    static let open = VerbID("open")
    static let putOn = VerbID("putOn")
    static let read = VerbID("read")
    static let remove = VerbID("remove")
    static let smell = VerbID("smell")
    static let take = VerbID("take")
    static let taste = VerbID("taste")
    static let thinkAbout = VerbID("thinkAbout")
    static let touch = VerbID("touch")
    static let turnOff = VerbID("turnOff")
    static let turnOn = VerbID("turnOn")
    static let unlock = VerbID("unlock")
    static let wear = VerbID("wear")

    // Meta Actions

    static let brief = VerbID("brief")
    static let help = VerbID("help")
    static let quit = VerbID("quit")
    static let restore = VerbID("restore")
    static let save = VerbID("save")
    static let score = VerbID("score")
    static let verbose = VerbID("verbose")
    static let wait = VerbID("wait")
}
