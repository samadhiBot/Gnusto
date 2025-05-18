import Foundation
import Logging

/// The main orchestrator for an interactive fiction game, responsible for managing
/// the game's state, running the primary game loop, and coordinating interactions
/// between the player (via an `IOHandler`), the command `Parser`, and the various
/// game logic handlers (`ActionHandler`, `ItemEventHandler`, `LocationEventHandler`).
///
/// As a Swift `actor`, `GameEngine` ensures safe access to the mutable `gameState`
/// from concurrent contexts, which is crucial for modern Swift concurrency.
///
/// Game developers typically interact with the `GameEngine` instance provided
/// within custom game logic closures (like those in `GameBlueprint` or event handlers).
/// Through this instance, developers can:
/// - Query the current `GameState` (e.g., find items, check locations).
/// - Initiate changes to the `GameState` by creating `StateChange` objects or using
///   convenience mutation methods.
/// - Access game-wide `GameConstants`.
/// - Trigger output to the player via the `IOHandler`.
public actor GameEngine: Sendable {
    /// The current, mutable state of the entire game world.
    ///
    /// This `GameState` object holds all information about locations, items, the player,
    /// active timers, and global variables. While action handlers and game hooks can
    /// read from this state directly (often via engine helper methods), modifications
    /// should be done by applying `StateChange` objects through the engine to ensure
    /// consistency and proper tracking.
    public internal(set) var gameState: GameState

    /// The parser responsible for interpreting raw player input strings into
    /// structured `Command` objects that the engine can understand and execute.
    /// This is primarily used internally by the engine during the game loop.
    private let parser: Parser

    /// The handler for all input and output operations, such as reading player commands
    /// and displaying game text. Game developers usually don't interact with this
    /// directly from handlers, as the engine provides higher-level methods for output
    /// (e.g., via `ActionResult.message`).
    nonisolated internal let ioHandler: IOHandler

    /// A utility to determine what items and locations are currently perceivable or
    /// interactable by the player, considering factors like light, containment, and reach.
    /// Game developers might use methods on the engine that internally leverage this resolver
    /// (e.g., `playerCanReach(_:)`).
    lazy var scopeResolver = ScopeResolver(engine: self)

    /// The game-specific constants, such as title, introduction, and maximum score,
    /// derived from the `GameBlueprint`.
    public let constants: GameConstants

    /// The registry holding definitions for timed events (`FuseDefinition`)
    /// and background processes (`DaemonDefinition`) provided by the `GameBlueprint`.
    /// The engine uses this to manage these time-based game mechanics.
    public let definitionRegistry: DefinitionRegistry

    /// The registry for custom logic that dynamically computes or validates item and
    /// location attributes, provided by the `GameBlueprint`.
    /// Developers can also register new handlers directly via engine methods like
    /// `registerItemCompute(key:handler:)`.
    public var dynamicAttributeRegistry: DynamicAttributeRegistry

    /// Registered `ActionHandler`s for specific verb commands (e.g., `.take`, `.look`).
    /// These are a combination of default engine handlers and custom handlers provided
    /// by the `GameBlueprint`.
    private var actionHandlers = [VerbID: ActionHandler]()

    /// Custom event handlers for specific items, triggered by events like `beforeTurn`
    /// or `afterTurn`, provided by the `GameBlueprint`.
    var itemEventHandlers: [ItemID: ItemEventHandler]

    /// Custom event handlers for specific locations, triggered by events like `onEnter`,
    /// `beforeTurn`, or `afterTurn`, provided by the `GameBlueprint`.
    var locationEventHandlers: [LocationID: LocationEventHandler]

    /// Internal logger for engine messages and warnings.
    let logger = Logger(label: "com.samadhibot.Gnusto.GameEngine")

    /// The maximum line length used for formatting descriptions.
    /// (Currently internal, may become configurable).
    private let maximumDescriptionLength: Int = 100

    /// Internal flag to control the main game loop's continuation.
    /// Game developers can call `requestQuit()` to set this.
    var shouldQuit: Bool = false

    // MARK: - Custom Game Hooks (Closures)

    /// A closure, provided by the `GameBlueprint`, that is called after the player
    /// successfully enters a new location.
    ///
    /// Use this to implement custom logic that should occur upon entering a room,
    /// such as triggering events, updating state, or describing unique features.
    /// The closure receives the `GameEngine` instance and the `LocationID` of the entered room.
    /// Return `true` if your hook fully handles the event (e.g., prints its own description)
    /// and the engine should not perform default processing for entering the room.
    public var onEnterRoom: (@Sendable (GameEngine, LocationID) async -> Bool)?

    /// A closure, provided by the `GameBlueprint`, that is called at the very start of
    /// each turn, before the player's `Command` is processed.
    ///
    /// Use this for per-turn logic like weather changes, NPC actions, or checking
    /// time-sensitive conditions. The closure receives the `GameEngine` instance and the
    /// current `Command`.
    /// Return `true` if your hook fully handles the command or pre-turn phase, and no
    /// further engine processing for the command should occur.
    public var beforeTurn: (@Sendable (GameEngine, Command) async -> Bool)?

    // MARK: - Initialization

    /// Creates a new `GameEngine` instance, configured by a `GameBlueprint`.
    ///
    /// This is typically called once at the start of the game to set up the engine
    /// with all game-specific data and logic.
    ///
    /// - Parameters:
    ///   - blueprint: The `GameBlueprint` containing all game definitions and initial state.
    ///   - parser: The `Parser` to be used for understanding player input.
    ///   - ioHandler: The `IOHandler` for interacting with the player.
    public init(
        blueprint: GameBlueprint,
        parser: Parser,
        ioHandler: IOHandler
    ) async {
        self.constants = blueprint.constants
        self.gameState = blueprint.state
        self.parser = parser
        self.ioHandler = ioHandler
        self.definitionRegistry = blueprint.definitionRegistry
        self.dynamicAttributeRegistry = blueprint.dynamicAttributeRegistry
        self.actionHandlers = blueprint.customActionHandlers
            .merging(Self.defaultActionHandlers) { (custom, _) in custom }
        self.itemEventHandlers = blueprint.itemEventHandlers
        self.locationEventHandlers = blueprint.locationEventHandlers
        self.onEnterRoom = blueprint.onEnterRoom
        self.beforeTurn = blueprint.beforeTurn

        #if DEBUG
        self.actionHandlers[.debug] = DebugActionHandler()
        #endif
    }
}

// MARK: - Game Loop

extension GameEngine {
    /// Starts and runs the main game loop.
    ///
    /// This method initiates the game: it sets up the I/O handler, displays initial
    /// game information (title, introduction), describes the starting location, and then
    /// enters a loop to process player turns. Each turn involves:
    ///   - Showing the status line.
    ///   - Processing timed events (fuses and daemons via `tickClock()`).
    ///   - Reading and parsing player input.
    ///   - Executing the parsed command (including `beforeTurn` hooks, item/location event
    ///     handlers, and the main `ActionHandler` for the verb).
    ///
    /// The loop continues until `shouldQuit` becomes `true` (e.g., via `requestQuit()`
    /// or a "quit" command). Game developers typically don't call this method directly;
    /// it's the entry point for running the game.
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
            logger.error("💥 \(error)")
        }

        while !shouldQuit {
            await showStatus()
            do {
                try await processTurn()
            } catch {
                logger.error("💥 \(error)")
            }
        }

        await ioHandler.teardown()
    }

    // MARK: Private helpers

    /// Processes a single turn of the game.
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
                attributeKey: .playerMoves,
                oldValue: .int(moves),
                newValue: .int(moves + 1)
            )
        )

        // 3. Execute Command or Handle Error
        switch parseResult {
        case .success(let command):
            // --- Custom Hook: Before Turn ---
            if await beforeTurn?(self, command) == true || shouldQuit {
                return
            }

            if command.verb == .quit || shouldQuit { return }

            // Handle location description after movement or light change
            let shouldDescribe: Bool
            switch command.verb {
            case .go:
                // Check if the destination room was visited before the movement
                let exit = try command.direction.flatMap { direction in
                    try location(playerLocationID).exits[direction]
                }
                shouldDescribe = if let destination = try? location(exit?.destinationID) {
                    !destination.hasFlag(.isVisited)
                } else {
                    false
                }
            case .turnOn, .turnOff:
                shouldDescribe = true // Light change commands
            default:
                shouldDescribe = false
            }

            await execute(command: command)

            if command.verb == .quit || shouldQuit { return }

            if shouldDescribe {
                try await describeCurrentLocation()
            }

        case .failure(let error):
            await report(parseError: error)
        }
    }

    /// Reports user-friendly messages for action responses to the player.
    /// This method is used internally by the engine to translate `ActionResponse`
    /// enum cases (often returned by `ActionHandler` validation or processing steps)
    /// into textual feedback for the player.
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
            logger.error("💥 ActionResponse: Internal Engine Error: \(msg)")
        case .invalidValue(let msg):
            logger.error("💥 ActionResponse: Invalid Value: \(msg)")
        case .stateValidationFailed(change: let change, actualOldValue: let actualOldValue):
            // Construct the log string first
            let logDetail = """
                State Validation Failed!
                    - Change: \(String(describing: change))
                    - Expected Old Value: \(String(describing: change.oldValue))
                    - Actual Old Value: \(String(describing: actualOldValue))
                """
            logger.error("💥 ActionResponse: \(logDetail)")
        default:
            break // No detailed logging needed for other handled errors
        }
    }

    /// Reports a parsing error to the player.
    /// This method is used internally by the engine to translate `ParseError` enum cases
    /// into textual feedback for the player when input cannot be understood.
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
            logger.error("💥 ParseError: \(details)")
        }
    }

    /// Displays the status line (e.g., current location, score, and turn count)
    /// to the player via the `IOHandler`.
    /// This is called automatically at the start of each turn.
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
    /// Processes all active fuses (timed events) and daemons (recurring actions)
    /// for the current game turn.
    ///
    /// This method is called automatically by the engine at the start of each turn.
    /// It updates fuse counters, executes expired fuse actions, and runs daemon actions
    /// based on their defined frequency. Game developers typically don't call this
    /// method directly; they define fuses and daemons in the `GameBlueprint`.
    private func tickClock() async {
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
                attributeKey: .updateFuseTurns(fuseID: fuseID),
                oldValue: .int(currentTurns),
                newValue: .int(newTurns)
            )
            do {
                try gameState.apply(updateChange)
            } catch {
                print("TickClock Error: Failed to apply fuse turn update for \(fuseID): \(error)")
            }

            if newTurns <= 0 {
                guard let definition = definitionRegistry.fuseDefinitions[fuseID] else {
                    print("TickClock Error: No FuseDefinition found for expiring fuse ID '\(fuseID)'. Cannot execute.")
                    let removeChangeOnError = StateChange(
                        entityID: .global,
                        attributeKey: .removeActiveFuse(fuseID: fuseID),
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
                    attributeKey: .removeActiveFuse(fuseID: fuseID),
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
            guard let definition = definitionRegistry.daemonDefinitions[daemonID] else {
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
    /// Looks up and executes the appropriate `ActionHandler` for the given command.
    ///
    /// This is the core of command processing. It involves several steps:
    ///   - Invoking `beforeTurn` hooks for the current location and specific items.
    ///   - If not handled by a hook, checking for darkness if the verb requires light.
    ///   - Executing the `validate`, `process`, and `postProcess` steps of the relevant
    ///     `ActionHandler` for the command's verb.
    ///   - Processing the `ActionResult` (applying state changes, printing messages).
    ///   - Invoking `afterTurn` hooks for items and the location.
    ///
    /// Game developers typically don't call this directly; it's part of the internal
    /// game loop (`processTurn`).
    func execute(command: Command) async {
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
                logger.warning("💥 Error in room beforeTurn handler: \(error)")
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
                logger.warning("""
                    💥 An unexpected error occurred in an object handler: \
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
                logger.warning("""
                    💥 Internal Error: Unknown verb ID \
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
                    logger.warning("""
                        💥 Internal Error: No ActionHandler registered for verb ID \
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
                    logger.error("💥 Unexpected error during handler execution: \(error)")
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
                logger.warning("💥 Error in direct object afterTurn handler: \(error)")
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
                logger.warning("💥 Error in indirect object afterTurn handler: \(error)")
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
                logger.warning("💥 Error in room afterTurn handler: \(error)")
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
    private func processActionResult(_ result: ActionResult) async throws -> Bool {
        // 1. Apply State Changes
        // Errors during apply will propagate up.
        for change in result.stateChanges {
            do {
                try gameState.apply(change)
            } catch {
                logger.error("""
                    💥 Failed to apply state change during processActionResult:
                       - \(error)
                       - Change: \(String(describing: change))
                    """)
                throw error // Re-throw the error to be caught by execute()
            }
        }

        // 2. Print Result Message
        if let message = result.message {
            await ioHandler.print(message)
            return true
        } else {
            return false
        }

        // TODO: Handle SideEffects if they are added to ActionResult?
    }
}
