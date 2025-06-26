import Foundation

/// A unique identifier for a verb within the game's vocabulary.
public struct Verb: GnustoID {
    public let rawValue: String

    /// <#Description#>
    public let intents: [Intent]

    @available(*, deprecated, renamed: "init(id:intents:)")
    /// Initializes a `Verb` with a raw string value.
    /// - Parameter rawValue: The string value for the ID.
    public init(rawValue: String) {
        assert(!rawValue.isEmpty, "Verb ID cannot be empty")
        self.rawValue = rawValue
        self.intents = []
    }

    /// <#Description#>
    /// - Parameters:
    ///   - rawValue: <#rawValue description#>
    ///   - intents: <#intents description#>
    public init(
        id rawValue: String,
        intents: Intent...
    ) {
        assert(!rawValue.isEmpty, "Verb ID cannot be empty")
        self.rawValue = rawValue
        self.intents = intents
    }
}

// MARK: - Interactive verbs

extension Verb {
    public static let `switch` = Verb(
        id: "switch"
    )

    public static let `throw` = Verb(
        id: "throw",
        intents: .throwObject, .give
    )

    public static let ascend = Verb(
        id: "ascend"
    )

    public static let ask = Verb(
        id: "ask"
    )

    public static let attack = Verb(
        id: "attack"
    )

    public static let balance = Verb(
        id: "balance"
    )

    public static let bind = Verb(
        id: "bind"
    )

    public static let bite = Verb(
        id: "bite"
    )

    public static let blow = Verb(
        id: "blow"
    )

    public static let brandish = Verb(
        id: "brandish"
    )

    public static let breathe = Verb(
        id: "breathe"
    )

    public static let brief = Verb(
        id: "brief"
    )

    public static let burn = Verb(
        id: "burn"
    )

    public static let chew = Verb(
        id: "chew"
    )

    public static let chomp = Verb(
        id: "chomp"
    )

    public static let chop = Verb(
        id: "chop"
    )

    public static let chortle = Verb(
        id: "chortle"
    )

    public static let chuck = Verb(
        id: "chuck"
    )

    public static let chuckle = Verb(
        id: "chuckle"
    )

    public static let clean = Verb(
        id: "clean"
    )

    public static let climb = Verb(
        id: "climb"
    )

    public static let close = Verb(
        id: "close"
    )

    public static let compress = Verb(
        id: "compress"
    )

    public static let consider = Verb(
        id: "consider"
    )

    public static let consume = Verb(
        id: "consume"
    )

    public static let cry = Verb(
        id: "cry"
    )

    public static let curse = Verb(
        id: "curse"
    )

    public static let cut = Verb(
        id: "cut"
    )

    public static let damn = Verb(
        id: "damn"
    )

    public static let dance = Verb(
        id: "dance"
    )

    public static let debug = Verb(
        id: "debug"
    )

    public static let deflate = Verb(
        id: "deflate"
    )

    public static let depress = Verb(
        id: "depress"
    )

    public static let devour = Verb(
        id: "devour"
    )

    public static let dig = Verb(
        id: "dig"
    )

    public static let discard = Verb(
        id: "discard"
    )

    public static let doff = Verb(
        id: "doff"
    )

    public static let don = Verb(
        id: "don"
    )

    public static let donate = Verb(
        id: "donate"
    )

    public static let douse = Verb(
        id: "douse"
    )

    public static let drink = Verb(
        id: "drink"
    )

    public static let drop = Verb(
        id: "drop"
    )

    public static let dump = Verb(
        id: "dump"
    )

    public static let eat = Verb(
        id: "eat"
    )

    public static let empty = Verb(
        id: "empty"
    )

    public static let enter = Verb(
        id: "enter"
    )

    public static let examine = Verb(
        id: "examine"
    )

    public static let excavate = Verb(
        id: "excavate"
    )

    public static let extinguish = Verb(
        id: "extinguish"
    )

    public static let fasten = Verb(
        id: "fasten"
    )

    public static let feel = Verb(
        id: "feel"
    )

    public static let fight = Verb(
        id: "fight"
    )

    public static let fill = Verb(
        id: "fill"
    )

    public static let find = Verb(
        id: "find"
    )

    public static let fuck = Verb(
        id: "fuck"
    )

    public static let get = Verb(
        id: "get"
    )

    public static let giggle = Verb(
        id: "giggle"
    )

    public static let give = Verb(
        id: "give"
    )

    public static let go = Verb(
        id: "go"
    )

    public static let grab = Verb(
        id: "grab"
    )

    public static let hang = Verb(
        id: "hang"
    )

    public static let head = Verb(
        id: "head"
    )

    public static let help = Verb(
        id: "help"
    )

    public static let hike = Verb(
        id: "hike"
    )

    public static let hit = Verb(
        id: "hit"
    )

    public static let hoist = Verb(
        id: "hoist"
    )

    public static let holler = Verb(
        id: "holler"
    )

    public static let hop = Verb(
        id: "hop"
    )

    public static let hum = Verb(
        id: "hum"
    )

    public static let hurl = Verb(
        id: "hurl"
    )

    public static let ignite = Verb(
        id: "ignite"
    )

    public static let imbibe = Verb(
        id: "imbibe"
    )

    public static let inflate = Verb(
        id: "inflate"
    )

    public static let inform = Verb(
        id: "inform"
    )

    public static let insert = Verb(
        id: "insert"
    )

    public static let inspect = Verb(
        id: "inspect"
    )

    public static let inventory = Verb(
        id: "inventory"
    )

    public static let jump = Verb(
        id: "jump"
    )

    public static let kick = Verb(
        id: "kick"
    )

    public static let kill = Verb(
        id: "kill"
    )

    public static let kiss = Verb(
        id: "kiss"
    )

    public static let knock = Verb(
        id: "knock"
    )

    public static let laugh = Verb(
        id: "laugh"
    )

    public static let leap = Verb(
        id: "leap"
    )

    public static let lick = Verb(
        id: "lick"
    )

    public static let lift = Verb(
        id: "lift"
    )

    public static let light = Verb(
        id: "light"
    )

    public static let listen = Verb(
        id: "listen"
    )

    public static let load = Verb(
        id: "load"
    )

    public static let locate = Verb(
        id: "locate"
    )

    public static let lock = Verb(
        id: "lock"
    )

    public static let look = Verb(
        id: "look"
    )

    public static let mount = Verb(
        id: "mount"
    )

    public static let move = Verb(
        id: "move"
    )

    public static let offer = Verb(
        id: "offer"
    )

    public static let open = Verb(
        id: "open"
    )

    public static let peek = Verb(
        id: "peek"
    )

    public static let pick = Verb(
        id: "pick"
    )

    public static let place = Verb(
        id: "place"
    )

    public static let polish = Verb(
        id: "polish"
    )

    public static let ponder = Verb(
        id: "ponder"
    )

    public static let pour = Verb(
        id: "pour"
    )

    public static let press = Verb(
        id: "press"
    )

    public static let proceed = Verb(
        id: "proceed"
    )

    public static let prune = Verb(
        id: "prune"
    )

    public static let puff = Verb(
        id: "puff"
    )

    public static let pull = Verb(
        id: "pull"
    )

    public static let push = Verb(
        id: "push"
    )

    public static let put = Verb(
        id: "put"
    )

    public static let quaff = Verb(
        id: "quaff"
    )

    public static let question = Verb(
        id: "question"
    )

    public static let quit = Verb(
        id: "quit"
    )

    public static let raise = Verb(
        id: "raise"
    )

    public static let rap = Verb(
        id: "rap"
    )

    public static let rattle = Verb(
        id: "rattle"
    )

    public static let read = Verb(
        id: "read"
    )

    public static let remove = Verb(
        id: "remove"
    )

    public static let restart = Verb(
        id: "restart"
    )

    public static let restore = Verb(
        id: "restore"
    )

    public static let rotate = Verb(
        id: "rotate"
    )

    public static let rub = Verb(
        id: "rub"
    )

    public static let run = Verb(
        id: "run"
    )

    public static let save = Verb(
        id: "save"
    )

    public static let scale = Verb(
        id: "scale"
    )

    public static let score = Verb(
        id: "score"
    )

    public static let scream = Verb(
        id: "scream"
    )

    public static let script = Verb(
        id: "script"
    )

    public static let search = Verb(
        id: "search"
    )

    public static let set = Verb(
        id: "set"
    )

    public static let shake = Verb(
        id: "shake"
    )

    public static let shift = Verb(
        id: "shift"
    )

    public static let shit = Verb(
        id: "shit"
    )

    public static let shout = Verb(
        id: "shout"
    )

    public static let shove = Verb(
        id: "shove"
    )

    public static let shriek = Verb(
        id: "shriek"
    )

    public static let shut = Verb(
        id: "shut"
    )

    public static let sing = Verb(
        id: "sing"
    )

    public static let sip = Verb(
        id: "sip"
    )

    public static let sit = Verb(
        id: "sit"
    )

    public static let slay = Verb(
        id: "slay"
    )

    public static let slice = Verb(
        id: "slice"
    )

    public static let slide = Verb(
        id: "slide"
    )

    public static let smell = Verb(
        id: "smell"
    )

    public static let snicker = Verb(
        id: "snicker"
    )

    public static let sniff = Verb(
        id: "sniff"
    )

    public static let sob = Verb(
        id: "sob"
    )

    public static let spill = Verb(
        id: "spill"
    )

    public static let squeeze = Verb(
        id: "squeeze"
    )

    public static let stab = Verb(
        id: "stab"
    )

    public static let steal = Verb(
        id: "steal"
    )

    public static let stroll = Verb(
        id: "stroll"
    )

    public static let swear = Verb(
        id: "swear"
    )

    public static let take = Verb(
        id: "take"
    )

    public static let tap = Verb(
        id: "tap"
    )

    public static let taste = Verb(
        id: "taste"
    )

    public static let tell = Verb(
        id: "tell"
    )

    public static let think = Verb(
        id: "think"
    )

    public static let tie = Verb(
        id: "tie"
    )

    public static let toss = Verb(
        id: "toss"
    )

    public static let touch = Verb(
        id: "touch"
    )

    public static let travel = Verb(
        id: "travel"
    )

    public static let turn = Verb(
        id: "turn"
    )

    public static let twist = Verb(
        id: "twist"
    )

    public static let unlock = Verb(
        id: "unlock"
    )

    public static let unscript = Verb(
        id: "unscript"
    )

    public static let verbose = Verb(
        id: "verbose"
    )

    public static let wait = Verb(
        id: "wait"
    )

    public static let walk = Verb(
        id: "walk"
    )

    public static let wave = Verb(
        id: "wave"
    )

    public static let wear = Verb(
        id: "wear"
    )

    public static let weep = Verb(
        id: "weep"
    )

    public static let xyzzy = Verb(
        id: "xyzzy"
    )

    public static let yell = Verb(
        id: "yell"
    )
}
