//import Foundation
//
//public struct Command: Sendable, Equatable {
//    public let verb: Verb
//    public let directObject: Object.ID?
//    public let indirectObject: Object.ID?
//    public let preposition: Preposition?
//    public let direction: Direction?
//
//    init(
//        verb: Verb,
//        directObject: Object.ID? = nil,
//        indirectObject: Object.ID? = nil,
//        preposition: Preposition? = nil,
//        direction: Direction? = nil
//    ) {
//        self.verb = verb
//        self.directObject = directObject
//        self.indirectObject = indirectObject
//        self.preposition = preposition
//        self.direction = direction
//    }
//}
//
//extension Command {
//    public init(
//        verb: Verb,
//        directObject: Object.ID? = nil,
//        indirectObject: Object.ID? = nil,
//        preposition: Preposition? = nil
//    ) {
//        self.verb = verb
//        self.directObject = directObject
//        self.indirectObject = indirectObject
//        self.preposition = preposition
//        self.direction = nil
//    }
//
//    /// Whether the command is a meta-command.
//    var isMeta: Bool {
//        [.help, .inventory, .look, .quit, .restore, .save, .undo, .version, .wait].contains(self)
//    }
//}
//
//// MARK: - Verb
//
//extension Command {
////    public struct Verb: Sendable, Hashable {
////        public let rawValues: [String]
////
////        public let worksInDarkness: Bool
////
////        public init(
////            _ rawValues: String...,
////            worksInDarkness: Bool = false
////        ) {
////            assert(!rawValues.isEmpty, "At least one word must be provided")
////            self.rawValues = rawValues
////            self.worksInDarkness = worksInDarkness
////        }
////
////        public var rawValue: String {
////            rawValues[0]
////        }
////
////        // Core verbs
////        public static let attack = Verb("attack", "hit", "kill", "destroy", "smash", "break")
////        public static let board = Verb("board", "enter")
////        public static let burn = Verb("burn", "incinerate", "ignite", "torch")
////        public static let climb = Verb("climb", "sit")
////        public static let close = Verb("close", "shut")
////        public static let cut = Verb("cut", "slice", "pierce")
////        public static let dig = Verb("dig")
////        public static let drink = Verb("drink", "imbibe", "swallow")
////        public static let drop = Verb("drop", "put…down", worksInDarkness: true)
////        public static let eat = Verb("eat", "consume", "taste", "bite", "scarf", "devour", "gulp", "chew")
////        public static let examine = Verb("examine", "x", "look…at", "describe", "what", "whats")
////        public static let fill = Verb("fill")
////        public static let give = Verb("give")
////        public static let inventory = Verb("inventory", "i", worksInDarkness: true)
////        public static let jump = Verb("jump")
////        public static let look = Verb("look", "l", worksInDarkness: true)
////        public static let lookUnder = Verb("look…under")
////        public static let lock = Verb("lock")
////        public static let move = Verb("move", "go", "walk", "cross", "ford", worksInDarkness: true)
////        public static let open = Verb("open")
////        public static let putIn = Verb("put…in", "insert", "place…in")
////        public static let putOn = Verb("put…on", "place…on", "set…on")
////        public static let push = Verb("push", "shove")
////        public static let pull = Verb("pull", "yank", "drag", "carry")
////        public static let read = Verb("read", "skim", "peruse")
////        public static let remove = Verb("remove", "take…off")
////        public static let rub = Verb("rub", "touch", "feel", "pat", "pet")
////        public static let search = Verb("search", "look…in")
////        public static let smell = Verb("smell", "sniff")
////        public static let swim = Verb("swim")
////        public static let take = Verb("take", "get", "pick…up", "grab")
////        public static let talk = Verb("talk", "tell", "say")
////        public static let toss = Verb("toss", "throw")
////        public static let turnOff = Verb("turn…off", "switch…off", "extinguish", "douse", worksInDarkness: true)
////        public static let turnOn = Verb("turn…on", "switch…on", "light", worksInDarkness: true)
////        public static let unlock = Verb("unlock")
////        public static let wait = Verb("wait", "z", worksInDarkness: true)
////        public static let wake = Verb("wake", "wake…up")
////        public static let wear = Verb("wear", "put…on", "don")
////        public static let wave = Verb("wave")
////
////        // Meta verbs
////        public static let help = Verb("help", "?", "h", worksInDarkness: true)
////        public static let quit = Verb("quit", worksInDarkness: true)
////        public static let restore = Verb("restore", worksInDarkness: true)
////        public static let save = Verb("save", worksInDarkness: true)
////        public static let undo = Verb("undo", worksInDarkness: true)
////        public static let version = Verb("version", worksInDarkness: true)
////
////        // Special case for unknown commands
////        public static func unknown(_ message: String) -> Verb {
////            Verb("unknown: \(message)")
////        }
////    }
//}
//
//// MARK: - Preposition
//
//
//// MARK: - Convenience initializers
//
//extension Command {
//    /// Convenience initializer for the help command.
//    public static let help = Command(verb: .help)
//
//    /// Convenience initializer for the inventory command.
//    public static let inventory = Command(verb: .inventory)
//
//    /// Convenience initializer for the look command.
//    public static let look = Command(verb: .look)
//
//    /// Convenience initializer for movement.
//    public static func move(_ direction: Direction) -> Command {
//        Command(verb: .move, direction: direction)
//    }
//
//    /// Convenience initializer for the quit command.
//    public static let quit = Command(verb: .quit)
//
//    /// Convenience initializer for the restore command.
//    public static let restore = Command(verb: .restore)
//
//    /// Convenience initializer for the save command.
//    public static let save = Command(verb: .save)
//
//    /// Convenience initializer for the undo command.
//    public static let undo = Command(verb: .undo)
//
//    /// Convenience initializer for the version command.
//    public static let version = Command(verb: .version)
//
//    /// Convenience initializer for the wait command.
//    public static let wait = Command(verb: .wait)
//
//    /// Convenience initializer for the unknown special case.
//    public static func unknown(_ message: String) -> Command {
//        Command(verb: .unknown(message))
//    }
//}
