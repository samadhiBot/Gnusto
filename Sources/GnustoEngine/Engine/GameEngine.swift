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
public actor GameEngine: Sendable {
    /// The full title of the game (e.g., "ZORK I: The Great Underground Empire").
    /// This is typically displayed when the game starts.
    let storyTitle: String

    /// An introductory text, often including a brief premise, version information, or byline.
    /// This is displayed after the `storyTitle` when the game starts.
    let introduction: String

    /// A version or release identifier for the game (e.g., "Release 1 / Serial number 880720").
    /// This can be part of the `introduction` or used separately as needed.
    let release: String

    /// The maximum achievable score in the game. This is used by score-reporting actions
    /// and can be used by the game to determine if the player has "won".
    let maximumScore: Int

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
    let parser: Parser

    /// The handler for all input and output operations, such as reading player commands
    /// and displaying game text. Game developers usually do not interact with this
    /// directly from handlers, as the engine provides higher-level mechanisms for output
    /// (e.g., the `message` property of an `ActionResult`, or by throwing an
    /// `ActionResponse` which the engine translates to a player-facing message).
    nonisolated let ioHandler: IOHandler

    /// A utility to determine what items and locations are currently perceivable or
    /// interactable by the player, considering factors like light, containment, and reach.
    /// This is used internally by various engine methods (e.g., `playerCanReach(_:)`)
    /// to resolve scope.
    lazy var scopeResolver = ScopeResolver(engine: self)

    /// The message provider for localized and customizable game text.
    /// Derived from the `GameBlueprint` used to initialize the engine.
    public nonisolated let messageProvider: MessageProvider

    /// A random number generator used throughout the game for various randomization needs.
    ///
    /// This generator is used for determining random events, NPC behaviors, game mechanics,
    /// and other probabilistic elements. The default implementation uses the system's
    /// random number generator.
    ///
    /// For testing purposes, you can provide a custom implementation that returns
    /// predetermined values to ensure consistent test results.
    public var randomNumberGenerator: any RandomNumberGenerator

    /// Definitions for timed events (fuses) that trigger after a set number of turns.
    /// These are derived from the `GameBlueprint` used to initialize the engine.
    public let fuses: [FuseID: Fuse]

    /// Definitions for background processes (daemons) that run periodically.
    /// These are derived from the `GameBlueprint` used to initialize the engine.
    public let daemons: [DaemonID: Daemon]

    /// Storage for item compute handlers.
    /// These are initialized from the `GameBlueprint`.
    var itemComputers: [ItemID: ItemComputer]

    /// Storage for location compute handlers.
    /// These are initialized from the `GameBlueprint`.
    var locationComputers: [LocationID: LocationComputer]

    /// Registered `ActionHandler`s for processing commands.
    /// These are a combination of default engine handlers and custom handlers provided
    /// by the `GameBlueprint`, with custom handlers taking precedence.
    private var actionHandlers: [ActionHandler]

    /// Custom event handlers for specific items, triggered by events like `beforeTurn`
    /// or `afterTurn`. These are provided by the `GameBlueprint` and are processed by the
    /// engine during the `execute(command:)` phase.
    var itemEventHandlers: [ItemID: ItemEventHandler]

    /// Custom event handlers for specific locations, triggered by events like `onEnter`,
    /// `beforeTurn`, or `afterTurn`. These are provided by the `GameBlueprint` and are processed
    /// by the engine, for example, during `applyPlayerMove(to:)` or `execute(command:)`.
    var locationEventHandlers: [LocationID: LocationEventHandler]

    /// Internal logger for engine messages, warnings, and errors.
    let logger = Logger(label: "com.samadhibot.Gnusto.GameEngine")

    /// Internal flag to control the main game loop's continuation.
    /// Game developers can call `requestQuit()` to set this flag to `true`,
    /// causing the game to end after the current turn completes.
    var shouldQuit: Bool = false

    // MARK: - Initialization

    /// Creates a new `GameEngine` instance, configured by a `GameBlueprint` and ready to run a game.
    ///
    /// This is typically called once at the start of the game application to set up the engine
    /// with all game-specific data (initial state, constants, definitions) and logic (custom handlers, hooks).
    ///
    /// - Parameters:
    ///   - blueprint: The `GameBlueprint` containing all game definitions, custom handlers, and hooks.
    ///   - vocabulary: Optional. The `Vocabulary` for the game. If `nil`, it's auto-generated from items.
    ///   - pronouns: Optional. Initial pronoun references.
    ///   - activeFuses: Optional. Initially active fuses and their remaining turns.
    ///   - activeDaemons: Optional. Initially active daemons.
    ///   - globalState: Optional. Initial game-specific global key-value data.
    ///   - parser: The `Parser` instance to be used for understanding player input.
    ///   - ioHandler: The `IOHandler` instance for interacting with the player (text input/output).
    public init(
        blueprint: GameBlueprint,
        vocabulary: Vocabulary? = nil,
        pronouns: [String: Set<EntityReference>] = [:],
        activeFuses: [FuseID: Int] = [:],
        activeDaemons: Set<DaemonID> = [],
        globalState: [GlobalID: StateValue] = [:],
        parser: Parser,
        ioHandler: IOHandler,
        randomNumberGenerator: any RandomNumberGenerator = SystemRandomNumberGenerator()
    ) async {
        self.daemons = blueprint.daemons
        self.fuses = blueprint.fuses
        self.introduction = blueprint.introduction
        self.maximumScore = blueprint.maximumScore
        self.messageProvider = blueprint.messageProvider
        self.randomNumberGenerator = randomNumberGenerator
        self.release = blueprint.release
        self.storyTitle = blueprint.storyTitle

        // Build action handlers and vocabulary from blueprint
        let allActionHandlers: [ActionHandler]
        let gameVocabulary: Vocabulary

        if let providedVocabulary = vocabulary {
            // If vocabulary is provided, use it and build handlers separately
            gameVocabulary = providedVocabulary
            allActionHandlers = blueprint.customActionHandlers
        } else {
            // Extract both verb definitions and handlers from ActionHandler instances
            let customHandlers = blueprint.customActionHandlers

            // Combine custom and default action handlers to extract all verb definitions
            let allHandlers = blueprint.customActionHandlers + Self.defaultActionHandlers
            let allVerbs = Self.extractVerbDefinitions(from: allHandlers)

            allActionHandlers = customHandlers
            gameVocabulary = Vocabulary.build(
                items: blueprint.items,
                locations: blueprint.locations,
                verbs: allVerbs
            )
        }

        self.gameState = GameState(
            locations: blueprint.locations,
            items: blueprint.items,
            player: blueprint.player,
            vocabulary: gameVocabulary,
            pronouns: pronouns,
            activeFuses: activeFuses,
            activeDaemons: activeDaemons,
            globalState: globalState
        )
        self.parser = parser
        self.ioHandler = ioHandler

        // Initialize the compute handlers directly from the blueprint
        self.itemComputers = blueprint.itemComputers
        self.locationComputers = blueprint.locationComputers

        // Combine custom and default action handlers, with custom handlers taking precedence
        let combinedHandlers = allActionHandlers + Self.defaultActionHandlers
        self.actionHandlers = combinedHandlers
        self.itemEventHandlers = blueprint.itemEventHandlers
        self.locationEventHandlers = blueprint.locationEventHandlers

        #if DEBUG
        self.actionHandlers.append(DebugActionHandler())
        #endif
    }

    // MARK: - Action Handler Processing

    /// Extracts verb definitions from action handlers to build vocabulary.
    static func extractVerbDefinitions(from handlers: [ActionHandler]) -> [Verb] {
        var verbs: [Verb] = []

        for handler in handlers {
            // Each handler can contribute multiple verbs
            for verbID in handler.verbs {
                let verb = Verb(
                    id: verbID,
                    syntax: handler.syntax,
                    requiresLight: handler.requiresLight
                )
                verbs.append(verb)
            }
        }

        return verbs
    }
}

// MARK: - Game Loop

extension GameEngine {
    /// Starts and runs the main game loop.
    ///
    /// This method is the primary entry point for beginning and playing the game.
    /// It performs the following sequence:
    /// 1. Sets up the `IOHandler` (e.g., preparing the console or UI).
    /// 2. Prints the game's title and introduction message.
    /// 3. Marks the player's starting location as visited and describes it.
    /// 4. Enters the main turn-based loop, which continues until `shouldQuit` becomes `true`.
    ///    Each iteration of the loop involves:
    ///    a. Displaying the status line (current location, score, moves) via `showStatus()`.
    ///    b. Processing a single player turn via `processTurn()`.
    /// 5. After the loop terminates (e.g., player quits), performs teardown for the `IOHandler`.
    ///
    /// Game developers typically do not call this method directly after initialization;
    /// it is intended to be the engine's top-level execution flow.
    public func run() async {
        await ioHandler.setup()
        await ioHandler.print(storyTitle, style: .strong)
        await ioHandler.print(introduction)

        do {
            // Describe the starting location with full description
            try await describeCurrentLocation(forceFullDescription: true)
        } catch {
            logError("\(error)")
        }

        while !shouldQuit {
            await showStatus()
            do {
                try await processTurn()
            } catch {
                logError("\(error)")
            }
        }

        await ioHandler.teardown()
    }

    /// Signals the engine to stop the main game loop and end the game after the
    /// current turn has been fully processed.
    ///
    /// This is the standard way to programmatically quit the game from within an
    /// action handler or game hook.
    public func requestQuit() {
        self.shouldQuit = true
    }
}

extension GameEngine {
    /// Processes a single turn of the game, including player input, parsing, command execution, and clock ticks.
    ///
    /// This method orchestrates the core sequence of events within a single game turn:
    /// 1. Prompts the player for input via the `IOHandler`.
    ///    If input is `nil` (e.g., EOF) or explicitly "quit", `shouldQuit` is set, and the turn ends.
    /// 2. Parses the player's input string into a structured `Command` using the `parser`.
    /// 3. If parsing is successful:
    ///    a. If the command is to quit or `shouldQuit` is set, the turn ends.
    ///    b. Calls `execute(command:)` to process the command through event and action handlers.
    ///    c. If the command was a movement command (`.go`) to an unvisited room, or a command
    ///       that changed the light state (e.g., `.turnOn`, `.turnOff` a light source), it then
    ///       calls `describeCurrentLocation()`.
    /// 4. Advances game time by calling `tickClock()`, which processes active fuses and daemons.
    ///    If `tickClock()` sets `shouldQuit` (e.g., a fuse ends the game), the turn ends.
    /// 5. If parsing fails, reports the `ParseError` to the player via `report(parseError:)`.
    ///
    /// Errors during turn processing are logged.
    func processTurn() async throws {
        if shouldQuit { return }

        // 1. Get Player Input
        guard let input = await ioHandler.readLine(prompt: "> ") else {
            await ioHandler.print("\nGoodbye!")
            shouldQuit = true
            return
        }

        // 2. Basic quit command check (can be expanded)
        if input.lowercased() == "quit" {
            shouldQuit = true
            return
        }

        // 3. Parse Input
        let parseResult = parser.parse(
            input: input,
            vocabulary: gameState.vocabulary,
            gameState: gameState
        )

        // 4. Execute Command or Handle Error
        switch parseResult {
        case .success(let command):
            // Allow quit command to be processed by QuitActionHandler
            // Only exit early if shouldQuit is already set
            if shouldQuit { return }
            await execute(command: command)

        case .failure(let error):
            await report(parseError: error)
        }

        // 5. Timed events happen AFTER the player's action is complete (or failed).
        if !shouldQuit {
            do {
                try await tickClock()
            } catch {
                logError("Error processing timed events: \(error)")
            }
        }
    }

    /// Reports user-friendly messages for action responses (errors or simple feedback)
    /// to the player. This method is used internally by the engine to translate
    /// `ActionResponse` enum cases, often thrown or returned by `ActionHandler`
    /// validation or processing steps, into textual feedback for the player.
    ///
    /// It also logs more detailed information for certain critical errors like
    /// `.internalEngineError` or `.stateValidationFailed`.
    func report(_ response: ActionResponse) async {
        // Determine the user-facing message using MessageProvider
        let message = switch response {
        case .containerIsClosed(let item):
            messageProvider.containerIsClosed(item: theThat(item))
        case .containerIsOpen(let item):
            messageProvider.containerIsOpen(item: theThat(item))
        case .custom(let message):
            messageProvider.custom(message: message)
        case .directionIsBlocked(let reason):
            messageProvider.directionIsBlocked(reason: reason)
        case .internalEngineError:
            messageProvider.internalEngineError()
        case .invalidDirection:
            messageProvider.invalidDirection()
        case .invalidIndirectObject(let objectName):
            messageProvider.invalidIndirectObject(object: theThat(objectName))
        case .invalidValue:
            messageProvider.internalEngineError()
        case .itemAlreadyClosed(let item):
            messageProvider.itemAlreadyClosed(item: theThat(item))
        case .itemAlreadyOpen(let item):
            messageProvider.itemAlreadyOpen(item: theThat(item))
        case .itemIsAlreadyWorn(let item):
            messageProvider.itemIsAlreadyWorn(item: theThat(item))
        case .itemIsLocked(let item):
            messageProvider.itemIsLocked(item: theThat(item))
        case .itemIsNotWorn(let item):
            messageProvider.itemIsNotWorn(item: theThat(item))
        case .itemIsUnlocked(let item):
            messageProvider.itemIsUnlocked(item: theThat(item))
        case .itemNotAccessible(let item):
            messageProvider.itemNotAccessible(item: anySuch(item))
        case .itemNotClosable(let item):
            messageProvider.itemNotClosable(item: theThat(item))
        case .itemNotDroppable(let item):
            messageProvider.itemNotDroppable(item: theThat(item))
        case .itemNotEdible(let item):
            messageProvider.itemNotEdible(item: theThat(item))
        case .itemNotHeld(let item):
            messageProvider.itemNotHeld(item: theThat(item))
        case .itemNotInContainer(let item, let container):
            messageProvider.itemNotInContainer(item: theThat(item), container: theThat(container))
        case .itemNotLockable(let item):
            messageProvider.itemNotLockable(item: theThat(item))
        case .itemNotOnSurface(let item, let surface):
            messageProvider.itemNotOnSurface(item: theThat(item), surface: theThat(surface))
        case .itemNotOpenable(let item):
            messageProvider.itemNotOpenable(item: theThat(item))
        case .itemNotReadable(let item):
            messageProvider.itemNotReadable(item: theThat(item))
        case .itemNotRemovable(let item):
            messageProvider.itemNotRemovable(item: theThat(item))
        case .itemNotTakable(let item):
            messageProvider.itemNotTakable(item: theThat(item))
        case .itemNotUnlockable(let item):
            messageProvider.itemNotUnlockable(item: theThat(item))
        case .itemNotWearable(let item):
            messageProvider.itemNotWearable(item: theThat(item))
        case .itemTooLargeForContainer(let item, let container):
            messageProvider.itemTooLargeForContainer(item: theThat(item), container: theThat(container))
        case .playerCannotCarryMore:
            messageProvider.playerCannotCarryMore()
        case .prerequisiteNotMet(let customMessage):
            messageProvider.prerequisiteNotMet(message: customMessage)
        case .roomIsDark:
            messageProvider.roomIsDark()
        case .stateValidationFailed:
            messageProvider.stateValidationFailed()
        case .targetIsNotAContainer(let item):
            messageProvider.targetIsNotAContainer(item: theThat(item))
        case .targetIsNotASurface(let item):
            messageProvider.targetIsNotASurface(item: theThat(item))
        case .toolMissing(let tool):
            messageProvider.toolMissing(tool: tool)
        case .unknownEntity:
            messageProvider.unknownEntity()
        case .unknownVerb(let verb):
            messageProvider.unknownVerb(verb: verb)
        case .wrongKey(let keyID, let lockID):
            messageProvider.wrongKey(key: theThat(keyID), lock: theThat(lockID))
        }

        await ioHandler.print(message)

        // Log detailed errors separately
        switch response {
        case .internalEngineError(let msg):
            logError("ActionResponse: Internal Engine Error: \(msg)")
        case .invalidValue(let msg):
            logError("ActionResponse: Invalid Value: \(msg)")
        case .stateValidationFailed(let change, let actualOldValue):
            // Construct the log string first
            let logDetail = """
                State Validation Failed!
                   - Change: \(change.description.multiline(2))
                   - Expected Old Value: \(String(describing: change.oldValue))
                   - Actual Old Value: \(String(describing: actualOldValue))
                """
            logError("ActionResponse: \(logDetail)")
        default:
            break  // No detailed logging needed for other handled errors
        }
    }

    /// Reports a parsing error to the player.
    /// This method is used internally by the engine to translate `ParseError` enum cases
    /// into textual feedback for the player when their input cannot be understood.
    /// For `.internalError` cases, it also logs detailed information.
    func report(parseError: ParseError) async {
        let message = switch parseError {
        case .emptyInput:
            messageProvider.emptyInput()
        case .unknownVerb(let verb):
            messageProvider.parseUnknownVerb(verb: verb)
        case .unknownNoun(let noun):
            messageProvider.unknownNoun(noun: noun)
        case .itemNotInScope(let noun):
            messageProvider.itemNotInScope(noun: noun)
        case .modifierMismatch(let noun, let modifiers):
            messageProvider.modifierMismatch(noun: noun, modifiers: modifiers)
        case .ambiguity(let text):
            messageProvider.ambiguity(text: text)
        case .ambiguousPronounReference(let text):
            messageProvider.ambiguousPronounReference(text: text)
        case .badGrammar(let text):
            messageProvider.badGrammar(text: text)
        case .pronounNotSet(let pronoun):
            messageProvider.pronounNotSet(pronoun: pronoun)
        case .pronounRefersToOutOfScopeItem(let pronoun):
            messageProvider.pronounRefersToOutOfScopeItem(pronoun: pronoun)
        case .internalError:
            messageProvider.internalParseError()
        }

        await ioHandler.print(message)

        if case .internalError(let details) = parseError {
            logError("ParseError: \(details)")
        }
    }

    /// Displays the status line (e.g., current location, score, and turn count)
    /// to the player via the `IOHandler`.
    /// This is called automatically at the start of each turn before `processTurn()`.
    func showStatus() async {
        guard let currentLocation = gameState.locations[playerLocationID] else { return }
        await ioHandler.showStatusLine(
            roomName: currentLocation.name,
            score: gameState.player.score,
            turns: gameState.player.moves
        )
    }
}

// MARK: - Decorators

extension GameEngine {
    private func anySuch(_ itemID: ItemID) -> String {
        if let item = try? item(itemID), item.hasFlag(.isTouched) {
            "the \(item.name)"
        } else {
            "any such thing"
        }
    }

    /// Returns `the {name}` of an item, or an alternate reference if the name is unknown.
    ///
    /// - Parameters:
    ///   - itemID: The item identifier.
    ///   - alternate: An alternate reference to the item.
    /// - Returns: `the {name}` of an item, or `that` if name is unknown.
    private func theThat(
        _ itemID: ItemID,
        alternate: String = "that"
    ) -> String {
        if let item = try? item(itemID) {
            item.withDefiniteArticle
        } else {
            alternate
        }
    }

    /// Returns `the {name}` of an item, or an alternate reference if the name is unknown.
    ///
    /// - Parameters:
    ///   - itemName: The item name.
    ///   - alternate: An alternate reference to the item.
    /// - Returns: `the {name}` of an item, or `that` if name is unknown.
    private func theThat(
        _ itemName: String?,
        alternate: String = "that"
    ) -> String {
        if let itemName {
            "the \(itemName)"
        } else {
            alternate
        }
    }
}

// MARK: - Clock Tick Logic

extension GameEngine {
    /// Advances the game clock by one tick, processing all active fuses and daemons.
    ///
    /// This method can be called to advance game time by one turn. It performs the following actions:
    /// 1. **Turn Increment**: Increments the player's move counter to advance game time.
    /// 2. **Fuses**: Iterates through all `activeFuses` in `gameState`.
    ///    - Decrements the turn counter for each active fuse.
    ///    - If a fuse's counter reaches zero or less:
    ///        - Retrieves the corresponding `Fuse` from the `GameBlueprint`.
    ///        - Executes the fuse's `action` closure, passing the `GameEngine` instance.
    ///        - Removes the fuse from `activeFuses` in `gameState`.
    ///        - If the fuse's `repeats` flag is `true`, it reactivates the fuse by adding it
    ///          back to `activeFuses` with its `initialTurns` count.
    /// 3. **Daemons**: Iterates through all `activeDaemons` in `gameState`.
    ///    - Retrieves the corresponding `Daemon` from the `GameBlueprint`.
    ///    - Executes the daemon's `action` closure, passing the `GameEngine` instance.
    ///
    /// Fuse and daemon actions can modify game state, print messages (by returning an `ActionResult`
    /// that the engine then processes), or even set `shouldQuit` to end the game.
    /// Errors during fuse/daemon definition lookup or action execution are logged.
    func tickClock() async throws {
        // Increment turn counter FIRST so daemons can see the correct turn number
        let moves = gameState.player.moves
        try gameState.apply(
            StateChange(
                entityID: .player,
                attribute: .playerMoves,
                oldValue: .int(moves),
                newValue: .int(moves + 1)
            )
        )
        let currentTurn = gameState.player.moves

        // --- Process Fuses ---
        // Explicitly define the action type to match Fuse.action
        typealias FuseActionType = @Sendable (GameEngine) async -> ActionResult?
        var expiredFuseIDsToExecute:
            [(id: FuseID, action: FuseActionType, definition: Fuse)] = []

        // Iterate over a copy of keys from gameState.activeFuses for safe modification
        let activeFuseIDsInState = Array(gameState.activeFuses.keys)

        for fuseID in activeFuseIDsInState {
            guard let currentTurns = gameState.activeFuses[fuseID] else {
                continue
            }

            let newTurns = currentTurns - 1

            let updateChange = StateChange(
                entityID: .global,
                attribute: .updateFuseTurns(fuseID: fuseID),
                oldValue: .int(currentTurns),
                newValue: .int(newTurns)
            )
            try gameState.apply(updateChange)

            if newTurns <= 0 {
                guard let definition = fuses[fuseID] else {
                    print(
                        "TickClock Error: No Fuse found for expiring fuse ID '\(fuseID)'. Cannot execute."
                    )
                    let removeChangeOnError = StateChange(
                        entityID: .global,
                        attribute: .removeActiveFuse(fuseID: fuseID),
                        oldValue: .int(newTurns),
                        newValue: .int(0)
                    )
                    try gameState.apply(removeChangeOnError)
                    continue
                }
                expiredFuseIDsToExecute.append(
                    (id: fuseID, action: definition.action, definition: definition))

                let removeChange = StateChange(
                    entityID: .global,
                    attribute: .removeActiveFuse(fuseID: fuseID),
                    oldValue: .int(newTurns),
                    newValue: .int(0)
                )
                try gameState.apply(removeChange)
            }
        }

        // Execute actions of expired fuses AFTER all state changes for this tick's expirations are processed
        for fuseToExecute in expiredFuseIDsToExecute {
            if let actionResult = await fuseToExecute.action(self) {
                _ = try await processActionResult(actionResult)
            }

            // Handle fuse repetition
            if fuseToExecute.definition.repeats {
                let restartChange = StateChange(
                    entityID: .global,
                    attribute: .addActiveFuse(
                        fuseID: fuseToExecute.id,
                        initialTurns: fuseToExecute.definition.initialTurns
                    ),
                    oldValue: nil,
                    newValue: .int(fuseToExecute.definition.initialTurns)
                )
                try gameState.apply(restartChange)
            }

            if shouldQuit { return }
        }

        // --- Process Daemons ---
        // Daemons are only checked against gameState.activeDaemons, no direct state change here.
        for daemonID in gameState.activeDaemons {
            // Get definition from registry
            guard let definition = daemons[daemonID] else {
                print(
                    "Warning: Active daemon '\(daemonID)' has no definition in registry. Skipping.")
                continue
            }

            // Check if it's time for this daemon to run based on frequency
            // Skip execution on turn 0 and run only on turns where currentTurn % frequency == 0
            if currentTurn > 0 && currentTurn % definition.frequency == 0 {
                // Execute the daemon's action
                if let actionResult = try await definition.action(self) {
                    _ = try await processActionResult(actionResult)
                }
                if shouldQuit { return }
            }
        }
    }
}

// MARK: - Command Execution

extension GameEngine {

            /// Finds the appropriate action handler for a given command.
    ///
    /// This method searches through all registered action handlers to find one that can
    /// process the given command based on:
    /// 1. The handler's verb list (if it specifies verbs)
    /// 2. The handler's syntax rules (for handlers that use specific syntax patterns)
    ///
    /// - Parameter command: The command to find a handler for
    /// - Returns: The action handler that can process this command, or nil if none found
    private func findActionHandler(for command: Command) -> ActionHandler? {
        for handler in actionHandlers {
            // Check if this handler can handle this verb (if it specifies verbs)
            if !handler.verbs.isEmpty && handler.verbs.contains(command.verb) {
                return handler
            }

            // For handlers with empty verbs, check if any syntax rules could match this command
            if handler.verbs.isEmpty && couldHandlerMatchCommand(handler, command) {
                return handler
            }
        }

        return nil
    }

    /// Finds action handlers that represent a specific conceptual action.
    ///
    /// This allows game logic to check for conceptual actions without worrying about
    /// the specific verbs used. For example, checking for `.drop` actions regardless
    /// of whether the player typed "drop", "put", or "place".
    ///
    /// - Parameter actionID: The conceptual action to find handlers for
    /// - Returns: Array of action handlers that represent this conceptual action
    public func actionHandlers(for actionID: ActionID) -> [ActionHandler] {
        return actionHandlers.filter { handler in
            handler.actions.contains(actionID)
        }
    }

    /// Checks if a command represents a specific conceptual action.
    ///
    /// This is useful for game logic that needs to react to conceptual actions
    /// regardless of the specific verbs used. For example, checking if the player
    /// is trying to drop something, regardless of whether they typed "drop lamp",
    /// "put lamp down", or "place lamp on ground".
    ///
    /// - Parameters:
    ///   - command: The command to check
    ///   - actionID: The conceptual action to check for
    /// - Returns: True if the command represents the specified conceptual action
    public func commandRepresents(_ command: Command, action actionID: ActionID) -> Bool {
        guard let handler = findActionHandler(for: command) else {
            return false
        }
        return handler.actions.contains(actionID)
    }

    /// Checks if a handler's syntax rules could potentially match a command.
    ///
    /// This performs a basic compatibility check focusing on verb-specific patterns.
    /// For syntax rules that use `.specificVerb(verbID)`, we check if the command's
    /// verb matches that specific verbID.
    ///
    /// - Parameters:
    ///   - handler: The action handler to check
    ///   - command: The command to match against
    /// - Returns: True if the handler could potentially process this command
    private func couldHandlerMatchCommand(_ handler: ActionHandler, _ command: Command) -> Bool {
        for syntaxRule in handler.syntax {
            if couldSyntaxRuleMatchCommand(syntaxRule, command) {
                return true
            }
        }
        return false
    }

    /// Checks if a specific syntax rule could match a command.
    ///
    /// This performs basic pattern matching, focusing on verb compatibility.
    /// For patterns with `.specificVerb(verbID)`, it checks if the command's verb
    /// matches the required verbID.
    ///
    /// - Parameters:
    ///   - syntaxRule: The syntax rule to check
    ///   - command: The command to match against
    /// - Returns: True if the syntax rule could match this command
    private func couldSyntaxRuleMatchCommand(_ syntaxRule: SyntaxRule, _ command: Command) -> Bool {
        // Look for specificVerb requirements in the pattern
        for token in syntaxRule.pattern {
            switch token {
            case .specificVerb(let requiredVerbID):
                // If this pattern requires a specific verb, check if command matches
                if command.verb != requiredVerbID {
                    return false  // Command verb doesn't match required verb
                }
            case .verb:
                // Generic .verb token would be handled by verb-based handlers
                // Syntax-only handlers shouldn't have generic .verb tokens
                continue
            default:
                // Other tokens (directObject, particles, etc.) would need more sophisticated
                // matching logic, but for now we'll assume they could match
                continue
            }
        }

        // If we get here, either:
        // 1. All specificVerb requirements were satisfied, or
        // 2. There were no specificVerb requirements
        return true
    }
    /// Executes a parsed game command, orchestrating calls to event handlers and action handlers.
    ///
    /// This is a central method in processing player actions. It performs the following sequence:
    /// 1. **Item `beforeTurn` Events**: For every item in the player's current location or
    ///    inventory that has an `ItemEventHandler` registered for `.beforeTurn`,
    ///    executes that handler. If any handler returns `true` (indicating it fully handled
    ///    the command or turn) or sets `shouldQuit`, further processing of the command stops.
    /// 2. **Location `beforeTurn` Events**: If the player's current location has a
    ///    `LocationEventHandler` registered for `.beforeTurn`, executes it. If it returns `true`
    ///    or sets `shouldQuit`, further processing stops.
    /// 3. **Main Action Handling**: If the command was not fully handled by `beforeTurn` events:
    ///    a. Retrieves the appropriate `ActionHandler` for the command's verb from the
    ///       engine's `actionHandlers` registry.
    ///    b. If a handler is found:
    ///        i. Calls the handler's `validate(context:)` method. If validation throws an
    ///           `ActionResponse`, reports it and stops.
    ///       ii. Calls the handler's `process(context:)` method. This typically returns an
    ///           `ActionResult` containing state changes and a message.
    ///      iii. Applies any `StateChange`s from the `ActionResult` to `gameState`.
    ///       iv. Prints the `ActionResult.message` to the player.
    ///        v. Calls the handler's `postProcess(context:result:)` method for any final actions.
    ///       vi. Processes any `SideEffect`s from the `ActionResult`.
    ///    c. If no `ActionHandler` is found for the verb, reports an `ActionResponse.unknownVerb` error.
    /// 4. **Item `afterTurn` Events**: Similar to `beforeTurn`, executes `.afterTurn` item event handlers.
    /// 5. **Location `afterTurn` Events**: Similar to `beforeTurn`, executes `.afterTurn` location event handlers.
    /// 6. **Movement and Lighting Detection**: For movement commands (`.go`, `.climb`) and lighting commands
    ///    (`.turnOn`, `.turnOff`), detects location changes or lighting state changes and automatically
    ///    describes the current location with appropriate transition messages.
    ///
    /// Any `ActionResponse` errors thrown during this process are caught and reported to the player.
    /// Other errors are logged.
    ///
    /// - Parameter command: The `Command` object to execute.
    public func execute(command: Command) async {
        var actionHandled = false
        var actionResponse: Error? = nil  // To store error from object handlers

        // Store the player's current location and lighting state before executing the command
        let locationBeforeCommand = playerLocationID
        let wasLitBeforeCommand = await playerLocationIsLit()

        // --- Room BeforeTurn Hook ---
        let currentLocationID = playerLocationID
        if let locationHandler = locationEventHandlers[currentLocationID] {
            do {
                // Call handler, pass command using correct enum case syntax
                if let result = try await locationHandler.handle(self, .beforeTurn(command)) {
                    // Room handler returned a result, process it
                    if try await processActionResult(result) {
                        return  // Room handler handled everything
                    }
                }
            } catch {
                // Log error and potentially halt turn?
                logWarning("Error in room beforeTurn handler: \(error)")
                // Decide if this error should block the turn. For now, let's continue.
            }
            // Check if handler quit the game
            if shouldQuit { return }
        }

        // --- Try Object Action Handlers ---

        // 1. Check Direct Object Handler (singular)
        if case .item(let doItemID) = command.directObject,
            let itemHandler = itemEventHandlers[doItemID]
        {
            do {
                // Pass the engine and the event to the handler
                if let result = try await itemHandler.handle(self, .beforeTurn(command)) {
                    // Object handler returned a result, process it
                    if try await processActionResult(result) {
                        return  // Object handler handled everything
                    }
                }
            } catch let response {
                actionResponse = response
                actionHandled = true  // Treat error as handled to prevent default handler
            }
        }

        // 1b. Check Direct Objects Handlers (plural) for multi-item commands
        if !actionHandled, actionResponse == nil, !command.directObjects.isEmpty {
            for directObjectRef in command.directObjects {
                guard case .item(let doItemID) = directObjectRef,
                      let itemHandler = itemEventHandlers[doItemID] else {
                    continue
                }

                do {
                    if let result = try await itemHandler.handle(self, .beforeTurn(command)) {
                        // Object handler returned a result, process it
                        if try await processActionResult(result) {
                            return  // Object handler handled everything
                        }
                    }
                } catch let response {
                    actionResponse = response
                    actionHandled = true  // Treat error as handled to prevent default handler
                    break  // Stop processing other objects if one throws an error
                }

                if shouldQuit { return }
            }
        }

        // 2. Check Indirect Object Handler (only if DO didn't handle it and no error occurred)
        // ZIL precedence: Often, if a DO routine handled it (or errored), the IO routine wasn't called.
        if !actionHandled, actionResponse == nil,
            case .item(let ioItemID) = command.indirectObject,
            let itemHandler = itemEventHandlers[ioItemID]
        {
            do {
                if let result = try await itemHandler.handle(self, .beforeTurn(command)) {
                    // Object handler returned a result, process it
                    if try await processActionResult(result) {
                        return  // Object handler handled everything
                    }
                }
            } catch let response {
                actionResponse = response
                actionHandled = true
            }
        }

        // --- Execute Default Handler or Report Error ---

        if let response = actionResponse {
            // An object handler threw an error
            if let specificResponse = response as? ActionResponse {
                await report(specificResponse)
            } else {
                logWarning("An unexpected error occurred in an object handler: \(response)")
                await ioHandler.print(
                    "Sorry, something went wrong performing that action on the specific item.")
            }
        } else if !actionHandled {
            // No object handler took charge, check for darkness before running default verb handler

            let isLit = await playerLocationIsLit()

            // Retrieve verb definition to check requiresLight property
            // Note: Parser should ensure command.verbID exists in vocabulary
            // Correct: Look up the Verb definition directly
            guard let verb = gameState.vocabulary.verbDefinitions[command.verb] else {
                // This case should ideally not be reached if parser validates verbs
                logWarning(
                    """
                    Internal Error: Unknown verb ID \
                    '\(command.verb.rawValue)' reached execution. \
                    If you encounter this error during testing, make sure to use \
                    `parse(input:vocabulary:gameState:)` to generate the command.
                    """)
                await ioHandler.print("I don't know how to '\(command.verb.rawValue)'.")
                return
            }

            // If the room is dark and the verb requires light (and isn't 'turn'), report error.
            if !isLit && verb.requiresLight && command.verb != .turn {
                await report(.roomIsDark)
            } else {
                // Room is lit OR verb doesn't require light, proceed with default handler execution.
                guard let verbHandler = findActionHandler(for: command) else {
                    // No handler registered for this verb (should match vocabulary definition)
                    logWarning(
                        """
                        Internal Error: No ActionHandler registered for verb ID \
                        '\(command.verb.rawValue)'.
                        """)
                    await ioHandler.print("I don't know how to '\(command.verb.rawValue)'.")
                    return
                }

                // --- Execute Handler (New Logic) ---
                do {
                    // Create the context for this action using a snapshot
                    let context = ActionContext(
                        command: command,
                        engine: self
                    )

                    // Directly use the enhanced handler pipeline
                    try await verbHandler.validate(context: context)
                    let result = try await verbHandler.process(context: context)

                    // Process the result (apply changes, print message)
                    _ = try await processActionResult(result)

                    // Call postProcess (even if default is empty)
                    try await verbHandler.postProcess(context: context, result: result)

                } catch let actionResponse as ActionResponse {
                    // Catch ActionResponse specifically for reporting
                    await report(actionResponse)
                } catch {
                    // Catch any other unexpected errors from handlers
                    logError("Unexpected error during handler execution: \(error)")
                    await ioHandler.print("An unexpected problem occurred.")
                }
                // --- End Execute Handler ---
            }
        }
        // If actionHandled is true and error is nil, the object handler succeeded silently (or printed its own msg).

        // --- Item AfterTurn Hooks ---

        // 1. Check Direct Object AfterTurn Handler (singular)
        if case .item(let doItemID) = command.directObject,
            let itemHandler = itemEventHandlers[doItemID]
        {
            do {
                if let result = try await itemHandler.handle(self, .afterTurn(command)),
                    try await processActionResult(result)
                {
                    return
                }
            } catch {
                logWarning("Error in direct object afterTurn handler: \(error)")
            }
            if shouldQuit { return }
        }

        // 1b. Check Direct Objects AfterTurn Handlers (plural) for multi-item commands
        if !command.directObjects.isEmpty {
            for directObjectRef in command.directObjects {
                guard case .item(let doItemID) = directObjectRef,
                      let itemHandler = itemEventHandlers[doItemID] else {
                    continue
                }

                do {
                    if let result = try await itemHandler.handle(self, .afterTurn(command)),
                        try await processActionResult(result)
                    {
                        return
                    }
                } catch {
                    logWarning("Error in direct object afterTurn handler: \(error)")
                }

                if shouldQuit { return }
            }
        }

        // 2. Check Indirect Object AfterTurn Handler
        if case .item(let ioItemID) = command.indirectObject,
            let itemHandler = itemEventHandlers[ioItemID]
        {
            do {
                if let result = try await itemHandler.handle(self, .afterTurn(command)),
                    try await processActionResult(result)
                {
                    return
                }
            } catch {
                logWarning("Error in indirect object afterTurn handler: \(error)")
            }
            if shouldQuit { return }
        }

        // --- Room AfterTurn Hook ---
        if let locationHandler = locationEventHandlers[currentLocationID] {
            do {
                // Call handler, ignore return value, use correct enum case syntax
                if let result = try await locationHandler.handle(self, .afterTurn(command)),
                    try await processActionResult(result)
                {
                    return
                }
            } catch {
                logWarning("Error in room afterTurn handler: \(error)")
            }
            // Check if handler quit the game
            if shouldQuit { return }
        }

        // --- Movement and Lighting Detection ---
        do {
            try await handlePostCommandLocationUpdates(
                command: command,
                locationBeforeCommand: locationBeforeCommand,
                wasLitBeforeCommand: wasLitBeforeCommand
            )
        } catch {
            logError("Error handling post-command location updates: \(error)")
        }
    }

    /// Handles location description updates after command execution for movement and lighting changes.
    ///
    /// This method detects when the player has moved to a different location or when the lighting
    /// state has changed, and automatically describes the current location with appropriate
    /// transition messages.
    ///
    /// - Parameters:
    ///   - command: The command that was executed.
    ///   - locationBeforeCommand: The player's location before the command was executed.
    ///   - wasLitBeforeCommand: Whether the player's location was lit before the command was executed.
    private func handlePostCommandLocationUpdates(
        command: Command,
        locationBeforeCommand: LocationID,
        wasLitBeforeCommand: Bool
    ) async throws {
        // Handle location description after movement or light change
        var shouldDescribe = false
        var forceFullDescription = false

        // Handle .onEnter event for new location
        if locationBeforeCommand != playerLocationID {
            // Trigger .onEnter event for the new location
            if let locationHandler = locationEventHandlers[playerLocationID] {
                if let result = try await locationHandler.handle(self, .onEnter) {
                    _ = try await processActionResult(result)
                }
                // Check if handler quit the game
                if shouldQuit { return }
            }
            shouldDescribe = true
        }

        // Handle lighting transition messages for movement
        let isLitAfterCommand = await playerLocationIsLit()

        if wasLitBeforeCommand && !isLitAfterCommand {
            // Moved from lit to dark - show transition message and darkness message combined
            await ioHandler.print(
                """
                \(messageProvider.nowDark())

                \(messageProvider.roomIsDark())
                """)
            shouldDescribe = false
            forceFullDescription = true
        } else if !wasLitBeforeCommand && isLitAfterCommand {
            shouldDescribe = true
            forceFullDescription = true
        }

        if shouldDescribe {
            try await describeCurrentLocation(forceFullDescription: forceFullDescription)
        }
    }

    /// Processes the result of an action, applying state changes and printing the message.
    ///
    /// This helper is called after an `ActionHandler` (or an event handler that
    /// returns an `ActionResult`) has processed a command or event. It applies any
    /// `StateChange`s specified in the `ActionResult` to the `gameState` and prints
    /// the `ActionResult.message` to the player via the `IOHandler`.
    ///
    /// - Parameter result: The `ActionResult` returned by an action or event handler.
    /// - Returns: `true` if the `ActionResult` contained a message that was printed,
    ///   `false` otherwise.
    /// - Throws: Re-throws errors encountered during state application.
    func processActionResult(_ result: ActionResult) async throws -> Bool {
        // 1. Apply State Changes
        // Errors during apply will propagate up.
        for change in result.changes {
            do {
                try await applyWithDynamicValidation(change)
            } catch {
                logError(
                    """
                    Failed to apply state change during processActionResult:
                       - \(error)
                       - Change: \(change.description.multiline(2))
                    """)
                throw error  // Re-throw the error to be caught by execute()
            }
        }

        // 2. Process Side Effects
        if !result.effects.isEmpty {
            do {
                try await processSideEffects(result.effects)
            } catch {
                logError(
                    """
                    Failed to process side effects during processActionResult:
                       - \(error)
                       - Side Effects: \(result.effects)
                    """)
                throw error
            }
        }

        // 3. Print Result Message
        if let message = result.message {
            await ioHandler.print(message)
            return true
        } else {
            return false
        }
    }

    /// Applies a `StateChange` with dynamic validation, respecting the action pipeline.
    ///
    /// This method performs dynamic validation using the `DynamicAttributeRegistry` before
    /// applying the change to the game state. This ensures that dynamic validation handlers
    /// are respected even when state changes are applied directly.
    ///
    /// - Parameter change: The `StateChange` to validate and apply.
    /// - Throws: `ActionResponse.invalidValue` if dynamic validation fails, or re-throws
    ///           any errors from `GameState.apply()`.
    func applyWithDynamicValidation(_ change: StateChange) async throws {
        // Perform dynamic validation for item and location attributes
        switch change.attribute {
        case .itemAttribute(let key):
            guard case .item(let itemID) = change.entityID else {
                throw ActionResponse.internalEngineError(
                    "Invalid entity ID for itemAttribute: expected .item"
                )
            }

            let isValid = try await validateStateValue(
                itemID: itemID,
                attributeID: key,
                newValue: change.newValue
            )

            if !isValid {
                throw ActionResponse.invalidValue(
                    """
                    Dynamic validation failed for item attribute '\(key.rawValue)' \
                    on \(itemID.rawValue): \(change.newValue)
                    """)
            }

        case .locationAttribute(let key):
            guard case .location(let locationID) = change.entityID else {
                throw ActionResponse.internalEngineError(
                    "Invalid entity ID for locationAttribute: expected .location"
                )
            }

            let isValid = try await validateStateValue(
                locationID: locationID,
                attributeID: key,
                newValue: change.newValue
            )

            if !isValid {
                throw ActionResponse.invalidValue(
                    """
                    Dynamic validation failed for location attribute '\(key.rawValue)' \
                    on \(locationID.rawValue): \(change.newValue)
                    """)
            }

        default:
            // No dynamic validation needed for other attribute types
            break
        }

        // Apply the change to the game state
        try gameState.apply(change)
    }
}

// MARK: - Default Handlers

extension GameEngine {
    /// **Default Handlers**: The engine provides standard handlers for common verbs like
    /// `take`, `drop`, `look`, etc. Games can override these via custom handlers in the `GameBlueprint`.
    static var defaultActionHandlers: [ActionHandler] {
        let handlers: [ActionHandler] = [
            AskActionHandler(),
            AttackActionHandler(),
            BlowActionHandler(),
            BreatheActionHandler(),
            BriefActionHandler(),
            BurnActionHandler(),
            ChompActionHandler(),
            ClimbActionHandler(),
            ClimbOnActionHandler(),
            CloseActionHandler(),
            CryActionHandler(),
            CurseActionHandler(),
            CutActionHandler(),
            DanceActionHandler(),
            DeflateActionHandler(),
            DigActionHandler(),
            DrinkActionHandler(),
            DropActionHandler(),
            EatActionHandler(),
            EmptyActionHandler(),
            EnterActionHandler(),
            ExamineActionHandler(),
            FillActionHandler(),
            FindActionHandler(),
            GiveActionHandler(),
            GoActionHandler(),
            HelpActionHandler(),
            InflateActionHandler(),
            InsertActionHandler(),
            InventoryActionHandler(),
            JumpActionHandler(),
            KickActionHandler(),
            KissActionHandler(),
            KnockActionHandler(),
            LaughActionHandler(),
            ListenActionHandler(),
            LockActionHandler(),
            LookActionHandler(),
            LookInsideActionHandler(),
            LookUnderActionHandler(),
            MoveActionHandler(),
            OpenActionHandler(),
            PourActionHandler(),
            PressActionHandler(),
            PullActionHandler(),
            PushActionHandler(),
            PutOnActionHandler(),
            QuitActionHandler(),
            RaiseActionHandler(),
            ReadActionHandler(),
            RemoveActionHandler(),
            RestartActionHandler(),
            RestoreActionHandler(),
            RubActionHandler(),
            SaveActionHandler(),
            ScoreActionHandler(),
            ScriptActionHandler(),
            ShakeActionHandler(),
            SingActionHandler(),
            SmellActionHandler(),
            SqueezeActionHandler(),
            TakeActionHandler(),
            TasteActionHandler(),
            TellActionHandler(),
            ThinkActionHandler(),
            ThrowActionHandler(),
            TieActionHandler(),
            TouchActionHandler(),
            TurnActionHandler(),
            TurnOffActionHandler(),
            TurnOnActionHandler(),
            UnlockActionHandler(),
            UnscriptActionHandler(),
            VerboseActionHandler(),
            WaitActionHandler(),
            WaveActionHandler(),
            WearActionHandler(),
            XyzzyActionHandler(),
            YellActionHandler(),
        ]

        #if DEBUG
        return handlers + [DebugActionHandler()]
        #else
        return handlers
        #endif
    }
}

// MARK: - Logging helpers

extension GameEngine {
    func logError(_ message: String) {
        logger.error(
            Logger.Message(
                stringLiteral: message.multiline()
            )
        )
    }

    func logWarning(_ message: String) {
        logger.warning(
            Logger.Message(
                stringLiteral: message.multiline()
            )
        )
    }
}

// MARK: - Random Number Generation

extension GameEngine {
    /// Generates a random Double value between 0.0 and 1.0.
    ///
    /// This is a convenience method that provides the same interface as the original
    /// randomizer closure, making it easy to migrate existing code that expects
    /// a 0.0-1.0 range Double value.
    ///
    /// - Returns: A random Double between 0.0 and 1.0 (inclusive of 0.0, exclusive of 1.0).
    public func randomDouble() -> Double {
        Double.random(in: 0.0..<1.0, using: &randomNumberGenerator)
    }

    /// Generates a random integer between 0 and 100 (inclusive).
    ///
    /// This method provides a convenient way to generate random percentages, where 0 represents
    /// 0% and 100 represents 100%. This is useful for probability-based game mechanics and
    /// random events.
    ///
    /// - Returns: A random integer between 0 and 100 (inclusive).
    public func randomPercentage() -> Int {
        Int.random(in: 0...100, using: &randomNumberGenerator)
    }

    /// Returns a random element from the given collection.
    ///
    /// This method provides a convenient way to select a random element from any collection
    /// using the engine's seeded random number generator, ensuring reproducible randomness
    /// across game sessions.
    ///
    /// The implementation uses direct calls to `randomNumberGenerator.next()` and modulo
    /// arithmetic to avoid actor isolation issues with inout references.
    ///
    /// - Parameter collection: The collection to select a random element from.
    /// - Returns: A random element from the collection.
    /// - Throws: `ActionResponse.internalEngineError` if the collection is empty.
    public func randomElement<T>(in collection: some Collection<T>) throws -> T {
        guard !collection.isEmpty else {
            throw ActionResponse.internalEngineError(
                "Attempted to select a random element from an empty collection"
            )
        }
        let randomValue = randomNumberGenerator.next()
        let randomIndex = Int(randomValue % UInt64(collection.count))
        return collection[collection.index(collection.startIndex, offsetBy: randomIndex)]
    }
}

// MARK: - Save/Restore Game

extension GameEngine {
    /// Saves the current game state.
    ///
    /// This is a placeholder implementation that will be enhanced with actual
    /// file system persistence in future versions. Currently throws an error
    /// indicating the feature is not yet implemented.
    ///
    /// - Throws: An error indicating save functionality is not yet implemented.
    public func saveGame() async throws {
        // TODO: Implement actual save functionality
        // This would typically serialize the gameState to a file
        throw NSError(
            domain: "GnustoEngine",
            code: 1001,
            userInfo: [NSLocalizedDescriptionKey: "Save functionality not yet implemented."]
        )
    }

    /// Restores a previously saved game state.
    ///
    /// This is a placeholder implementation that will be enhanced with actual
    /// file system persistence in future versions. Currently throws an error
    /// indicating the feature is not yet implemented.
    ///
    /// - Throws: An error indicating restore functionality is not yet implemented.
    public func restoreGame() async throws {
        // TODO: Implement actual restore functionality
        // This would typically deserialize gameState from a file
        throw NSError(
            domain: "GnustoEngine",
            code: 1002,
            userInfo: [NSLocalizedDescriptionKey: "Restore functionality not yet implemented."]
        )
    }
}
