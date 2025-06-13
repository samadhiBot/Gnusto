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
    public static let ask = VerbID("ask")
    public static let attack = VerbID("attack")
    public static let breathe = VerbID("breathe")
    public static let climb = VerbID("climb")
    public static let climbOn = VerbID("climbOn")
    public static let close = VerbID("close")
    public static let cut = VerbID("cut")
    public static let dig = VerbID("dig")
    public static let drink = VerbID("drink")
    public static let drop = VerbID("drop")
    public static let eat = VerbID("eat")
    public static let examine = VerbID("examine")
    public static let fill = VerbID("fill")
    public static let find = VerbID("find")
    public static let burn = VerbID("burn")
    public static let give = VerbID("give")
    public static let go = VerbID("go")
    public static let insert = VerbID("insert")
    public static let inventory = VerbID("inventory")
    public static let kick = VerbID("kick")
    public static let kiss = VerbID("kiss")
    public static let knock = VerbID("knock")
    public static let listen = VerbID("listen")
    public static let lock = VerbID("lock")
    public static let look = VerbID("look")
    public static let lookUnder = VerbID("lookUnder")
    public static let lookInside = VerbID("lookInside")
    public static let move = VerbID("move")
    public static let open = VerbID("open")
    public static let pourOn = VerbID("pourOn")
    public static let push = VerbID("push")
    public static let putOn = VerbID("putOn")
    public static let raise = VerbID("raise")
    public static let read = VerbID("read")
    public static let remove = VerbID("remove")
    public static let rub = VerbID("rub")
    public static let shake = VerbID("shake")
    public static let smell = VerbID("smell")
    public static let squeeze = VerbID("squeeze")
    public static let take = VerbID("take")
    public static let taste = VerbID("taste")
    public static let tell = VerbID("tell")
    public static let thinkAbout = VerbID("thinkAbout")
    public static let throwItem = VerbID("throw")
    public static let tie = VerbID("tie")
    public static let touch = VerbID("touch")
    public static let turn = VerbID("turn")
    public static let turnOff = VerbID("turnOff")
    public static let turnOn = VerbID("turnOn")
    public static let unlock = VerbID("unlock")
    public static let wave = VerbID("wave")
    public static let wear = VerbID("wear")
    public static let xyzzy = VerbID("xyzzy")
}

// MARK: - Priority 2: Movement & Navigation verbs

extension VerbID {
    public static let climbDown = VerbID("climbDown")
    public static let climbUp = VerbID("climbUp")
    public static let enter = VerbID("enter")
    public static let exit = VerbID("exit")
    public static let getOff = VerbID("getOff")
    public static let getOut = VerbID("getOut")
    public static let jump = VerbID("jump")
    public static let jumpOff = VerbID("jumpOff")
    public static let jumpOut = VerbID("jumpOut")
    public static let leave = VerbID("leave")
    public static let lookDown = VerbID("lookDown")
    public static let lookUp = VerbID("lookUp")
    public static let swim = VerbID("swim")
    public static let walk = VerbID("walk")
}

// MARK: - Meta verbs

extension VerbID {
    public static let brief = VerbID("brief")
    public static let help = VerbID("help")
    public static let quit = VerbID("quit")
    public static let restart = VerbID("restart")
    public static let restore = VerbID("restore")
    public static let save = VerbID("save")
    public static let score = VerbID("score")
    public static let script = VerbID("script")
    public static let unscript = VerbID("unscript")
    public static let verbose = VerbID("verbose")
    public static let wait = VerbID("wait")
}

#if DEBUG

// MARK: - Debug verb

extension VerbID {
    public static let debug = VerbID("debug")
}

#endif
