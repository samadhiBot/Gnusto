import Foundation
import OSLog
//import Markdown

/// The main orchestrator for the interactive fiction game.
/// This actor manages the game state, handles the game loop, interacts with the parser
/// and IO handler, and executes player commands using registered ActionHandlers.
public actor GameEngine: Sendable {
    /// The current state of the game world.
    public internal(set) var gameState: GameState

    /// The parser responsible for understanding player input.
    private let parser: Parser

    /// The handler for input and output operations.
    /// Use a nonisolated let for the IOHandler; calls to it must be await ioHandler.method().
    nonisolated internal let ioHandler: IOHandler

    /// The resolver for scope and visibility checks.
    lazy var scopeResolver: ScopeResolver = ScopeResolver(engine: self)

    /// The registry holding static game definitions (fuses, daemons, action overrides).
    public let definitionRegistry: DefinitionRegistry

    /// The registry for dynamic attribute computation and validation logic.
    public var dynamicAttributeRegistry: DynamicAttributeRegistry

    /// Registered handlers for specific verb commands.
    private var actionHandlers = [VerbID: ActionHandler]()

    /// A logger used for unhandled error warnings.
    let logger = Logger(subsystem: "GnustoEngine", category: "GameEngine")

    /// The maximum line length for description formatting.
    /// TODO: Make this configurable via init or GameBlueprint?
    private let maximumDescriptionLength: Int = 100

    /// Flag to control the main game loop.
    var shouldQuit: Bool = false

    // MARK: - Custom Game Hooks (Closures)

    /// Custom logic called after the player successfully enters a new location.
    ///
    /// The closure receives the engine and the ID of the location entered. It can modify the
    /// game state (e.g., change location properties based on player state). The closure returns
    /// `true` if the hook handled the situation, and no further action is required.
    public var onEnterRoom: (@Sendable (GameEngine, LocationID) async -> Bool)?

    /// Custom logic called at the very start of each turn, before command processing.
    ///
    /// The closure receives the engine and the command. It can modify game state or print messages
    /// based on the current state. The closure returns `true` if the hook handled the command,
    /// and no further action is required.
    public var beforeTurn: (@Sendable (GameEngine, Command) async -> Bool)?

    // MARK: - Initialization

    /// Creates a new `GameEngine` instance from a game definition.
    ///
    /// - Parameters:
    ///   - game: The game definition.
    ///   - parser: The command parser.
    ///   - ioHandler: The I/O handler for player interaction.
    public init(
        game: GameBlueprint,
        parser: Parser,
        ioHandler: IOHandler
    ) async {
        self.gameState = game.state
        self.parser = parser
        self.ioHandler = ioHandler
        self.definitionRegistry = game.definitionRegistry
        self.dynamicAttributeRegistry = game.dynamicAttributeRegistry
        self.actionHandlers = game.definitionRegistry.customActionHandlers
            .merging(Self.defaultActionHandlers) { (custom, _) in custom }
        self.onEnterRoom = game.onEnterRoom
        self.beforeTurn = game.beforeTurn
    }
}

// MARK: - Game Loop

extension GameEngine {
    /// Starts and runs the main game loop.
    public func run() async {
        await ioHandler.setup()
        await describeCurrentLocation() // Initial look

        while !shouldQuit {
            await showStatus()
            await processTurn()
        }

        await ioHandler.teardown()
    }

    // MARK: Private helpers

    private func anySuch(_ itemID: ItemID) -> String {
        if let item = item(itemID), item.hasFlag(.isTouched) {
            "the \(item.name)"
        } else {
            "any such thing"
        }
    }

    /// Processes a single turn of the game.
    private func processTurn() async {
        // --- Custom Hook: Before Turn ---
        // Moved hook call to *after* successful parsing
        // await beforeTurn?(self)
        // guard !shouldQuit else { return }
        // --------------------------------

        // --- Tick the Clock (Fuses & Daemons) ---
        await tickClock()
        guard !shouldQuit else { return } // Clock tick might trigger quit
                                          // -----------------------------------------

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
        let parseResult = parser.parse(input: input, vocabulary: vocabulary, gameState: gameState)

        // Increment turn counter AFTER clock tick and BEFORE command execution
        do {
            let oldMoves = gameState.player.moves
            let change = StateChange(
                entityID: .player,
                attributeKey: .playerMoves,
                oldValue: StateValue.int(oldMoves),
                newValue: StateValue.int(oldMoves + 1)
            )
            try gameState.apply(change)
        } catch {
            // Log error if applying the move increment fails (should be rare)
            print("Critical Error: Failed to apply player move increment state change: \(error)")
            // Depending on desired robustness, might want to halt or handle differently.
        }

        // 3. Execute Command or Handle Error
        switch parseResult {
        case .success(let command):
            // --- Custom Hook: Before Turn (called only on success) ---
            if await beforeTurn?(self, command) ?? false {
                return
            }
            guard !shouldQuit else {
                return // Hook might quit
            }
            await execute(command: command)

            // Describe location AFTER executing command if no error occurred during execution
            // (Errors are handled within execute/report)
            // Only describe if the command wasn't a quit command (already handled)
            // Also check if shouldQuit was set during execute
            if command.verbID != "quit" && !shouldQuit {
                // TODO: Only describe if the action *might* have changed the view
                // (e.g., movement, light change, taking/dropping items). LOOK already handles it.
                if command.verbID != "look" { // Avoid double-description for LOOK
                    await describeCurrentLocation()
                }
            }

        case .failure(let error):
            await report(parseError: error)
        }
    }

    /// Reports user-friendly messages for action failures to the player.
    private func report(actionError: ActionError) async {
        // Determine the user-facing message
        let message = switch actionError {
        case .containerIsClosed(let item):
            "\(theThat(item).capitalizedFirst) is closed."
        case .containerIsOpen(let item):
            "\(theThat(item).capitalizedFirst) is already open."
        case .customResponse(let message):
            message
        case .directionIsBlocked(let reason):
            reason ?? "Something is blocking the way."
        case .general(let message):
            message
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
        case .unknownItem(let item):
            "You can't see any \(item.rawValue) here."
        case .unknownVerb(let verb):
            "I don't know how to \"\(verb)\" something."
        case .wrongKey(keyID: let keyID, lockID: let lockID):
            "\(theThat(keyID).capitalizedFirst) doesn't fit \(theThat(lockID))."
        }
        await ioHandler.print(message)

        // Log detailed errors separately
        switch actionError {
        case .internalEngineError(let msg):
            logger.error("💥 ActionError: Internal Engine Error: \(msg, privacy: .public)")
        case .invalidValue(let msg):
            logger.error("💥 ActionError: Invalid Value: \(msg, privacy: .public)")
        case .stateValidationFailed(change: let change, actualOldValue: let actualOldValue):
            // Construct the log string first
            let logDetail = """
                State Validation Failed!
                    - Change: \(String(describing: change))
                    - Expected Old Value: \(String(describing: change.oldValue))
                    - Actual Old Value: \(String(describing: actualOldValue))
                """
            logger.error("💥 ActionError: \(logDetail, privacy: .public)")
        default:
            break // No detailed logging needed for other handled errors
        }
    }

    /// Reports a parsing error to the player.
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
            logger.error("💥 ParseError: \(details, privacy: .public)")
        }
    }

    /// Displays the status line.
    private func showStatus() async {
        guard let currentLocation = gameState.locations[gameState.player.currentLocationID] else { return }
        await ioHandler.showStatusLine(
            roomName: currentLocation.name,
            score: gameState.player.score,
            turns: gameState.player.moves
        )
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
        if let item = item(itemID) {
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
    /// Processes fuses and daemons for the current turn.
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
                oldValue: StateValue.int(currentTurns),
                newValue: StateValue.int(newTurns)
            )
            do {
                try gameState.apply(updateChange)
            } catch {
                print("TickClock Error: Failed to apply fuse turn update for \(fuseID): \(error)")
            }

            if newTurns <= 0 {
                guard let definition = definitionRegistry.fuseDefinition(for: fuseID) else {
                    print("TickClock Error: No FuseDefinition found for expiring fuse ID '\(fuseID)'. Cannot execute.")
                    let removeChangeOnError = StateChange(
                        entityID: .global,
                        attributeKey: .removeActiveFuse(fuseID: fuseID),
                        oldValue: StateValue.int(newTurns),
                        newValue: StateValue.int(0)
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
                    oldValue: StateValue.int(newTurns),
                    newValue: StateValue.int(0)
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
            guard let definition = definitionRegistry.daemonDefinition(for: daemonID) else {
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
    /// Looks up and executes the appropriate ActionHandler for the given command.
    /// - Parameter command: The command to execute.
    func execute(command: Command) async {
        var actionHandled = false
        var actionError: Error? = nil // To store error from object handlers

        // --- Room BeforeTurn Hook ---
        let currentLocationID = gameState.player.currentLocationID
        if let roomHandler = definitionRegistry.roomActionHandler(for: currentLocationID) {
            do {
                // Call handler, pass command using correct enum case syntax
                if try await roomHandler(self, RoomActionMessage.beforeTurn(command)) {
                    // Room handler blocked further action, return immediately.
                    // We don't increment moves or run afterTurn hook here.
                    return
                }
            } catch {
                // Log error and potentially halt turn?
                logger.warning("💥 Error in room beforeTurn handler: \(error, privacy: .public)")
                // Decide if this error should block the turn. For now, let's continue.
            }
            // Check if handler quit the game
            if shouldQuit { return }
        }

        // --- Try Object Action Handlers ---

        // 1. Check Direct Object Handler
        if let doID = command.directObject,
           let objectHandler = definitionRegistry.objectActionHandlers[doID]
        {
            do {
                // Pass the engine and the full command to the handler
                actionHandled = try await objectHandler(self, command)
            } catch {
                actionError = error // Store the error
                actionHandled = true // Treat error as handled to prevent default handler
            }
        }

        // 2. Check Indirect Object Handler (only if DO didn't handle it and no error occurred)
        // ZIL precedence: Often, if a DO routine handled it (or errored), the IO routine wasn't called.
        if !actionHandled, actionError == nil,
           let ioID = command.indirectObject,
           let objectHandler = definitionRegistry.objectActionHandlers[ioID]
        {
            do {
                actionHandled = try await objectHandler(self, command)
            } catch {
                actionError = error
                actionHandled = true
            }
        }

        // --- Execute Default Handler or Report Error ---

        if let error = actionError {
            // An object handler threw an error
            if let specificError = error as? ActionError {
                await report(actionError: specificError)
            } else {
                logger.warning("""
                    💥 An unexpected error occurred in an object handler: \
                    \(error, privacy: .public)
                    """)
                await ioHandler.print("Sorry, something went wrong performing that action on the specific item.")
            }
        } else if !actionHandled {
            // No object handler took charge, check for darkness before running default verb handler

            let isLit = await scopeResolver.isLocationLit(locationID: currentLocationID)

            // Retrieve verb definition to check requiresLight property
            // Note: Parser should ensure command.verbID exists in vocabulary
            // Correct: Look up the Verb definition directly
            guard let verb = gameState.vocabulary.verbDefinitions[command.verbID] else {
                // This case should ideally not be reached if parser validates verbs
                logger.warning("""
                    💥 Internal Error: Unknown verb ID \
                    '\(command.verbID.rawValue, privacy: .public)' reached execution.
                    """)
                await ioHandler.print("I don't know how to '\(command.verbID.rawValue)'.")
                return
            }

            // If the room is dark and the verb requires light (and isn't 'turn on'), report error.
            let isTurnOn = command.verbID == VerbID("turn on") // Special case for turning on lights
            if !isLit && verb.requiresLight && !isTurnOn {
                await report(actionError: .roomIsDark)
                // Do not proceed to execute the handler
            } else {
                // Room is lit OR verb doesn't require light, proceed with default handler execution.
                guard let verbHandler = actionHandlers[command.verbID] else {
                    // No handler registered for this verb (should match vocabulary definition)
                    logger.warning("""
                        💥 Internal Error: No ActionHandler registered for verb ID  \
                        '\(command.verbID.rawValue, privacy: .public)'.
                        """)
                    await ioHandler.print("I don't know how to '\(command.verbID.rawValue)'.")
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
                    try await processActionResult(result)

                    // Call postProcess (even if default is empty)
                    try await verbHandler.postProcess(context: context, result: result)

                } catch let actionErr as ActionError {
                    // Catch ActionError specifically for reporting
                    await report(actionError: actionErr)
                } catch {
                    // Catch any other unexpected errors from handlers
                    logger.error("💥 Unexpected error during handler execution: \(error)")
                    await ioHandler.print("An unexpected problem occurred.")
                }
                // --- End Execute Handler ---
            }
        }
        // If actionHandled is true and error is nil, the object handler succeeded silently (or printed its own msg).

        // --- Room AfterTurn Hook ---
        if let roomHandler = definitionRegistry.roomActionHandler(for: currentLocationID) {
            do {
                // Call handler, ignore return value, use correct enum case syntax
                _ = try await roomHandler(self, RoomActionMessage.afterTurn(command))
            } catch {
                logger.warning("💥 Error in room afterTurn handler: \(error, privacy: .public)")
            }
            // Check if handler quit the game
            if shouldQuit { return }
        }
    }

    /// Processes the result of an action, applying state changes and printing the message.
    ///
    /// - Parameter result: The `ActionResult` returned by an `ActionHandler`.
    /// - Throws: Re-throws errors encountered during state application.
    private func processActionResult(_ result: ActionResult) async throws {
        // 1. Apply State Changes
        // Errors during apply will propagate up.
        for change in result.stateChanges {
            do {
                try gameState.apply(change)
            } catch {
                logger.error("""
                    💥 Failed to apply state change during processActionResult:
                       - \(error, privacy: .public)
                       - Change: \(String(describing: change), privacy: .public)
                    """)
                throw error // Re-throw the error to be caught by execute()
            }
        }

        // 2. Print Result Message
        await ioHandler.print(result.message)

        // TODO: Handle SideEffects if they are added to ActionResult?
    }

}
