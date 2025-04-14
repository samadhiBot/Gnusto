import Foundation

/// Context passed to a command handler, containing the input and world state.
public struct CommandContext {
    /// The user input that triggered the command.
    /// Note: If the handler was triggered by a phrase with a preposition (e.g., "turn on"),
    /// the matched preposition will *not* be present in this `userInput`'s `prepositions` array.
    public let userInput: UserInput
    /// The current game world state.
    public let world: World
    /// The canonical `VerbID` associated with the matched `VerbPhrase` in the registry.
    public let canonicalVerbID: VerbID
}

/// A typealias for the function signature used by command handlers.
///
/// Command handlers receive the parsed user input context and the current
/// world state (`World`), and return an optional array of `Effect`s to be presented,
/// or nil if the command cannot be handled in the current context.
public typealias CommandHandler = (CommandContext) -> [Effect]?

/// Manages the registration and lookup of command handlers based on verb phrases (verb + optional preposition).
///
/// This registry maps input phrases (like "turn on" or just "look") to the appropriate handler function.
/// It supports registering default engine handlers and allows games to override them.
public class CommandRegistry {
    // Stores the handler function associated with each VerbPhrase.
    // The VerbID is stored alongside for potential future use (e.g., help commands, introspection).
    internal struct HandlerEntry {
        let canonicalVerbID: VerbID
        let handler: CommandHandler
        /// Whether this command can be performed when the player's location is dark.
        let worksInDarkness: Bool
    }

    /// Stores game-specific command handlers, keyed by `VerbPhrase`.
    private var gameHandlers: [VerbPhrase: HandlerEntry] = [:]

    /// Stores default engine command handlers, keyed by `VerbPhrase`.
    private var defaultHandlers: [VerbPhrase: HandlerEntry] = [:]

    /// Initializes a new, empty command registry.
    public init() {}

    /// Registers a command handler for a specific canonical verb ID and a set of trigger phrases.
    ///
    /// Each phrase consists of a verb string and an optional preposition string. If a phrase
    /// includes a preposition, that preposition must be present in the user input (and will be
    /// consumed) for the handler to be invoked via that phrase.
    ///
    /// - Parameters:
    ///   - canonicalVerbID: The canonical `VerbID` representing the core action (e.g., `.turnOn`).
    ///   - phrases: An array of `VerbPhrase` objects that trigger this handler.
    ///   - handler: The closure or function conforming to `CommandHandler`.
    ///   - worksInDarkness: Whether this command can be performed in the dark.
    public func register(
        canonicalVerbID: VerbID,
        phrases: [VerbPhrase],
        handler: @escaping CommandHandler,
        worksInDarkness: Bool = false
    ) {
        register(
            canonicalVerbID: canonicalVerbID,
            phrases: phrases,
            handler: handler,
            isDefault: false,
            worksInDarkness: worksInDarkness
        )
    }

    /// Registers a command handler using variadic lists of verb and preposition synonyms.
    ///
    /// This simplifies registering multiple synonyms for the same handler. If the `prepositions`
    /// list is empty, only verb phrases without prepositions are registered.
    ///
    /// - Parameters:
    ///   - canonicalVerbID: The canonical `VerbID` representing the core action (e.g., `.turnOn`).
    ///   - verbs: An array of verb strings that trigger this handler.
    ///   - prepositions: An array of preposition strings that trigger this handler.
    ///   - handler: The closure or function conforming to `CommandHandler`.
    ///   - isDefault: If `true`, registers this as a default engine handler. If `false` (default),
    ///     registers it as a game-specific handler which overrides any default for the same `VerbPhrase`.
    ///   - worksInDarkness: Whether this command can be performed in the dark.
    public func register(
        canonicalVerbID: VerbID,
        verbs: String...,
        prepositions: String...,
        handler: @escaping CommandHandler,
        isDefault: Bool = false,
        worksInDarkness: Bool = false
    ) {
        var phrases: [VerbPhrase] = []
        let validVerbs = verbs.filter { !$0.isEmpty }
        let validPrepositions = prepositions.filter { !$0.isEmpty }

        assert(
            !validVerbs.isEmpty,
            "Cannot register a handler for `\(canonicalVerbID)` with no valid verbs specified."
        )

        if validPrepositions.isEmpty {
            // Register verb-only phrases
            for verb in validVerbs {
                phrases.append(VerbPhrase(verb: verb))
            }
        } else {
            // Register verb + preposition combinations
            for verb in validVerbs {
                for prep in validPrepositions {
                    phrases.append(VerbPhrase(verb: verb, preposition: prep))
                }
            }
        }

        // Call the original register function with the generated phrases
        register(
            canonicalVerbID: canonicalVerbID,
            phrases: phrases,
            handler: handler,
            isDefault: isDefault,
            worksInDarkness: worksInDarkness
        )
    }


    /// Registers a command handler for a specific canonical verb ID and a set of trigger phrases.
    ///
    /// Each phrase consists of a verb string and an optional preposition string.
    /// If a phrase includes a preposition, that preposition must be present in the user input
    /// (and will be consumed) for the handler to be invoked via that phrase.
    ///
    /// - Parameters:
    ///   - canonicalVerbID: The canonical `VerbID` representing the core action (e.g., `.turnOn`).
    ///   - phrases: An array of `VerbPhrase` objects that trigger this handler.
    ///   - handler: The closure or function conforming to `CommandHandler` to execute.
    ///   - isDefault: If `true`, registers this as a default engine handler. If `false` (default),
    ///     registers it as a game-specific handler which overrides any default for the same `VerbPhrase`.
    ///   - worksInDarkness: Whether this command can be performed when the player's location is dark.
    func register(
        canonicalVerbID: VerbID,
        phrases: [VerbPhrase],
        handler: @escaping CommandHandler,
        isDefault: Bool = true,
        worksInDarkness: Bool = false
    ) {
        let entry = HandlerEntry(
            canonicalVerbID: canonicalVerbID,
            handler: handler,
            worksInDarkness: worksInDarkness
        )

        for phrase in phrases {
            // Ensure the verb component of the phrase is not empty
            assert(
                !phrase.verb.isEmpty,
                "Cannot register a handler for an empty verb string: \(phrase)"
            )

            if isDefault {
                if let existingEntry = defaultHandlers[phrase] {
                    print("⚠️ Warning: Default handler for phrase '\(phrase)' already registered (Canonical: \(existingEntry.canonicalVerbID)). Overwriting with handler for '\(canonicalVerbID)'.")
                }
                defaultHandlers[phrase] = entry
            } else {
                if let existingEntry = gameHandlers[phrase] {
                    print("⚠️ Warning: Game handler for phrase '\(phrase)' already registered (Canonical: \(existingEntry.canonicalVerbID)). Overwriting with handler for '\(canonicalVerbID)'.")
                }
                gameHandlers[phrase] = entry
            }
        }
    }


    /// Retrieves the appropriate command handler entry for a given verb phrase.
    ///
    /// Prioritizes game-specific handlers over defaults.
    ///
    /// - Parameter phrase: The `VerbPhrase` derived from the user input.
    /// - Returns: The `HandlerEntry` containing the canonical ID and handler closure if found, otherwise `nil`.
    internal func handlerEntry(for phrase: VerbPhrase) -> HandlerEntry? {
        // Prioritize game-specific handlers
        if let gameEntry = gameHandlers[phrase] {
            return gameEntry
        }
        // Fallback to default handlers
        return defaultHandlers[phrase]
    }

    /// Registers all default engine command handlers using the phrase-based system.
    public func registerDefaultHandlers() {
        // Register LookHandler
        register(
            canonicalVerbID: .look,
            verbs: "look", "l",
            handler: LookHandler.handle,
            isDefault: true,
            worksInDarkness: true
        )

        // Register GoHandler
        register(
            canonicalVerbID: .go,
            verbs: "north", "n", "south", "s", "east", "e", "west", "w",
                   "northeast", "ne", "northwest", "nw", "southeast", "se", "southwest", "sw",
                   "up", "u", "down", "d", "in", "out",
                   // These require a direction object, handled by GoHandler logic:
                   "go", "walk", "run", "proceed",
            handler: GoHandler.handle,
            isDefault: true,
            worksInDarkness: true
        )

        // Register PutInHandler (into container)
        register(
            canonicalVerbID: .put, // Use .put for both PutIn and PutOn
            verbs: "put", "insert", "place",
            prepositions: "in", "into",
            handler: PutInHandler.handle,
            isDefault: true
        )

        // Register PutOnHandler (onto surface)
        register(
            canonicalVerbID: .put, // Use .put for both PutIn and PutOn
            verbs: "put", "place", "set",
            prepositions: "on", "onto",
            handler: PutOnHandler.handle,
            isDefault: true
        )

        // Register QuitHandler
        register(
            canonicalVerbID: .quit,
            verbs: "quit", "exit", "q",
            handler: QuitHandler.handle,
            isDefault: true,
            worksInDarkness: true
        )

        // Register SaveHandler
        register(
            canonicalVerbID: .save,
            verbs: "save",
            handler: SaveHandler.handle,
            isDefault: true,
            worksInDarkness: true
        )

        // Register RestoreHandler
        register(
            canonicalVerbID: .restore,
            verbs: "restore", "load",
            handler: RestoreHandler.handle,
            isDefault: true,
            worksInDarkness: true
        )

        // Register HelpHandler
        register(
            canonicalVerbID: .help,
            verbs: "help", "?", "h",
            handler: HelpHandler.handle,
            isDefault: true,
            worksInDarkness: true
        )

        // Register UndoHandler
        register(
            canonicalVerbID: .undo,
            verbs: "undo",
            handler: UndoHandler.handle,
            isDefault: true,
            worksInDarkness: true
        )

        // Register WaitHandler
        register(
            canonicalVerbID: .wait,
            verbs: "wait", "z",
            handler: WaitHandler.handle,
            isDefault: true,
            worksInDarkness: true
        )

        // Register VersionHandler
        register(
            canonicalVerbID: .version,
            verbs: "version",
            handler: VersionHandler.handle,
            isDefault: true,
            worksInDarkness: true
        )

        // Register InventoryHandler
        register(
            canonicalVerbID: .inventory,
            verbs: "inventory", "i",
            handler: InventoryHandler.handle,
            isDefault: true,
            worksInDarkness: true
        )

        // Register DropHandler
        register(
            canonicalVerbID: .drop,
            verbs: "drop", "discard",
            handler: DropHandler.handle,
            isDefault: true
        )
        // Register "put down" separately as it has a preposition
        register(
            canonicalVerbID: .drop, // Map "put down" to the drop action
            verbs: "put",
            prepositions: "down",
            handler: DropHandler.handle,
            isDefault: true
        )

        // Register TakeHandler
        register(
            canonicalVerbID: .take,
            verbs: "take", "get", "grab",
            handler: TakeHandler.handle,
            isDefault: true
        )
        // Register "pick up" separately
        register(
            canonicalVerbID: .take,
            verbs: "pick",
            prepositions: "up",
            handler: TakeHandler.handle,
            isDefault: true
        )

        // Register WearHandler
        register(
            canonicalVerbID: .wear,
            verbs: "wear", "don",
            handler: WearHandler.handle,
            isDefault: true
        )
        // Note: "put on <clothing>" is handled by PutOnHandler, which needs
        // logic to differentiate wearing vs placing on surface.
        // OR, we could register "put on" directly to WearHandler if it ONLY means wear.
        // Let's assume PutOnHandler handles it for now.

        // Register TakeOffHandler
        register(
            canonicalVerbID: .takeOff,
            verbs: "remove", "doff", // Single word verbs
            handler: TakeOffHandler.handle,
            isDefault: true
        )
        register(
            canonicalVerbID: .takeOff,
            verbs: "take", // Multi-word verb "take off"
            prepositions: "off",
            handler: TakeOffHandler.handle,
            isDefault: true
        )

        // Register TurnOnHandler
        register(
            canonicalVerbID: .turnOn,
            verbs: "turn", "switch",
            prepositions: "on",
            handler: TurnOnHandler.handle,
            isDefault: true,
            worksInDarkness: true // Can try to turn something on in the dark
        )
        register(
            canonicalVerbID: .turnOn,
            verbs: "light", // e.g., "light lamp"
            handler: TurnOnHandler.handle,
            isDefault: true,
            worksInDarkness: true // Can try to turn something on in the dark
        )

        // Register TurnOffHandler
        register(
            canonicalVerbID: .turnOff,
            verbs: "turn", "switch",
            prepositions: "off",
            handler: TurnOffHandler.handle,
            isDefault: true
            // worksInDarkness: false (Default - usually need light to turn things off? debatable)
        )
        register(
            canonicalVerbID: .turnOff,
            verbs: "extinguish", "douse", // e.g., "extinguish torch"
            handler: TurnOffHandler.handle,
            isDefault: true
            // worksInDarkness: false (Default)
        )

        // Register ExamineHandler
        register(
            canonicalVerbID: .examine,
            verbs: "examine", "x", "look", // "look at" might be handled here or via specific phrase
            prepositions: "at", // Example preposition for examine
            handler: ExamineHandler.handle,
            isDefault: true,
            worksInDarkness: true
        )

        // Register AttackHandler
        register(
            canonicalVerbID: .attack,
            verbs: "attack", "hit", "fight", "kill",
            handler: AttackHandler.handle,
            isDefault: true
        )

        // Register OpenHandler
        register(
            canonicalVerbID: .open,
            verbs: "open",
            handler: OpenHandler.handle,
            isDefault: true
        )

        // Register CloseHandler
        register(
            canonicalVerbID: .close,
            verbs: "close", "shut",
            handler: CloseHandler.handle,
            isDefault: true
        )

        // Register LockHandler
        register(
            canonicalVerbID: .lock,
            verbs: "lock",
            prepositions: "with", // Assuming lock requires key via preposition
            handler: LockHandler.handle,
            isDefault: true
        )

        // Register UnlockHandler
        register(
            canonicalVerbID: .unlock,
            verbs: "unlock",
            prepositions: "with", // Assuming unlock requires key via preposition
            handler: UnlockHandler.handle,
            isDefault: true
        )
    }
}
