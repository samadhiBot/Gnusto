import Foundation
import Logging

/// The main orchestrator for an interactive fiction game, responsible for managing
/// the game's state, running the primary game loop, and coordinating interactions
/// between the player (via an `IOHandler`), the command `Parser`, and the various
/// game logic handlers (`ActionHandler`, `ItemEventHandler`, `LocationEventHandler`).
///
/// As a Swift `actor`, `GameEngine` ensures thread-safe access to the mutable `gameState`
/// from concurrent contexts, which is crucial for modern Swift concurrency.
///
/// Game developers typically interact with the `GameEngine` instance provided
/// within custom game logic closures (like those in `GameBlueprint` or event handlers)
/// or within `ActionHandler` implementations. Through this instance, developers can:
/// - Query the current `GameState` (e.g., find items, check locations) using the
///   various accessor methods and properties available in `GameEngine` extensions
///   (e.g., `GameEngine+stateQuery.swift`, `GameEngine+playerQuery.swift`).
/// - Initiate changes to the `GameState` by creating `StateChange` objects (often via
///   factory methods in `GameEngine+changes.swift`) and then applying them,
///   or by using higher-level convenience mutation methods (e.g., in
///   `GameEngine+stateMutation.swift`).
/// - Trigger output to the player (usually by returning an `ActionResult` with a message).
public actor GameEngine {
    /// The full title of the game (e.g., "ZORK I: The Great Underground Empire").
    /// This is typically displayed when the game starts.
    nonisolated var title: String { gameBlueprint.title }

    /// A shortened version of the title for use in file names and system identifiers.
    nonisolated var abbreviatedTitle: String { gameBlueprint.abbreviatedTitle }

    /// An introductory text, often including a brief premise, version information, or byline.
    /// This is displayed after the `title` when the game starts.
    nonisolated var introduction: String { gameBlueprint.introduction }

    /// A version or release identifier for the game (e.g., "Release 1 / Serial number 880720").
    /// This can be part of the `introduction` or used separately as needed.
    nonisolated var release: String { gameBlueprint.release }

    /// The maximum achievable score in the game. This is used by score-reporting actions
    /// and can be used by the game to determine if the player has "won".
    nonisolated var maximumScore: Int { gameBlueprint.maximumScore }

    /// The current, mutable state of the entire game world.
    ///
    /// This `GameState` object holds all information about locations, items, the player,
    /// active timers (fuses and daemons), pronouns, and global variables. While action
    /// handlers and game hooks can read from this state (often via engine helper methods),
    /// all modifications **must** be done by applying `StateChange` objects through the
    /// engine (e.g., `gameState.apply(someChange)`) to ensure consistency, proper
    /// validation (if registered), and tracking of changes in `gameState.changeHistory`.
    public internal(set) var gameState: GameState

    /// The parser responsible for interpreting raw player input strings into
    /// structured `Command` objects that the engine can understand and execute.
    /// This is primarily used internally by the engine during the game loop.
    public let parser: Parser

    /// The handler for all input and output operations, such as reading player commands
    /// and displaying game text. Game developers usually do not interact with this
    /// directly from handlers, as the engine provides higher-level mechanisms for output
    /// (e.g., the `message` property of an `ActionResult`, or by throwing an
    /// `ActionResponse` which the engine translates to a player-facing message).
    public internal(set) var ioHandler: IOHandler

    /// The conversation manager for handling multi-turn conversations and questions.
    /// Provides a clean API for action handlers to ask questions and process responses.
    public lazy var conversationManager = ConversationManager()

    /// The messenger for localized and customizable game text.
    /// Derived from the `GameBlueprint` used to initialize the engine.
    public let messenger: StandardMessenger

    /// The game's vocabulary, containing all recognized words (verbs, nouns, adjectives, etc.)
    /// and syntax rules. This is built once during engine initialization from the game blueprint.
    public let vocabulary: Vocabulary

    /// A random number generator used throughout the game for various randomization needs.
    ///
    /// This generator is used for determining random events, NPC behaviors, game mechanics,
    /// and other probabilistic elements. The default implementation uses the system's
    /// random number generator.
    ///
    /// For testing purposes, you can provide a custom implementation that returns
    /// predetermined values to ensure consistent test results.
    public var randomNumberGenerator: any RandomNumberGenerator

    /// Handles filesystem operations for save files, transcripts, and other game data.
    ///
    /// This allows for dependency injection of filesystem behavior, enabling easy testing
    /// with mock implementations that don't touch the actual filesystem.
    public let filesystemHandler: FilesystemHandler

    /// Definitions for timed events (fuses) that trigger after a set number of turns.
    /// These are derived from the `GameBlueprint` used to initialize the engine.
    public let fuses: [FuseID: Fuse]

    /// Definitions for background processes (daemons) that run periodically.
    /// These are derived from the `GameBlueprint` used to initialize the engine.
    public nonisolated var daemons: [DaemonID: Daemon] { gameBlueprint.daemons }

    /// Storage for item compute handlers.
    /// These are initialized from the `GameBlueprint`.
    var itemComputers: [ItemID: ItemComputer]

    /// Storage for location compute handlers.
    /// These are initialized from the `GameBlueprint`.
    var locationComputers: [LocationID: LocationComputer]

    /// Registered `ActionHandler`s for processing commands.
    /// These are a combination of default engine handlers and custom handlers provided
    /// by the `GameBlueprint`, with custom handlers taking precedence.
    var actionHandlers: [ActionHandler] {
        let combined = gameBlueprint.customActionHandlers + Self.defaultActionHandlers
        #if DEBUG
            return combined + [DebugActionHandler()]
        #else
            return combined
        #endif
    }

    /// Custom event handlers for specific items, triggered by events like `beforeTurn`
    /// or `afterTurn`. These are provided by the `GameBlueprint` and are processed by the
    /// engine during the `execute(command:)` phase.
    nonisolated var itemEventHandlers: [ItemID: ItemEventHandler] {
        gameBlueprint.itemEventHandlers
    }

    /// Custom event handlers for specific locations, triggered by events like `onEnter`,
    /// `beforeTurn`, or `afterTurn`. These are provided by the `GameBlueprint` and are processed
    /// by the engine, for example, during `applyPlayerMove(to:)` or `execute(command:)`.
    nonisolated var locationEventHandlers: [LocationID: LocationEventHandler] {
        gameBlueprint.locationEventHandlers
    }

    /// Combat systems for specific characters, providing custom combat behavior.
    /// These are provided by the `GameBlueprint` and are used by the `AttackActionHandler`
    /// to handle combat encounters with different character types.
    nonisolated var combatSystems: [ItemID: any CombatSystem] {
        gameBlueprint.combatSystems
    }

    /// Combat messengers for specific characters, providing custom combat messaging.
    /// These are provided by the `GameBlueprint` and are used by combat systems
    /// to generate narrative descriptions for combat events.
    nonisolated var combatMessengers: [ItemID: CombatMessenger] {
        gameBlueprint.combatMessengers
    }

    /// The default combat messenger used when no character-specific messenger is configured.
    nonisolated var defaultCombatMessenger: CombatMessenger {
        gameBlueprint.defaultCombatMessenger
    }

    /// Stores the last command that encountered disambiguation for retry with clarification
    var lastDisambiguationContext: LastDisambiguationContext?

    /// Stores the last disambiguation options for matching against user responses
    var lastDisambiguationOptions: [String]?

    /// Internal logger for engine messages, warnings, and errors.
    let logger = Logger(label: "com.samadhibot.Gnusto.GameEngine")

    /// Internal flag to control the main game loop's continuation.
    /// Game developers can call `requestQuit()` to set this flag to `true`,
    /// causing the game to end after the current turn completes.
    var shouldQuit: Bool = false

    /// Internal flag to control game restart.
    /// Game developers can call `requestRestart()` to set this flag to `true`,
    /// causing the game to restart after the current turn completes.
    var shouldRestart: Bool = false

    /// Blueprint data for game restart and computed properties
    let gameBlueprint: GameBlueprint

    // MARK: - Initialization

    /// Creates a new `GameEngine` instance, configured by a `GameBlueprint` and ready to run a game.
    ///
    /// This is typically called once at the start of the game application to set up the engine
    /// with all game-specific data (initial state, constants, definitions) and logic (custom handlers, hooks).
    ///
    /// - Parameters:
    ///   - blueprint: The `GameBlueprint` containing all game definitions, custom handlers, and hooks.
    ///   - parser: The `Parser` instance to be used for understanding player input.
    ///   - ioHandler: The `IOHandler` instance for interacting with the player (text input/output).
    ///   - filesystemHandler: The `FilesystemHandler` for save files and transcripts (defaults to production handler).
    public init(
        blueprint: GameBlueprint,
        parser: Parser = StandardParser(),
        ioHandler: IOHandler,
        filesystemHandler: FilesystemHandler = StandardFilesystemHandler()
    ) async {
        // Store blueprint and basic configuration
        self.gameBlueprint = blueprint
        self.randomNumberGenerator = blueprint.randomNumberGenerator
        self.parser = parser
        self.ioHandler = ioHandler
        self.filesystemHandler = filesystemHandler

        // Add blueprint fuse definitions to standard fuses
        self.fuses = gameBlueprint.fuses.merging([
            .enemyWakeUp: .enemyWakeUp,
            .enemyReturn: .enemyReturn,
            .statusEffectExpiry: .statusEffectExpiry,
        ]) { blueprint, _ in blueprint }

        // Initialize the compute handlers directly from the blueprint
        self.itemComputers = blueprint.itemComputers
        self.locationComputers = blueprint.locationComputers

        // Build initial game state and vocabulary using shared method
        let (initialGameState, initialVocabulary) = await Self.buildInitialGameState(
            from: blueprint
        )
        self.gameState = initialGameState
        self.messenger = gameBlueprint.messenger
        self.vocabulary = initialVocabulary
    }
}

// MARK: - LastDisambiguationContext

extension GameEngine {
    struct LastDisambiguationContext {
        let originalInput: String
        let verb: Verb
        let noun: String
    }
}
