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
///   factory methods in `GameEngine+stateChanges.swift`) and then applying them,
///   or by using higher-level convenience mutation methods (e.g., in
///   `GameEngine+stateMutation.swift`).
/// - Access game-wide `GameConstants`.
/// - Trigger output to the player (usually by returning an `ActionResult` with a message).
public actor GameEngine: Sendable {
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
    private let parser: Parser

    /// The handler for all input and output operations, such as reading player commands
    /// and displaying game text. Game developers usually do not interact with this
    /// directly from handlers, as the engine provides higher-level mechanisms for output
    /// (e.g., the `message` property of an `ActionResult`, or by throwing an
    /// `ActionResponse` which the engine translates to a player-facing message).
    nonisolated internal let ioHandler: IOHandler

    /// A utility to determine what items and locations are currently perceivable or
    /// interactable by the player, considering factors like light, containment, and reach.
    /// This is used internally by various engine methods (e.g., `playerCanReach(_:)`)
    /// to resolve scope.
    lazy var scopeResolver = ScopeResolver(engine: self)

    /// The game-specific constants, such as title, introduction, and maximum score,
    /// derived from the `GameBlueprint` used to initialize the engine.
    public let constants: GameConstants

    /// The registry holding definitions for timed events (`FuseDefinition`)
    /// and background processes (`DaemonDefinition`) provided by the `GameBlueprint`.
    /// The engine uses this to manage these time-based game mechanics during `tickClock()`.
    public let timeRegistry: TimeRegistry

    /// The registry for custom logic that dynamically computes or validates item and
    /// location attributes. This is initialized from the `GameBlueprint` and can be
    /// further modified by game developers using methods like `registerItemCompute(attribute:handler:)`.
    public var dynamicAttributeRegistry: DynamicAttributeRegistry

    /// Registered `ActionHandler`s for specific verb commands (e.g., `.take`, `.look`).
    /// These are a combination of default engine handlers and custom handlers provided
    /// by the `GameBlueprint`, with custom handlers taking precedence.
    private var actionHandlers = [VerbID: ActionHandler]()

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
        ioHandler: IOHandler
    ) async {
        self.constants = blueprint.constants
        
        // Build vocabulary with custom verbs if not provided
        let gameVocabulary: Vocabulary
        if let providedVocabulary = vocabulary {
            gameVocabulary = providedVocabulary
        } else {
            // Create custom verbs from the blueprint's custom action handlers
            var customVerbs: [Verb] = []
            for verbID in blueprint.customActionHandlers.keys {
                // Create a basic definition; requiresLight=false is a safe default for custom verbs
                let verbDef = Verb(id: verbID, syntax: [], requiresLight: false)
                customVerbs.append(verbDef)
            }
            
            // Build vocabulary with custom verbs
            gameVocabulary = Vocabulary.build(
                items: blueprint.items,
                locations: blueprint.locations,
                verbs: customVerbs,
                useDefaultVerbs: true
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
        self.timeRegistry = blueprint.timeRegistry
        self.dynamicAttributeRegistry = blueprint.dynamicAttributeRegistry
        self.actionHandlers = blueprint.customActionHandlers
            .merging(Self.defaultActionHandlers) { (custom, _) in custom }
        self.itemEventHandlers = blueprint.itemEventHandlers
        self.locationEventHandlers = blueprint.locationEventHandlers

        #if DEBUG
        self.actionHandlers[.debug] = DebugActionHandler()
        #endif
    }
}

// MARK: - Game Loop

extension GameEngine {
    /// Starts and runs the main game loop.
    ///
    /// This method is the primary entry point for beginning and playing the game.
    /// It performs the following sequence:
    /// 1. Sets up the `IOHandler` (e.g., preparing the console or UI).
    /// 2. Prints the game's title and introduction message (from `GameConstants`).
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
        await ioHandler.print(constants.storyTitle, style: .strong)
        await ioHandler.print(constants.introduction)

        do {
            let startingLocationID = playerLocationID
            let startingLoc = try location(startingLocationID)
            if let addVisitedFlag = setFlag(.isVisited, on: startingLoc) {
                try gameState.apply(addVisitedFlag)
            }
            try await describeCurrentLocation()
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

    // MARK: Private helpers

    /// Processes a single turn of the game, including clock ticks, player input, parsing, and command execution.
    ///
    /// This method orchestrates the core sequence of events within a single game turn:
    /// 1. Advances game time by calling `tickClock()`, which processes active fuses and daemons.
    ///    If `tickClock()` sets `shouldQuit` (e.g., a fuse ends the game), the turn ends.
    /// 2. Prompts the player for input via the `IOHandler`.
    ///    If input is `nil` (e.g., EOF) or explicitly "quit", `shouldQuit` is set, and the turn ends.
    /// 3. Parses the player's input string into a structured `Command` using the `parser`.
    /// 4. Increments the player's move counter in `gameState`.
    /// 5. If parsing is successful:
    ///    a. If the command is to quit or `shouldQuit` is set, the turn ends.
    ///    b. Calls `execute(command:)` to process the command through event and action handlers.
    ///    c. If the command was a movement command (`.go`) to an unvisited room, or a command
    ///       that changed the light state (e.g., `.turnOn`, `.turnOff` a light source), it then
    ///       calls `describeCurrentLocation()`.
    /// 6. If parsing fails, reports the `ParseError` to the player via `report(parseError:)`.
    ///
    /// Errors during turn processing are logged.
    private func processTurn() async throws {
        // --- Tick the Clock (Fuses & Daemons) ---
        await tickClock()

        if shouldQuit { return } // Clock tick might trigger quit

        // 1. Get Player Input
        guard let input = await ioHandler.readLine(prompt: "> ") else {
            await ioHandler.print("\nGoodbye!")
            shouldQuit = true
            return
        }

        // Basic quit command check (can be expanded)
        if input.lowercased() == "quit" {
            shouldQuit = true
            return
        }

        // 2. Parse Input
        let vocabulary = gameState.vocabulary
        let parseResult = parser.parse(
            input: input,
            vocabulary: vocabulary,
            gameState: gameState
        )

        // Increment turn counter AFTER clock tick and BEFORE command execution
        let moves = gameState.player.moves
        try gameState.apply(
            StateChange(
                entityID: .player,
                attribute: .playerMoves,
                oldValue: .int(moves),
                newValue: .int(moves + 1)
            )
        )

        // 3. Execute Command or Handle Error
        switch parseResult {
        case .success(let command):
            if command.verb == .quit || shouldQuit { return }

            // Store the player's current location before executing the command
            let locationBeforeCommand = playerLocationID
            
            // For GO commands, check if the destination is unvisited before execution
            let destinationWasUnvisited: Bool
            if command.verb == .go {
                let exit = try? command.direction.flatMap { direction in
                    try location(playerLocationID).exits[direction]
                }
                destinationWasUnvisited = if let destination = try? location(exit?.destinationID) {
                    !destination.hasFlag(.isVisited)
                } else {
                    false
                }
            } else {
                destinationWasUnvisited = false
            }

            await execute(command: command)

            if command.verb == .quit || shouldQuit { return }

            // Handle location description after movement or light change
            let shouldDescribe: Bool
            switch command.verb {
            case .go:
                // Check if the player actually moved to a different location
                let locationAfterCommand = playerLocationID
                if locationBeforeCommand != locationAfterCommand {
                    // Player moved - use the pre-execution check for whether to describe
                    shouldDescribe = destinationWasUnvisited
                } else {
                    // Player didn't move (movement was prevented)
                    shouldDescribe = false
                }
            case .turnOn, .turnOff:
                shouldDescribe = true // Light change commands
            default:
                shouldDescribe = false
            }

            if shouldDescribe {
                try await describeCurrentLocation()
            }

        case .failure(let error):
            await report(parseError: error)
        }
    }

    /// Reports user-friendly messages for action responses (errors or simple feedback)
    /// to the player. This method is used internally by the engine to translate
    /// `ActionResponse` enum cases, often thrown or returned by `ActionHandler`
    /// validation or processing steps, into textual feedback for the player.
    ///
    /// It also logs more detailed information for certain critical errors like
    /// `.internalEngineError` or `.stateValidationFailed`.
    private func report(_ response: ActionResponse) async {
        // Determine the user-facing message
        let message = switch response {
        case .containerIsClosed(let item):
            "\(theThat(item).capitalizedFirst) is closed."
        case .containerIsOpen(let item):
            "\(theThat(item).capitalizedFirst) is already open."
        case .custom(let message):
            message
        case .directionIsBlocked(let reason):
            reason ?? "Something is blocking the way."
        case .internalEngineError:
            "A strange buzzing sound indicates something is wrong."
        case .invalidDirection:
            "You can't go that way."
        case .invalidIndirectObject(let objectName):
            "You can't use \(theThat(objectName)) for that."
        case .invalidValue:
            "A strange buzzing sound indicates something is wrong."
        case .itemAlreadyClosed(let item):
            "\(theThat(item).capitalizedFirst) is already closed."
        case .itemAlreadyOpen(let item):
            "\(theThat(item).capitalizedFirst) is already open."
        case .itemIsAlreadyWorn(let item):
            "You are already wearing \(theThat(item))."
        case .itemIsLocked(let item):
            "\(theThat(item).capitalizedFirst) is locked."
        case .itemIsNotWorn(let item):
            "You are not wearing \(theThat(item))."
        case .itemIsUnlocked(let item):
            "\(theThat(item).capitalizedFirst) is already unlocked."
        case .itemNotAccessible(let item):
            "You can't see \(anySuch(item))."
        case .itemNotClosable(let item):
            "\(theThat(item).capitalizedFirst) is not something you can close."
        case .itemNotDroppable(let item):
            "You can't drop \(theThat(item))."
        case .itemNotEdible(let item):
            "You can't eat \(theThat(item))."
        case .itemNotHeld(let item):
            "You aren't holding \(theThat(item))."
        case .itemNotInContainer(item: let item, container: let container):
            "\(theThat(item).capitalizedFirst) isn't in \(theThat(container))."
        case .itemNotLockable(let item):
            "You can't lock \(theThat(item))."
        case .itemNotOnSurface(item: let item, surface: let surface):
            "\(theThat(item).capitalizedFirst) isn't on \(theThat(surface))."
        case .itemNotOpenable(let item):
            "You can't open \(theThat(item))."
        case .itemNotReadable(let item):
            "\(theThat(item).capitalizedFirst) isn't something you can read."
        case .itemNotRemovable(let item):
            "You can't remove \(theThat(item))."
        case .itemNotTakable(let item):
            "You can't take \(theThat(item))."
        case .itemNotUnlockable(let item):
            "You can't unlock \(theThat(item))."
        case .itemNotWearable(let item):
            "You can't wear \(theThat(item))."
        case .itemTooLargeForContainer(item: let item, container: let container):
            "\(theThat(item).capitalizedFirst) won't fit in \(theThat(container))."
        case .playerCannotCarryMore:
            "Your hands are full."
        case .prerequisiteNotMet(let customMessage):
            customMessage.isEmpty ? "You can't do that." : customMessage
        case .roomIsDark:
            "It's too dark to do that."
        case .stateValidationFailed:
            "A strange buzzing sound indicates something is wrong with the state validation."
        case .targetIsNotAContainer(let item):
            "You can't put things in \(theThat(item))."
        case .targetIsNotASurface(let item):
            "You can't put things on \(theThat(item))."
        case .toolMissing(let tool):
            "You need \(tool) for that."
        case .unknownEntity:
            "You can't see any such thing."
        case .unknownVerb(let verb):
            "I don't know how to \"\(verb)\" something."
        case .wrongKey(keyID: let keyID, lockID: let lockID):
            "\(theThat(keyID).capitalizedFirst) doesn't fit \(theThat(lockID))."
        }
        await ioHandler.print(message)

        // Log detailed errors separately
        switch response {
        case .internalEngineError(let msg):
            logError("ActionResponse: Internal Engine Error: \(msg)")
        case .invalidValue(let msg):
            logError("ActionResponse: Invalid Value: \(msg)")
        case .stateValidationFailed(change: let change, actualOldValue: let actualOldValue):
            // Construct the log string first
            let logDetail = """
                State Validation Failed!
                   - Change: \(change.description.multiline(2))
                   - Expected Old Value: \(String(describing: change.oldValue))
                   - Actual Old Value: \(String(describing: actualOldValue))
                """
            logError("ActionResponse: \(logDetail)")
        default:
            break // No detailed logging needed for other handled errors
        }
    }

    /// Reports a parsing error to the player.
    /// This method is used internally by the engine to translate `ParseError` enum cases
    /// into textual feedback for the player when their input cannot be understood.
    /// For `.internalError` cases, it also logs detailed information.
    private func report(parseError: ParseError) async {
        let message = switch parseError {
        case .emptyInput:
            "I beg your pardon?"
        case .unknownVerb(let verb):
            "I don't know the verb '\(verb)'."
        case .unknownNoun(let noun):
            "I don't see any '\(noun)' here."
        case .itemNotInScope(let noun):
            "You can't see any '\(noun)' here."
        case .modifierMismatch(let noun, let modifiers):
            "I don't see any '\(modifiers.joined(separator: " ")) \(noun)' here."
        case .ambiguity(let text), .ambiguousPronounReference(let text):
            text
        case .badGrammar(let text):
            text
        case .pronounNotSet(let pronoun):
            "I don't know what '\(pronoun)' refers to."
        case .pronounRefersToOutOfScopeItem(let pronoun):
            "You can't see what '\(pronoun)' refers to right now."
        case .internalError:
            "A strange buzzing sound indicates something is wrong."
        }
        await ioHandler.print(message)
        if case .internalError(let details) = parseError {
            logError("ParseError: \(details)")
        }
    }

    /// Displays the status line (e.g., current location, score, and turn count)
    /// to the player via the `IOHandler`.
    /// This is called automatically at the start of each turn before `processTurn()`.
    private func showStatus() async {
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
            "the \(item.name)"
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
    /// This method is called automatically at the beginning of each player turn by `processTurn()`.
    /// It performs the following actions:
    /// 1. **Fuses**: Iterates through all `activeFuses` in `gameState`.
    ///    - Decrements the turn counter for each active fuse.
    ///    - If a fuse's counter reaches zero or less:
    ///        - Retrieves the corresponding `FuseDefinition` from the `timeRegistry`.
    ///        - Executes the fuse's `action` closure, passing the `GameEngine` instance.
    ///        - Removes the fuse from `activeFuses` in `gameState`.
    ///        - If the fuse's `repeats` flag is `true`, it reactivates the fuse by adding it
    ///          back to `activeFuses` with its `initialTurns` count.
    /// 2. **Daemons**: Iterates through all `activeDaemons` in `gameState`.
    ///    - Retrieves the corresponding `DaemonDefinition` from the `timeRegistry`.
    ///    - Executes the daemon's `action` closure, passing the `GameEngine` instance.
    ///
    /// Fuse and daemon actions can modify game state, print messages (by returning an `ActionResult`
    /// that the engine then processes), or even set `shouldQuit` to end the game.
    /// Errors during fuse/daemon definition lookup or action execution are logged.
    func tickClock() async {
        let currentTurn = gameState.player.moves

        // --- Process Fuses ---
        // Explicitly define the action type to match FuseDefinition.action
        typealias FuseActionType = @Sendable (GameEngine) async -> Void
        var expiredFuseIDsToExecute: [(id: FuseID, action: FuseActionType)] = []

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
            do {
                try gameState.apply(updateChange)
            } catch {
                print("TickClock Error: Failed to apply fuse turn update for \(fuseID): \(error)")
            }

            if newTurns <= 0 {
                guard let definition = timeRegistry.fuseDefinitions[fuseID] else {
                    print("TickClock Error: No FuseDefinition found for expiring fuse ID '\(fuseID)'. Cannot execute.")
                    let removeChangeOnError = StateChange(
                        entityID: .global,
                        attribute: .removeActiveFuse(fuseID: fuseID),
                        oldValue: .int(newTurns),
                        newValue: .int(0)
                    )
                    do {
                        try gameState.apply(removeChangeOnError)
                    } catch {
                        print("TickClock Error: Failed to apply fuse removal (on definition error) for \(fuseID): \(error)")
                    }
                    continue
                }
                expiredFuseIDsToExecute.append((id: fuseID, action: definition.action))

                let removeChange = StateChange(
                    entityID: .global,
                    attribute: .removeActiveFuse(fuseID: fuseID),
                    oldValue: .int(newTurns),
                    newValue: .int(0)
                )
                do {
                    try gameState.apply(removeChange)
                } catch {
                    print("TickClock Error: Failed to apply fuse removal for \(fuseID): \(error)")
                }
            }
        }

        // Execute actions of expired fuses AFTER all state changes for this tick's expirations are processed
        for fuseToExecute in expiredFuseIDsToExecute {
            await fuseToExecute.action(self)
            if shouldQuit { return }
        }

        // --- Process Daemons ---
        // Daemons are only checked against gameState.activeDaemons, no direct state change here.
        for daemonID in gameState.activeDaemons {
            // Get definition from registry
            guard let definition = timeRegistry.daemonDefinitions[daemonID] else {
                print("Warning: Active daemon '\(daemonID)' has no definition in registry. Skipping.")
                continue
            }

            // Check if it's time for this daemon to run based on frequency
            // Skip execution on turn 0 and run only on turns where currentTurn % frequency == 0
            if currentTurn > 0 && currentTurn % definition.frequency == 0 {
                // Execute the daemon's action
                await definition.action(self)
                if shouldQuit { return }
            }
        }
    }
}

// MARK: - Command Execution

extension GameEngine {
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
    ///
    /// Any `ActionResponse` errors thrown during this process are caught and reported to the player.
    /// Other errors are logged.
    ///
    /// - Parameter command: The `Command` object to execute.
    public func execute(command: Command) async {
        var actionHandled = false
        var actionResponse: Error? = nil // To store error from object handlers

        // --- Room BeforeTurn Hook ---
        let currentLocationID = playerLocationID
        if let locationHandler = locationEventHandlers[currentLocationID] {
            do {
                // Call handler, pass command using correct enum case syntax
                if let result = try await locationHandler.handle(
                    self,
                    LocationEvent.beforeTurn(command)
                ) {
                    // Room handler returned a result, process it
                    if try await processActionResult(result) {
                        return // Room handler handled everything
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

        // 1. Check Direct Object Handler
        if case .item(let doItemID) = command.directObject,
           let itemHandler = itemEventHandlers[doItemID]
        {
            do {
                // Pass the engine and the event to the handler
                if let result = try await itemHandler.handle(self, .beforeTurn(command)) {
                    // Object handler returned a result, process it
                    if try await processActionResult(result) {
                        return // Object handler handled everything
                    }
                }
            } catch let response {
                actionResponse = response
                actionHandled = true // Treat error as handled to prevent default handler
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
                        return // Object handler handled everything
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
                logWarning("""
                    An unexpected error occurred in an object handler: \
                    \(response)
                    """)
                await ioHandler.print("Sorry, something went wrong performing that action on the specific item.")
            }
        } else if !actionHandled {
            // No object handler took charge, check for darkness before running default verb handler

            let isLit = await playerLocationIsLit()

            // Retrieve verb definition to check requiresLight property
            // Note: Parser should ensure command.verbID exists in vocabulary
            // Correct: Look up the Verb definition directly
            guard let verb = gameState.vocabulary.verbDefinitions[command.verb] else {
                // This case should ideally not be reached if parser validates verbs
                logWarning("""
                    Internal Error: Unknown verb ID \
                    '\(command.verb.rawValue)' reached execution. \
                    If you encounter this error during testing, make sure to use \
                    `parse(input:vocabulary:gameState:)` to generate the command.
                    """)
                await ioHandler.print("I don't know how to '\(command.verb.rawValue)'.")
                return
            }

            // If the room is dark and the verb requires light (and isn't 'turn on'), report error.
            if !isLit && verb.requiresLight && command.verb != .turnOn {
                await report(.roomIsDark)
            } else {
                // Room is lit OR verb doesn't require light, proceed with default handler execution.
                guard let verbHandler = actionHandlers[command.verb] else {
                    // No handler registered for this verb (should match vocabulary definition)
                    logWarning("""
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
                        engine: self,
                        stateSnapshot: gameState.snapshot
                        // contextData is empty by default
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

        // 1. Check Direct Object AfterTurn Handler
        if case .item(let doItemID) = command.directObject,
           let itemHandler = itemEventHandlers[doItemID]
        {
            do {
                if let result = try await itemHandler.handle(self, .afterTurn(command)),
                   try await processActionResult(result) { return }
            } catch {
                logWarning("Error in direct object afterTurn handler: \(error)")
            }
            if shouldQuit { return }
        }

        // 2. Check Indirect Object AfterTurn Handler
        if case .item(let ioItemID) = command.indirectObject,
           let itemHandler = itemEventHandlers[ioItemID]
        {
            do {
                if let result = try await itemHandler.handle(self, .afterTurn(command)),
                   try await processActionResult(result) { return }
            } catch {
                logWarning("Error in indirect object afterTurn handler: \(error)")
            }
            if shouldQuit { return }
        }

        // --- Room AfterTurn Hook ---
        if let locationHandler = locationEventHandlers[currentLocationID] {
            do {
                // Call handler, ignore return value, use correct enum case syntax
                if let result = try await locationHandler.handle(
                    self,
                    LocationEvent.afterTurn(command)
                ),
                   try await processActionResult(result) { return }
            } catch {
                logWarning("Error in room afterTurn handler: \(error)")
            }
            // Check if handler quit the game
            if shouldQuit { return }
        }
    }

    /// Processes the result of an action, applying state changes and printing the message.
    ///
    /// This internal helper is called after an `ActionHandler` (or an event handler that
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
        for change in result.stateChanges {
            do {
                try await applyWithDynamicValidation(change)
            } catch {
                logError("""
                    Failed to apply state change during processActionResult:
                       - \(error)
                       - Change: \(change.description.multiline(2))
                    """)
                throw error // Re-throw the error to be caught by execute()
            }
        }

        // 2. Process Side Effects
        if !result.sideEffects.isEmpty {
            do {
                try await processSideEffects(result.sideEffects)
            } catch {
                logError("""
                    Failed to process side effects during processActionResult:
                       - \(error)
                       - Side Effects: \(result.sideEffects)
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
                throw ActionResponse.invalidValue("""
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
                throw ActionResponse.invalidValue("""
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
    /// Default action handlers provided by the engine.
    /// Games can override these via the `TimeRegistry`.
    static var defaultActionHandlers: [VerbID: ActionHandler] {
        var handlers: [VerbID: ActionHandler] = [
            // Movement & World Interaction
            .close: CloseActionHandler(),
            .drop: DropActionHandler(),
            .examine: ExamineActionHandler(),
            .give: GiveActionHandler(),
            .go: GoActionHandler(),
            .insert: InsertActionHandler(),
            .inventory: InventoryActionHandler(),
            .listen: ListenActionHandler(),
            .lock: LockActionHandler(),
            .look: LookActionHandler(),
            .open: OpenActionHandler(),
            .push: PushActionHandler(),
            .putOn: PutOnActionHandler(),
            .read: ReadActionHandler(),
            .remove: RemoveActionHandler(),
            .smell: SmellActionHandler(),
            .take: TakeActionHandler(),
            .taste: TasteActionHandler(),
            .thinkAbout: ThinkAboutActionHandler(),
            .touch: TouchActionHandler(),
            .turnOff: TurnOffActionHandler(),
            .turnOn: TurnOnActionHandler(),
            .unlock: UnlockActionHandler(),
            .wear: WearActionHandler(),
            .xyzzy: XyzzyActionHandler(),

            // Meta Actions
//            .brief: BriefActionHandler(),
//            .help: HelpActionHandler(),
            .quit: QuitActionHandler(),
//            .restore: RestoreActionHandler(),
//            .save: SaveActionHandler(),
            .score: ScoreActionHandler(),
//            .verbose: VerboseActionHandler(),
            .wait: WaitActionHandler(),
        ]

    #if DEBUG
        handlers[.debug] = DebugActionHandler()
    #endif
        return handlers
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

#if DEBUG

// MARK: - Internal State Mutation (Testing & Engine Use Only)

extension GameEngine {
    /// Applies a `StateChange` directly to the game state.
    ///
    /// > Important: **Internal/Test Use Only**: This method is provided for internal engine
    ///   operations and testing scenarios where direct state manipulation is necessary. Game
    ///   developers should use the action handler system (`ActionResult.stateChanges`) rather
    ///   than calling this method directly.
    ///
    /// This method bypasses the normal action handler pipeline, including:
    /// - Before/after turn event handlers
    /// - Action validation
    /// - Side effect processing
    ///
    /// Use this method only when:
    /// - Setting up test scenarios that require specific game states
    /// - Internal engine operations that need direct state access
    /// - Implementing low-level engine functionality
    ///
    /// - Parameter change: The `StateChange` to apply to the game state.
    /// - Throws: Re-throws any errors from `GameState.apply()`, including validation failures.
    func apply(_ change: StateChange) async throws {
        try await applyWithDynamicValidation(change)
    }

    /// Retrieves the complete history of all `StateChange`s applied to the `gameState`
    /// since the game started or the state was last loaded.
    ///
    /// This can be useful for debugging or advanced game mechanics that need to inspect
    /// past state transitions.
    ///
    /// - Returns: An array of `StateChange` objects, in the order they were applied.
    func changeHistory() -> [StateChange] {
        gameState.changeHistory
    }
}

#endif
