import Foundation

// swiftlint:disable file_length

/// A unique identifier for a verb within the game's vocabulary.
///
/// Verbs represent player actions in the interactive fiction engine. Each verb has a unique
/// identifier and can be associated with one or more intents that describe the conceptual
/// actions the verb can perform.
///
/// For example, the verb "light" might have intents for both `.lightSource` (turning on a lamp)
/// and `.burn` (setting something on fire), allowing the engine to route commands appropriately
/// based on context and available objects.
public struct Verb: GnustoID {
    /// The unique string identifier for this verb.
    public let rawValue: String

    /// The gerund (present participle) form of the verb.
    public let gerund: String

    /// The past participle form of the verb.
    public let pastParticiple: String

    /// The conceptual actions this verb can perform.
    ///
    /// Intents allow multiple verbs to map to the same underlying game actions.
    /// For example, "get", "take", "grab" might all have the `.take` intent.
    public let intents: [Intent]

    /// Initializes a `Verb` with a raw string value and no intents.
    ///
    /// This initializer is deprecated. Use `init(id:intents:)` instead to properly
    /// associate the verb with its conceptual actions.
    ///
    /// - Parameter rawValue: The unique string identifier for the verb.
    @available(*, deprecated, renamed: "init(id:intents:)")
    public init(rawValue: String) {
        assert(rawValue.isNotEmpty, "Verb rawValue cannot be empty")
        self.rawValue = rawValue
        self.gerund = "\(rawValue)-ing"
        self.pastParticiple = "\(rawValue)-ed"
        self.intents = []
    }

    /// Initializes a `Verb` with an identifier and associated intents.
    ///
    /// - Parameters:
    ///   - rawValue: The unique string identifier for the verb. Must not be empty.
    ///   - gerund: The gerund form of the verb. Only needs to be specified when irregular.
    ///   - pastParticiple: The past tense form of the verb. Only needs to be specified when irregular.
    ///   - intents: The conceptual actions this verb can perform. Multiple intents
    ///              allow a single verb to handle different types of actions based on context.
    public init(
        id rawValue: String,
        gerund: String? = nil,
        pastParticiple: String? = nil,
        intents: Intent...
    ) {
        assert(rawValue.isNotEmpty, "Verb rawValue cannot be empty")

        self.rawValue = rawValue
        self.gerund =
            if let gerund {
                gerund
            } else if rawValue.hasSuffix("e") {
                "\(rawValue.dropLast())ing"
            } else {
                "\(rawValue)ing"
            }
        self.pastParticiple =
            if let pastParticiple {
                pastParticiple
            } else if rawValue.hasSuffix("e") {
                "\(rawValue)d"
            } else {
                "\(rawValue)ed"
            }
        self.intents = intents
    }
}

// MARK: - Interactive Verbs

/// Predefined verbs for common interactive fiction actions.
///
/// These static properties provide a comprehensive vocabulary of verbs that players
/// can use to interact with the game world. Each verb is associated with one or more
/// intents that describe the conceptual actions it can perform.
///
/// The verbs are organized alphabetically and include synonyms for common actions
/// to provide a rich and intuitive command interface.
extension Verb {
    /// Climb up or ascend something.
    public static let ascend = Verb(
        id: "ascend",
        intents: .climb
    )

    /// Ask a question or request information.
    public static let ask = Verb(
        id: "ask",
        intents: .ask
    )

    /// Attack or assault something.
    public static let attack = Verb(
        id: "attack",
        intents: .attack, .mung
    )

    /// Balance something, which may involve pushing or turning it.
    public static let balance = Verb(
        id: "balance",
        intents: .push, .turn
    )

    /// Bind or tie something together.
    public static let bind = Verb(
        id: "bind",
        pastParticiple: "bound",
        intents: .tie
    )

    /// Bite something, either as an attack or to eat it.
    public static let bite = Verb(
        id: "bite",
        pastParticiple: "bitten",
        intents: .attack, .eat
    )

    /// Blow on something to push it or extinguish it.
    public static let blow = Verb(
        id: "blow",
        pastParticiple: "blown",
        intents: .push, .extinguish
    )

    /// Brandish a weapon or object threateningly.
    public static let brandish = Verb(
        id: "brandish",
        intents: .attack
    )

    /// Break something.
    public static let `break` = Verb(
        id: "break",
        intents: .mung
    )

    /// Breathe on something (treated as touching).
    public static let breathe = Verb(
        id: "breathe",
        intents: .touch
    )

    /// Switch to brief mode (minimal room descriptions).
    public static let brief = Verb(
        id: "brief",
        intents: .help
    )

    /// Burn or set fire to something.
    public static let burn = Verb(
        id: "burn",
        intents: .burn
    )

    /// Chew on something (a form of eating).
    public static let chew = Verb(
        id: "chew",
        intents: .eat
    )

    /// Chomp or bite down on something (a form of eating).
    public static let chomp = Verb(
        id: "chomp",
        intents: .eat
    )

    /// Chop something, either to cut it or as an attack.
    public static let chop = Verb(
        id: "chop",
        gerund: "chopping",
        pastParticiple: "chopped",
        intents: .cut, .attack
    )

    /// Chortle or chuckle (a form of vocal expression).
    public static let chortle = Verb(
        id: "chortle",
        intents: .tell
    )

    /// Chuck or throw an object.
    public static let chuck = Verb(
        id: "chuck",
        intents: .throw
    )

    /// Chuckle or laugh softly (a form of vocal expression).
    public static let chuckle = Verb(
        id: "chuckle",
        intents: .tell
    )

    /// Clean something (treated as touching).
    public static let clean = Verb(
        id: "clean",
        intents: .touch
    )

    /// Climb up or onto something.
    public static let climb = Verb(
        id: "climb",
        intents: .climb
    )

    /// Close something that can be opened/closed.
    public static let close = Verb(
        id: "close",
        intents: .close
    )

    /// Compress or press down on something.
    public static let compress = Verb(
        id: "compress",
        intents: .push
    )

    /// Consider or think about something.
    public static let consider = Verb(
        id: "consider",
        intents: .think
    )

    /// Consume or eat something.
    public static let consume = Verb(
        id: "consume",
        intents: .eat
    )

    /// Cry out or weep (a form of vocal expression).
    public static let cry = Verb(
        id: "cry",
        pastParticiple: "cried",
        intents: .tell
    )

    /// Curse or swear (a form of vocal expression).
    public static let curse = Verb(
        id: "curse",
        intents: .tell
    )

    /// Cut something with a sharp object.
    public static let cut = Verb(
        id: "cut",
        pastParticiple: "cut",
        intents: .cut
    )

    /// Express frustration or curse (a form of vocal expression).
    public static let damn = Verb(
        id: "damn",
        intents: .tell
    )

    /// Dance or move rhythmically (treated as vocal expression for game purposes).
    public static let dance = Verb(
        id: "dance",
        intents: .turn
    )

    /// Enter debug mode or display debug information.
    public static let debug = Verb(
        id: "debug",
        pastParticiple: "debugged",
        intents: .debug
    )

    /// Deflate something by pressing or pushing.
    public static let deflate = Verb(
        id: "deflate",
        intents: .push
    )

    /// Depress or press down on something.
    public static let depress = Verb(
        id: "depress",
        intents: .push
    )

    /// Describe the details of something.
    public static let describe = Verb(
        id: "describe",
        intents: .examine
    )

    /// Destroy something.
    public static let destroy = Verb(
        id: "destroy",
        intents: .attack, .mung
    )

    /// Devour or eat something hungrily.
    public static let devour = Verb(
        id: "devour",
        intents: .eat
    )

    /// Dig in the ground or excavate.
    public static let dig = Verb(
        id: "dig",
        gerund: "digging",
        pastParticiple: "dug",
        intents: .dig
    )

    /// Discard or drop something.
    public static let discard = Verb(
        id: "discard",
        intents: .drop
    )

    /// Doff or remove clothing/accessories.
    public static let doff = Verb(
        id: "doff",
        intents: .remove
    )

    /// Don or put on clothing/accessories.
    public static let don = Verb(
        id: "don",
        pastParticiple: "donned",
        intents: .wear
    )

    /// Donate or give something away.
    public static let donate = Verb(
        id: "donate",
        intents: .give
    )

    /// Douse or extinguish a fire or light.
    public static let douse = Verb(
        id: "douse",
        intents: .extinguish
    )

    /// Drink a liquid.
    public static let drink = Verb(
        id: "drink",
        pastParticiple: "drunk",
        intents: .drink
    )

    /// Drop something from inventory.
    public static let drop = Verb(
        id: "drop",
        gerund: "dropping",
        pastParticiple: "dropped",
        intents: .drop
    )

    /// Dump or drop something carelessly.
    public static let dump = Verb(
        id: "dump",
        intents: .drop
    )

    /// Eat something edible.
    public static let eat = Verb(
        id: "eat",
        pastParticiple: "eaten",
        intents: .eat
    )

    /// Empty a container of its contents.
    public static let empty = Verb(
        id: "empty",
        pastParticiple: "emptied",
        intents: .empty
    )

    /// Enter a location or container.
    public static let enter = Verb(
        id: "enter",
        intents: .enter
    )

    /// Examine something closely for details.
    public static let examine = Verb(
        id: "examine",
        intents: .examine
    )

    /// Excavate or dig carefully.
    public static let excavate = Verb(
        id: "excavate",
        intents: .dig
    )

    /// Extinguish a fire or light source.
    public static let extinguish = Verb(
        id: "extinguish",
        intents: .extinguish
    )

    /// Fasten or tie something securely.
    public static let fasten = Verb(
        id: "fasten",
        intents: .tie
    )

    /// Feel or touch something with hands.
    public static let feel = Verb(
        id: "feel",
        pastParticiple: "felt",
        intents: .touch
    )

    /// Fight or engage in combat.
    public static let fight = Verb(
        id: "fight",
        pastParticiple: "fought",
        intents: .attack
    )

    /// Fill a container with something.
    public static let fill = Verb(
        id: "fill",
        intents: .fill
    )

    /// Find or search for something.
    public static let find = Verb(
        id: "find",
        pastParticiple: "found",
        intents: .search
    )

    /// Express strong emotion or frustration (a form of vocal expression).
    public static let fuck = Verb(
        id: "fuck",
        intents: .tell
    )

    /// Get or take something (synonym for "take").
    public static let get = Verb(
        id: "get",
        pastParticiple: "gotten",
        intents: .take
    )

    /// Giggle or laugh lightly (a form of vocal expression).
    public static let giggle = Verb(
        id: "giggle",
        intents: .tell
    )

    /// Give something to someone or something.
    public static let give = Verb(
        id: "give",
        pastParticiple: "given",
        intents: .give
    )

    /// Go or move in a direction.
    public static let go = Verb(
        id: "go",
        pastParticiple: "gone",
        intents: .move
    )

    /// Grab or seize something quickly.
    public static let grab = Verb(
        id: "grab",
        gerund: "grabbing",
        pastParticiple: "grabbed",
        intents: .take
    )

    /// Hang something up or use hanging as an attack.
    public static let hang = Verb(
        id: "hang",
        intents: .insert, .attack
    )

    /// Head in a particular direction.
    public static let head = Verb(
        id: "head",
        intents: .move
    )

    /// Request help or display help information.
    public static let help = Verb(
        id: "help",
        intents: .help, .meta
    )

    /// Hike or walk a long distance.
    public static let hike = Verb(
        id: "hike",
        intents: .move
    )

    /// Hit or strike something.
    public static let hit = Verb(
        id: "hit",
        pastParticiple: "hit",
        intents: .attack, .mung
    )

    /// Hoist or pull something up.
    public static let hoist = Verb(
        id: "hoist",
        intents: .pull
    )

    /// Holler or shout loudly (a form of vocal expression).
    public static let holler = Verb(
        id: "holler",
        intents: .tell
    )

    /// Hop or jump lightly.
    public static let hop = Verb(
        id: "hop",
        gerund: "hopping",
        pastParticiple: "hopped",
        intents: .jump
    )

    /// Hug something.
    public static let hug = Verb(
        id: "hug",
        gerund: "hugging",
        pastParticiple: "hugged",
        intents: .push
    )

    /// Hum a tune (a form of vocal expression).
    public static let hum = Verb(
        id: "hum",
        gerund: "humming",
        pastParticiple: "hummed",
        intents: .tell
    )

    /// Hurl or throw something forcefully.
    public static let hurl = Verb(
        id: "hurl",
        intents: .throw
    )

    /// Ignite or light a fire or light source.
    public static let ignite = Verb(
        id: "ignite",
        intents: .lightSource
    )

    /// Imbibe or drink something (formal term).
    public static let imbibe = Verb(
        id: "imbibe",
        intents: .drink
    )

    /// Inflate something by pushing air into it.
    public static let inflate = Verb(
        id: "inflate",
        intents: .push
    )

    /// Inform or tell someone something.
    public static let inform = Verb(
        id: "inform",
        intents: .tell
    )

    /// Inquire about something.
    public static let inquire = Verb(
        id: "inquire",
        intents: .ask
    )

    /// Insert something into a container or opening.
    public static let insert = Verb(
        id: "insert",
        intents: .insert
    )

    /// Inspect something carefully (synonym for "examine").
    public static let inspect = Verb(
        id: "inspect",
        intents: .examine
    )

    /// Display player's inventory.
    public static let inventory = Verb(
        id: "inventory",
        intents: .inventory, .meta
    )

    /// Jump or leap over/onto something.
    public static let jump = Verb(
        id: "jump",
        intents: .jump
    )

    /// Kick something as an attack.
    public static let kick = Verb(
        id: "kick",
        intents: .attack
    )

    /// Kill or attempt to destroy something.
    public static let kill = Verb(
        id: "kill",
        intents: .attack, .mung
    )

    /// Kiss something or someone (treated as touching).
    public static let kiss = Verb(
        id: "kiss",
        intents: .touch
    )

    /// Knock on something or knock it down.
    public static let knock = Verb(
        id: "knock",
        intents: .push, .attack
    )

    /// Laugh or express amusement (a form of vocal expression).
    public static let laugh = Verb(
        id: "laugh",
        intents: .tell
    )

    /// Leap or jump with force.
    public static let leap = Verb(
        id: "leap",
        pastParticiple: "leapt",
        intents: .jump
    )

    /// Lick something to taste or touch it.
    public static let lick = Verb(
        id: "lick",
        intents: .taste, .touch
    )

    /// Lift something up, either to take it or pull it.
    public static let lift = Verb(
        id: "lift",
        intents: .take, .pull
    )

    /// Light a fire or turn on a light source.
    public static let light = Verb(
        id: "light",
        pastParticiple: "lit",
        intents: .lightSource
    )

    /// Listen for sounds or pay attention to audio.
    public static let listen = Verb(
        id: "listen",
        intents: .listen
    )

    /// Load something into a container or device.
    public static let load = Verb(
        id: "load",
        intents: .insert
    )

    /// Locate or find something by searching.
    public static let locate = Verb(
        id: "locate",
        intents: .search
    )

    /// Lock something with a key or mechanism.
    public static let lock = Verb(
        id: "lock",
        intents: .lock
    )

    /// Look around or examine something visually.
    public static let look = Verb(
        id: "look",
        intents: .look, .examine
    )

    /// Abbreviation for "look" - look around or examine something visually.
    public static let l = Verb(  // swiftlint:disable:this identifier_name
        id: "l",
        intents: .look, .examine
    )

    /// Massage something with your hands (a form of touching).
    public static let massage = Verb(
        id: "massage",
        intents: .touch
    )

    /// Mount or climb onto something.
    public static let mount = Verb(
        id: "mount",
        intents: .climb
    )

    /// Move something by pushing it or taking it.
    public static let move = Verb(
        id: "move",
        intents: .move, .push, .take
    )

    /// Nibble or take small bites of something.
    public static let nibble = Verb(
        id: "nibble",
        intents: .eat
    )

    /// Respond negatively to a question.
    public static let no = Verb(
        id: "no",
        intents: .tell
    )

    /// Offer or present something to someone.
    public static let offer = Verb(
        id: "offer",
        intents: .give
    )

    /// Open something that can be opened/closed.
    public static let open = Verb(
        id: "open",
        intents: .open
    )

    /// Peek at or glance at something quickly.
    public static let peek = Verb(
        id: "peek",
        intents: .examine
    )

    /// Peer at or glance at something quickly.
    public static let peer = Verb(
        id: "peer",
        intents: .examine
    )

    /// Pick something up or pick through things to search.
    public static let pick = Verb(
        id: "pick",
        intents: .take, .search
    )

    /// Place something somewhere (insert into a location).
    public static let place = Verb(
        id: "place",
        intents: .insert
    )

    /// Polish something by rubbing it (treated as touching).
    public static let polish = Verb(
        id: "polish",
        intents: .touch
    )

    /// Ponder or think deeply about something.
    public static let ponder = Verb(
        id: "ponder",
        intents: .think
    )

    /// Pour liquid from one container to another.
    public static let pour = Verb(
        id: "pour",
        intents: .pour
    )

    /// Press down on something (a form of pushing).
    public static let press = Verb(
        id: "press",
        intents: .push
    )

    /// Proceed or continue moving forward.
    public static let proceed = Verb(
        id: "proceed",
        intents: .move
    )

    /// Prune or trim something by cutting.
    public static let prune = Verb(
        id: "prune",
        intents: .cut
    )

    /// Puff air at something to push it or extinguish it.
    public static let puff = Verb(
        id: "puff",
        intents: .push, .extinguish
    )

    /// Pull something toward you.
    public static let pull = Verb(
        id: "pull",
        intents: .pull
    )

    /// Push something away from you.
    public static let push = Verb(
        id: "push",
        intents: .push
    )

    /// Put something somewhere (insert into a location).
    public static let put = Verb(
        id: "put",
        gerund: "putting",
        pastParticiple: "put",
        intents: .insert
    )

    /// Quaff or drink something heartily.
    public static let quaff = Verb(
        id: "quaff",
        intents: .drink
    )

    /// Question someone or ask for information.
    public static let question = Verb(
        id: "question",
        intents: .ask
    )

    /// Quit or exit the game.
    public static let quit = Verb(
        id: "quit",
        intents: .quit, .meta
    )

    /// Raise something up by pulling or taking it.
    public static let raise = Verb(
        id: "raise",
        intents: .pull, .take
    )

    /// Rap or knock on something, either gently or as an attack.
    public static let rap = Verb(
        id: "rap",
        intents: .push, .attack
    )

    /// Rattle something by shaking or pushing it.
    public static let rattle = Verb(
        id: "rattle",
        intents: .push
    )

    /// Read text or written material.
    public static let read = Verb(
        id: "read",
        pastParticiple: "read",
        intents: .read
    )

    /// Remove or take something (often clothing or accessories if worn).
    public static let remove = Verb(
        id: "remove",
        intents: .remove, .take
    )

    /// Restart the game from the beginning.
    public static let restart = Verb(
        id: "restart",
        intents: .restart, .meta
    )

    /// Restore a saved game state.
    public static let restore = Verb(
        id: "restore",
        intents: .restore, .meta
    )

    /// Rip something.
    public static let rip = Verb(
        id: "rip",
        gerund: "ripping",
        intents: .mung
    )

    /// Rotate or turn something around.
    public static let rotate = Verb(
        id: "rotate",
        intents: .turn
    )

    /// Rub something with your hands (a form of touching).
    public static let rub = Verb(
        id: "rub",
        gerund: "rubbing",
        pastParticiple: "rubbed",
        intents: .touch
    )

    /// Ruin something.
    public static let ruin = Verb(
        id: "ruin",
        intents: .mung
    )

    /// Run or move quickly in a direction.
    public static let run = Verb(
        id: "run",
        gerund: "running",
        pastParticiple: "run",
        intents: .move
    )

    /// Save the current game state.
    public static let save = Verb(
        id: "save",
        intents: .save, .meta
    )

    /// Say to someone or speak aloud.
    public static let say = Verb(
        id: "say",
        pastParticiple: "said",
        intents: .tell
    )

    /// Scale or climb up something steep.
    public static let scale = Verb(
        id: "scale",
        intents: .climb
    )

    /// Display the current game score.
    public static let score = Verb(
        id: "score",
        intents: .help
    )

    /// Scream or shout loudly (a form of vocal expression).
    public static let scream = Verb(
        id: "scream",
        intents: .tell
    )

    /// Enable transcript recording of game session.
    public static let script = Verb(
        id: "script",
        intents: .help
    )

    /// Search for something or look through things carefully.
    public static let search = Verb(
        id: "search",
        intents: .search
    )

    /// Serenade another character (a form of vocal expression).
    public static let serenade = Verb(
        id: "serenade",
        intents: .tell
    )

    /// Set something down or set it to a particular state.
    public static let set = Verb(
        id: "set",
        gerund: "setting",
        pastParticiple: "set",
        intents: .insert, .push
    )

    /// Shake something vigorously (a form of pushing/moving).
    public static let shake = Verb(
        id: "shake",
        pastParticiple: "shaken",
        intents: .push
    )

    /// Shatter something.
    public static let shatter = Verb(
        id: "shatter",
        intents: .mung
    )

    /// Shift something by pushing or turning it.
    public static let shift = Verb(
        id: "shift",
        intents: .push, .turn
    )

    /// Express frustration or anger (a form of vocal expression).
    public static let shit = Verb(
        id: "shit",
        gerund: "shitting",
        pastParticiple: "shat",
        intents: .tell
    )

    /// Shout or yell loudly (a form of vocal expression).
    public static let shout = Verb(
        id: "shout",
        intents: .tell
    )

    /// Shove something forcefully (a form of pushing).
    public static let shove = Verb(
        id: "shove",
        intents: .push
    )

    /// Shriek or scream with a high pitch (a form of vocal expression).
    public static let shriek = Verb(
        id: "shriek",
        intents: .tell
    )

    /// Shut or close something (synonym for "close").
    public static let shut = Verb(
        id: "shut",
        gerund: "shutting",
        pastParticiple: "shut",
        intents: .close
    )

    /// Sing a song (a form of vocal expression).
    public static let sing = Verb(
        id: "sing",
        pastParticiple: "sung",
        intents: .tell
    )

    /// Sip or drink something slowly in small amounts.
    public static let sip = Verb(
        id: "sip",
        gerund: "sipping",
        pastParticiple: "sipped",
        intents: .drink
    )

    /// Sit down on something.
    public static let sit = Verb(
        id: "sit",
        gerund: "sitting",
        pastParticiple: "sat",
        intents: .sit
    )

    /// Slay or kill something (a form of attack).
    public static let slay = Verb(
        id: "slay",
        intents: .attack, .mung
    )

    /// Slice something with a blade, either to cut it or attack it.
    public static let slice = Verb(
        id: "slice",
        intents: .cut, .attack
    )

    /// Slide something along a surface (a form of pushing).
    public static let slide = Verb(
        id: "slide",
        intents: .push
    )

    /// Smash something.
    public static let smash = Verb(
        id: "smash",
        intents: .mung
    )

    /// Smell something to detect its odor.
    public static let smell = Verb(
        id: "smell",
        intents: .smell
    )

    /// Snicker or laugh quietly (a form of vocal expression).
    public static let snicker = Verb(
        id: "snicker",
        intents: .tell
    )

    /// Sniff something to smell it more carefully.
    public static let sniff = Verb(
        id: "sniff",
        intents: .smell
    )

    /// Sob or cry audibly (a form of vocal expression).
    public static let sob = Verb(
        id: "sob",
        gerund: "sobbing",
        pastParticiple: "sobbed",
        intents: .tell
    )

    /// Speak to someone or say aloud.
    public static let speak = Verb(
        id: "speak",
        intents: .tell
    )

    /// Spill something by emptying it accidentally or dropping it.
    public static let spill = Verb(
        id: "spill",
        intents: .empty, .drop
    )

    /// Squeeze something by applying pressure (a form of pushing).
    public static let squeeze = Verb(
        id: "squeeze",
        intents: .push
    )

    /// Stab something with a sharp object, either to attack or cut it.
    public static let stab = Verb(
        id: "stab",
        gerund: "stabbing",
        pastParticiple: "stabbed",
        intents: .attack, .cut, .mung
    )

    /// Steal or take something without permission.
    public static let steal = Verb(
        id: "steal",
        pastParticiple: "stolen",
        intents: .take
    )

    /// Stroll or walk leisurely in a direction.
    public static let stroll = Verb(
        id: "stroll",
        intents: .move
    )

    /// Swear or use profanity (a form of vocal expression).
    public static let swear = Verb(
        id: "swear",
        pastParticiple: "sworn",
        intents: .tell
    )

    /// Switch something on/off or push/press it.
    public static let `switch` = Verb(
        id: "switch",
        intents: .turn, .push
    )

    /// Take or pick up something to add it to inventory.
    public static let take = Verb(
        id: "take",
        pastParticiple: "taken",
        intents: .take
    )

    /// Talk to someone or speak aloud.
    public static let talk = Verb(
        id: "talk",
        intents: .tell
    )

    /// Tap something lightly, either to push it or touch it.
    public static let tap = Verb(
        id: "tap",
        gerund: "tapping",
        pastParticiple: "tapped",
        intents: .push, .touch
    )

    /// Taste something to sample its flavor.
    public static let taste = Verb(
        id: "taste",
        intents: .taste
    )

    /// Tear something.
    public static let tear = Verb(
        id: "tear",
        pastParticiple: "torn",
        intents: .mung
    )

    /// Tell something to someone or speak aloud.
    public static let tell = Verb(
        id: "tell",
        pastParticiple: "told",
        intents: .tell
    )

    /// Think about something or contemplate.
    public static let think = Verb(
        id: "think",
        pastParticiple: "thought",
        intents: .think
    )

    /// Throw an object or give it to someone/something.
    public static let `throw` = Verb(
        id: "throw",
        pastParticiple: "thrown",
        intents: .throw, .give
    )

    /// Tie something together or fasten with rope/string.
    public static let tie = Verb(
        id: "tie",
        gerund: "tying",
        pastParticiple: "tied",
        intents: .tie
    )

    /// Toss or throw something lightly.
    public static let toss = Verb(
        id: "toss",
        intents: .throw
    )

    /// Touch something with your hands.
    public static let touch = Verb(
        id: "touch",
        intents: .touch
    )

    /// Travel or journey in a direction.
    public static let travel = Verb(
        id: "travel",
        intents: .move
    )

    /// Turn something around or turn on/off a light source.
    public static let turn = Verb(
        id: "turn",
        intents: .turn, .lightSource
    )

    /// Twist something by rotating it.
    public static let twist = Verb(
        id: "twist",
        intents: .turn
    )

    /// Unlock something with a key or mechanism.
    public static let unlock = Verb(
        id: "unlock",
        intents: .unlock
    )

    /// Disable transcript recording (opposite of script).
    public static let unscript = Verb(
        id: "unscript",
        intents: .help
    )

    /// Switch to verbose mode (detailed room descriptions).
    public static let verbose = Verb(
        id: "verbose",
        intents: .help
    )

    /// Wait or pause for a turn without taking action.
    public static let wait = Verb(
        id: "wait",
        intents: .wait, .meta
    )

    /// Walk in a particular direction.
    public static let walk = Verb(
        id: "walk",
        intents: .move
    )

    /// Wave something as a weapon or gesture, or wave as greeting.
    public static let wave = Verb(
        id: "wave",
        intents: .attack, .tell
    )

    /// Wear clothing or accessories.
    public static let wear = Verb(
        id: "wear",
        pastParticiple: "worn",
        intents: .wear
    )

    /// Weep or cry (a form of vocal expression).
    public static let weep = Verb(
        id: "weep",
        pastParticiple: "wept",
        intents: .tell
    )

    /// Abbreviation for "examine" - examine something closely for details..
    public static let x = Verb(  // swiftlint:disable:this identifier_name
        id: "x",
        intents: .examine
    )

    /// The classic adventure game magic word (treated as vocal expression).
    public static let xyzzy = Verb(
        id: "xyzzy",
        intents: .tell
    )

    /// Yell or shout loudly (a form of vocal expression).
    public static let yell = Verb(
        id: "yell",
        intents: .tell
    )

    /// Respond affirmatively to a question.
    public static let yes = Verb(
        id: "yes",
        intents: .tell
    )
}

// MARK: - Conformances

extension Verb: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}

// swiftlint:enable file_length
