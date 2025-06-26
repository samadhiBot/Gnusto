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
        id: "switch",
        intents: .turn, .push
    )

    public static let `throw` = Verb(
        id: "throw",
        intents: .throwObject, .give
    )

    public static let ascend = Verb(
        id: "ascend",
        intents: .climb
    )

    public static let ask = Verb(
        id: "ask",
        intents: .ask
    )

    public static let attack = Verb(
        id: "attack",
        intents: .attack
    )

    public static let balance = Verb(
        id: "balance",
        intents: .push, .turn
    )

    public static let bind = Verb(
        id: "bind",
        intents: .tie
    )

    public static let bite = Verb(
        id: "bite",
        intents: .attack, .eat
    )

    public static let blow = Verb(
        id: "blow",
        intents: .push, .extinguish
    )

    public static let brandish = Verb(
        id: "brandish",
        intents: .attack
    )

    public static let breathe = Verb(
        id: "breathe",
        intents: .touch
    )

    public static let brief = Verb(
        id: "brief",
        intents: .help
    )

    public static let burn = Verb(
        id: "burn",
        intents: .burn
    )

    public static let chew = Verb(
        id: "chew",
        intents: .eat
    )

    public static let chomp = Verb(
        id: "chomp",
        intents: .eat
    )

    public static let chop = Verb(
        id: "chop",
        intents: .cut, .attack
    )

    public static let chortle = Verb(
        id: "chortle",
        intents: .tell
    )

    public static let chuck = Verb(
        id: "chuck",
        intents: .throwObject
    )

    public static let chuckle = Verb(
        id: "chuckle",
        intents: .tell
    )

    public static let clean = Verb(
        id: "clean",
        intents: .touch
    )

    public static let climb = Verb(
        id: "climb",
        intents: .climb
    )

    public static let close = Verb(
        id: "close",
        intents: .close
    )

    public static let compress = Verb(
        id: "compress",
        intents: .push
    )

    public static let consider = Verb(
        id: "consider",
        intents: .think
    )

    public static let consume = Verb(
        id: "consume",
        intents: .eat
    )

    public static let cry = Verb(
        id: "cry",
        intents: .tell
    )

    public static let curse = Verb(
        id: "curse",
        intents: .tell
    )

    public static let cut = Verb(
        id: "cut",
        intents: .cut
    )

    public static let damn = Verb(
        id: "damn",
        intents: .tell
    )

    public static let dance = Verb(
        id: "dance",
        intents: .tell
    )

    public static let debug = Verb(
        id: "debug",
        intents: .debug
    )

    public static let deflate = Verb(
        id: "deflate",
        intents: .push
    )

    public static let depress = Verb(
        id: "depress",
        intents: .push
    )

    public static let devour = Verb(
        id: "devour",
        intents: .eat
    )

    public static let dig = Verb(
        id: "dig",
        intents: .dig
    )

    public static let discard = Verb(
        id: "discard",
        intents: .drop
    )

    public static let doff = Verb(
        id: "doff",
        intents: .remove
    )

    public static let don = Verb(
        id: "don",
        intents: .wear
    )

    public static let donate = Verb(
        id: "donate",
        intents: .give
    )

    public static let douse = Verb(
        id: "douse",
        intents: .extinguish
    )

    public static let drink = Verb(
        id: "drink",
        intents: .drink
    )

    public static let drop = Verb(
        id: "drop",
        intents: .drop
    )

    public static let dump = Verb(
        id: "dump",
        intents: .drop
    )

    public static let eat = Verb(
        id: "eat",
        intents: .eat
    )

    public static let empty = Verb(
        id: "empty",
        intents: .empty
    )

    public static let enter = Verb(
        id: "enter",
        intents: .enter
    )

    public static let examine = Verb(
        id: "examine",
        intents: .examine
    )

    public static let excavate = Verb(
        id: "excavate",
        intents: .dig
    )

    public static let extinguish = Verb(
        id: "extinguish",
        intents: .extinguish
    )

    public static let fasten = Verb(
        id: "fasten",
        intents: .tie
    )

    public static let feel = Verb(
        id: "feel",
        intents: .touch
    )

    public static let fight = Verb(
        id: "fight",
        intents: .attack
    )

    public static let fill = Verb(
        id: "fill",
        intents: .fill
    )

    public static let find = Verb(
        id: "find",
        intents: .search
    )

    public static let fuck = Verb(
        id: "fuck",
        intents: .tell
    )

    public static let get = Verb(
        id: "get",
        intents: .take
    )

    public static let giggle = Verb(
        id: "giggle",
        intents: .tell
    )

    public static let give = Verb(
        id: "give",
        intents: .give
    )

    public static let go = Verb(
        id: "go",
        intents: .move
    )

    public static let grab = Verb(
        id: "grab",
        intents: .take
    )

    public static let hang = Verb(
        id: "hang",
        intents: .insert, .attack
    )

    public static let head = Verb(
        id: "head",
        intents: .move
    )

    public static let help = Verb(
        id: "help",
        intents: .help
    )

    public static let hike = Verb(
        id: "hike",
        intents: .move
    )

    public static let hit = Verb(
        id: "hit",
        intents: .attack
    )

    public static let hoist = Verb(
        id: "hoist",
        intents: .pull
    )

    public static let holler = Verb(
        id: "holler",
        intents: .tell
    )

    public static let hop = Verb(
        id: "hop",
        intents: .jump
    )

    public static let hum = Verb(
        id: "hum",
        intents: .tell
    )

    public static let hurl = Verb(
        id: "hurl",
        intents: .throwObject
    )

    public static let ignite = Verb(
        id: "ignite",
        intents: .lightSource
    )

    public static let imbibe = Verb(
        id: "imbibe",
        intents: .drink
    )

    public static let inflate = Verb(
        id: "inflate",
        intents: .push
    )

    public static let inform = Verb(
        id: "inform",
        intents: .tell
    )

    public static let insert = Verb(
        id: "insert",
        intents: .insert
    )

    public static let inspect = Verb(
        id: "inspect",
        intents: .examine
    )

    public static let inventory = Verb(
        id: "inventory",
        intents: .inventory
    )

    public static let jump = Verb(
        id: "jump",
        intents: .jump
    )

    public static let kick = Verb(
        id: "kick",
        intents: .attack
    )

    public static let kill = Verb(
        id: "kill",
        intents: .attack
    )

    public static let kiss = Verb(
        id: "kiss",
        intents: .touch
    )

    public static let knock = Verb(
        id: "knock",
        intents: .push, .attack
    )

    public static let laugh = Verb(
        id: "laugh",
        intents: .tell
    )

    public static let leap = Verb(
        id: "leap",
        intents: .jump
    )

    public static let lick = Verb(
        id: "lick",
        intents: .taste, .touch
    )

    public static let lift = Verb(
        id: "lift",
        intents: .take, .pull
    )

    public static let light = Verb(
        id: "light",
        intents: .lightSource
    )

    public static let listen = Verb(
        id: "listen",
        intents: .listen
    )

    public static let load = Verb(
        id: "load",
        intents: .insert
    )

    public static let locate = Verb(
        id: "locate",
        intents: .search
    )

    public static let lock = Verb(
        id: "lock",
        intents: .lock
    )

    public static let look = Verb(
        id: "look",
        intents: .look, .examine
    )

    public static let mount = Verb(
        id: "mount",
        intents: .climb
    )

    public static let move = Verb(
        id: "move",
        intents: .push, .take
    )

    public static let offer = Verb(
        id: "offer",
        intents: .give
    )

    public static let open = Verb(
        id: "open",
        intents: .open
    )

    public static let peek = Verb(
        id: "peek",
        intents: .examine
    )

    public static let pick = Verb(
        id: "pick",
        intents: .take, .search
    )

    public static let place = Verb(
        id: "place",
        intents: .insert
    )

    public static let polish = Verb(
        id: "polish",
        intents: .touch
    )

    public static let ponder = Verb(
        id: "ponder",
        intents: .think
    )

    public static let pour = Verb(
        id: "pour",
        intents: .pour
    )

    public static let press = Verb(
        id: "press",
        intents: .push
    )

    public static let proceed = Verb(
        id: "proceed",
        intents: .move
    )

    public static let prune = Verb(
        id: "prune",
        intents: .cut
    )

    public static let puff = Verb(
        id: "puff",
        intents: .push, .extinguish
    )

    public static let pull = Verb(
        id: "pull",
        intents: .pull
    )

    public static let push = Verb(
        id: "push",
        intents: .push
    )

    public static let put = Verb(
        id: "put",
        intents: .insert
    )

    public static let quaff = Verb(
        id: "quaff",
        intents: .drink
    )

    public static let question = Verb(
        id: "question",
        intents: .ask
    )

    public static let quit = Verb(
        id: "quit",
        intents: .quit
    )

    public static let raise = Verb(
        id: "raise",
        intents: .pull, .take
    )

    public static let rap = Verb(
        id: "rap",
        intents: .push, .attack
    )

    public static let rattle = Verb(
        id: "rattle",
        intents: .push
    )

    public static let read = Verb(
        id: "read",
        intents: .read
    )

    public static let remove = Verb(
        id: "remove",
        intents: .remove
    )

    public static let restart = Verb(
        id: "restart",
        intents: .restart
    )

    public static let restore = Verb(
        id: "restore",
        intents: .restore
    )

    public static let rotate = Verb(
        id: "rotate",
        intents: .turn
    )

    public static let rub = Verb(
        id: "rub",
        intents: .touch
    )

    public static let run = Verb(
        id: "run",
        intents: .move
    )

    public static let save = Verb(
        id: "save",
        intents: .save
    )

    public static let scale = Verb(
        id: "scale",
        intents: .climb
    )

    public static let score = Verb(
        id: "score",
        intents: .help
    )

    public static let scream = Verb(
        id: "scream",
        intents: .tell
    )

    public static let script = Verb(
        id: "script",
        intents: .help
    )

    public static let search = Verb(
        id: "search",
        intents: .search
    )

    public static let set = Verb(
        id: "set",
        intents: .insert, .push
    )

    public static let shake = Verb(
        id: "shake",
        intents: .push
    )

    public static let shift = Verb(
        id: "shift",
        intents: .push, .turn
    )

    public static let shit = Verb(
        id: "shit",
        intents: .tell
    )

    public static let shout = Verb(
        id: "shout",
        intents: .tell
    )

    public static let shove = Verb(
        id: "shove",
        intents: .push
    )

    public static let shriek = Verb(
        id: "shriek",
        intents: .tell
    )

    public static let shut = Verb(
        id: "shut",
        intents: .close
    )

    public static let sing = Verb(
        id: "sing",
        intents: .tell
    )

    public static let sip = Verb(
        id: "sip",
        intents: .drink
    )

    public static let sit = Verb(
        id: "sit",
        intents: .sit
    )

    public static let slay = Verb(
        id: "slay",
        intents: .attack
    )

    public static let slice = Verb(
        id: "slice",
        intents: .cut, .attack
    )

    public static let slide = Verb(
        id: "slide",
        intents: .push
    )

    public static let smell = Verb(
        id: "smell",
        intents: .smell
    )

    public static let snicker = Verb(
        id: "snicker",
        intents: .tell
    )

    public static let sniff = Verb(
        id: "sniff",
        intents: .smell
    )

    public static let sob = Verb(
        id: "sob",
        intents: .tell
    )

    public static let spill = Verb(
        id: "spill",
        intents: .empty, .drop
    )

    public static let squeeze = Verb(
        id: "squeeze",
        intents: .push
    )

    public static let stab = Verb(
        id: "stab",
        intents: .attack, .cut
    )

    public static let steal = Verb(
        id: "steal",
        intents: .take
    )

    public static let stroll = Verb(
        id: "stroll",
        intents: .move
    )

    public static let swear = Verb(
        id: "swear",
        intents: .tell
    )

    public static let take = Verb(
        id: "take",
        intents: .take
    )

    public static let tap = Verb(
        id: "tap",
        intents: .push, .touch
    )

    public static let taste = Verb(
        id: "taste",
        intents: .taste
    )

    public static let tell = Verb(
        id: "tell",
        intents: .tell
    )

    public static let think = Verb(
        id: "think",
        intents: .think
    )

    public static let tie = Verb(
        id: "tie",
        intents: .tie
    )

    public static let toss = Verb(
        id: "toss",
        intents: .throwObject
    )

    public static let touch = Verb(
        id: "touch",
        intents: .touch
    )

    public static let travel = Verb(
        id: "travel",
        intents: .move
    )

    public static let turn = Verb(
        id: "turn",
        intents: .turn, .lightSource
    )

    public static let twist = Verb(
        id: "twist",
        intents: .turn
    )

    public static let unlock = Verb(
        id: "unlock",
        intents: .unlock
    )

    public static let unscript = Verb(
        id: "unscript",
        intents: .help
    )

    public static let verbose = Verb(
        id: "verbose",
        intents: .help
    )

    public static let wait = Verb(
        id: "wait",
        intents: .wait
    )

    public static let walk = Verb(
        id: "walk",
        intents: .move
    )

    public static let wave = Verb(
        id: "wave",
        intents: .attack, .tell
    )

    public static let wear = Verb(
        id: "wear",
        intents: .wear
    )

    public static let weep = Verb(
        id: "weep",
        intents: .tell
    )

    public static let xyzzy = Verb(
        id: "xyzzy",
        intents: .tell
    )

    public static let yell = Verb(
        id: "yell",
        intents: .tell
    )
}
