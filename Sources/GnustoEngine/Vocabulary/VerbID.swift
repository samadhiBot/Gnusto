import Foundation

/// A unique identifier for a verb within the game's vocabulary.
public struct VerbID: GnustoID {
    public let rawValue: String

    /// Initializes a `VerbID` with a raw string value.
    /// - Parameter rawValue: The string value for the ID.
    public init(rawValue: String) {
        assert(!rawValue.isEmpty, "Verb ID cannot be empty")
        self.rawValue = rawValue
    }
}

// MARK: - Interactive verbs

extension VerbID {
    public static let close = VerbID("close")
    public static let drop = VerbID("drop")
    public static let examine = VerbID("examine")
    public static let give = VerbID("give")
    public static let go = VerbID("go")
    public static let insert = VerbID("insert")
    public static let inventory = VerbID("inventory")
    public static let listen = VerbID("listen")
    public static let lock = VerbID("lock")
    public static let look = VerbID("look")
    public static let open = VerbID("open")
    public static let push = VerbID("push")
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
    public static let xyzzy = VerbID("xyzzy")
}

// MARK: - Meta verbs

extension VerbID {
    public static let brief = VerbID("brief")
    public static let help = VerbID("help")
    public static let quit = VerbID("quit")
    public static let restore = VerbID("restore")
    public static let save = VerbID("save")
    public static let score = VerbID("score")
    public static let verbose = VerbID("verbose")
    public static let wait = VerbID("wait")
}

#if DEBUG

// MARK: - Debug verb

extension VerbID {
    public static let debug = VerbID("debug")
}

#endif
