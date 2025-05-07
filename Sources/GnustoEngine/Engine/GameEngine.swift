import Foundation
import OSLog
import Markdown

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
    private let logger = Logger(subsystem: "GnustoEngine", category: "GameEngine")

    /// The maximum line length for description formatting.
    /// TODO: Make this configurable via init or GameBlueprint?
    private let maximumDescriptionLength: Int = 100

    /// Flag to control the main game loop.
    private var shouldQuit: Bool = false

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

    // MARK: - Game Loop

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
        let parseResult = await parser.parse(input: input, vocabulary: vocabulary, gameState: gameState)

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

    // MARK: - Clock Tick Logic

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

    // MARK: - Command Execution

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
           let objectHandler = definitionRegistry.objectActionHandlers[doID] {
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
        if !actionHandled, actionError == nil, let ioID = command.indirectObject,
           let objectHandler = definitionRegistry.objectActionHandlers[ioID] {
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
                        stateSnapshot: await gameState.snapshot
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

    // MARK: - State Change & Side Effect Application

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

    /// Applies a single state change to the game state by forwarding to the central `GameState.apply` method.
    /// - Parameter change: The `StateChange` to apply.
    /// - Parameter gameState: The GameState instance to modify (passed as inout).
    /// - Throws: An error if the change cannot be applied (forwarded from `GameState.apply`).
    private func applyStateChange(_ change: StateChange, gameState: inout GameState) throws {
        // Forward directly to GameState's apply method, modifying the inout parameter.
        try gameState.apply(change)
    }

    /// Processes a single side effect, potentially triggering StateChanges.
    /// - Parameter effect: The `SideEffect` to process.
    /// - Throws: An error if processing the side effect fails (e.g., definition not found, apply fails).
    private func processSideEffect(_ effect: SideEffect, gameState: inout GameState) throws {
        switch effect.type {
        case .startFuse:
            guard
                let definition = definitionRegistry.fuseDefinition(
                    for: try effect.targetID.fuseID()
                )
            else {
                throw ActionError.internalEngineError("""
                    No FuseDefinition found for fuse ID '\(effect.targetID)' \
                    in startFuse side effect.
                    """)
            }
            let initialTurns = effect.parameters["turns"]?.toInt ?? definition.initialTurns
            let addChange = StateChange(
                entityID: .global,
                attributeKey:
                    .addActiveFuse(
                        fuseID: definition.id,
                        initialTurns: initialTurns
                    ),
                oldValue: gameState.activeFuses[definition.id].map { .int($0) },
                newValue: StateValue.int(initialTurns)
            )
            try gameState.apply(addChange)

        case .stopFuse:
            let fuseID = try effect.targetID.fuseID()
            let oldTurns = gameState.activeFuses[fuseID]
            let removeChange = StateChange(
                entityID: .global,
                attributeKey: .removeActiveFuse(fuseID: fuseID),
                oldValue: oldTurns.map { StateValue.int($0) },
                newValue: StateValue.int(0)
            )
            try gameState.apply(removeChange)

        case .runDaemon:
            let daemonID = try effect.targetID.daemonID()
            guard definitionRegistry.daemonDefinition(for: daemonID) != nil else {
                throw ActionError.internalEngineError("""
                    No DaemonDefinition found for daemon ID '\(daemonID)' \
                    in runDaemon side effect.
                    """)
            }
            if !gameState.activeDaemons.contains(daemonID) {
                try gameState.apply(
                    StateChange(
                        entityID: .global,
                        attributeKey: .addActiveDaemon(daemonID: daemonID),
                        oldValue: false,
                        newValue: true
                    )
                )
            }

        case .stopDaemon:
            let daemonID = try effect.targetID.daemonID()
            if gameState.activeDaemons.contains(daemonID) {
                try gameState.apply(
                    StateChange(
                        entityID: .global,
                        attributeKey: .removeActiveDaemon(daemonID: daemonID),
                        oldValue: true,
                        newValue: false
                    )
                )
            }

        case .scheduleEvent:
            // For scheduleEvent, effect.targetID (EntityID) can be used directly
            // without needing to convert it to a definition key.
            // The actual scheduling logic would go here.
            print("Warning: SideEffectType.scheduleEvent for target '\(effect.targetID)' not yet fully implemented.")
        }
    }

    // MARK: - Output & Error Reporting

    /// Displays the description of the current location, considering light level.
    internal func describeCurrentLocation() async {
        let locationID = gameState.player.currentLocationID

        // 1. Check for light
        let isLitResult = await scopeResolver.isLocationLit(locationID: locationID)
        guard isLitResult else {
            // It's dark!
            await ioHandler.print("It is pitch black. You are likely to be eaten by a grue.")
            // Do not describe the room or list items.
            return
        }

        // 2. If lit, get snapshot and print name
        guard let location = location(with: locationID) else {
            logger.warning("💥 Error: Current location snapshot not found!")
            return
        }
        await ioHandler.print("--- \(location.name) ---", style: .strong)

        // 3. Generate and print the description using the DescriptionHandlerRegistry
        let description = await generateDescription(
            for: location.id,
            key: .longDescription,
            engine: self
        )
        await ioHandler.print(description)

        // 4. List visible items
        await listItemsInLocation(locationID: locationID)
    }

    /// Helper to list items visible in a location (only called if lit).
    private func listItemsInLocation(locationID: LocationID) async {
        // 1. Get visible item IDs using ScopeResolver
        let visibleItemIDs = await scopeResolver.visibleItemsIn(locationID: locationID)

        // 2. Asynchronously fetch Item objects/snapshots for the visible IDs
        let visibleItems = visibleItemIDs.compactMap(item(_:))

        // 3. Format and print the list if not empty
        if !visibleItems.isEmpty {
            // Use the helper to generate a sentence like "a foo, a bar, and a baz"
            let itemListing = visibleItems.listWithIndefiniteArticles
            await ioHandler.print("You can see \(itemListing) here.")
        }
        // No output if no items are visible
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

    /// Reports user-friendly messages for action failures to the player.
    private func report(actionError: ActionError) async {
        // Determine the user-facing message
        let message = switch actionError {
        case .containerIsClosed(let item):
            "\(theThat(item).capitalizedFirst) is closed."
        case .containerIsFull(let item):
            "\(theThat(item).capitalizedFirst) is full."
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
            "The \(item(keyID)?.name ?? keyID.rawValue) doesn't fit \(theThat(lockID))."
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

    private func anySuch(_ itemID: ItemID) -> String {
        if let item = item(itemID), item.hasFlag(.isTouched) {
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

    // MARK: - State Query Helpers (Public API for Handlers/Hooks)

    /// Retrieves the current state of a specific location.
    /// - Parameter id: The `LocationID` of the location to retrieve.
    /// - Returns: A `Location` struct if the location is found, otherwise `nil`.
    public func location(with id: LocationID) -> Location? {
        gameState.locations[id]
    }

    /// Retrieves the current state of a specific item.
    /// - Parameter id: The `ItemID` of the item to retrieve.
    /// - Returns: An `Item` struct if the item is found, otherwise `nil`.
    public func item(_ id: ItemID) -> Item? {
        gameState.items[id]
    }

    /// Retrieves the current state of all items with a specific parent.
    /// - Parameter parent: The `ParentEntity` to filter items by.
    /// - Returns: An array of `Item` structs for items with the specified parent.
    public func items(in parent: ParentEntity) -> [Item] {
        gameState.items.values
            .filter { $0.parent == parent }
    }

    // MARK: - State Mutation Helpers (Public API for Handlers/Hooks)

    /// Sets a global flag by applying a `.setFlag` state change.
    /// Logs a warning and returns if the state change application fails.
    /// Does nothing if the flag is already set.
    ///
    /// - Parameter id: The `FlagID` of the flag to set.
    public func setFlag(_ id: FlagID) async {
        // Only apply if the flag isn't already set
        if !gameState.flags.contains(id) {
            let change = StateChange(
                entityID: .global,
                attributeKey: .setFlag(id),
                oldValue: false, // Expecting it was false
                newValue: true,
            )
            do {
                try gameState.apply(change)
            } catch {
                logger.warning("""
                    💥 Failed to apply .setFlag change for '\(id.rawValue, privacy: .public)': \
                    \(error, privacy: .public)
                    """)
            }
        }
    }

    /// Clears a global flag by applying a `.clearFlag` state change.
    /// Logs a warning and returns if the state change application fails.
    /// Does nothing if the flag is already clear.
    ///
    /// - Parameter id: The `FlagID` of the flag to clear.
    public func clearFlag(_ id: FlagID) async {
        // Only apply if the flag is currently set
        if gameState.flags.contains(id) {
            let change = StateChange(
                entityID: .global,
                attributeKey: .clearFlag(id),
                oldValue: true, // Expecting it was true
                newValue: false
            )
            do {
                try gameState.apply(change)
            } catch {
                logger.warning("""
                    💥 Failed to apply .clearFlag change for \
                    '\(id.rawValue, privacy: .public)': \(error, privacy: .public)
                    """)
            }
        }
    }

    /// Updates the pronoun reference (e.g., "it") to point to a specific item.
    ///
    /// - Parameters:
    ///   - pronoun: The pronoun (e.g., "it").
    ///   - itemID: The ItemID the pronoun should refer to.
    public func applyPronounChange(pronoun: String, itemID: ItemID) async {
        let newSet: Set<ItemID> = [itemID]
        let oldSet = gameState.pronouns[pronoun]

        if oldSet != newSet {
            let change = StateChange(
                entityID: .global,
                attributeKey: .pronounReference(pronoun: pronoun),
                oldValue: oldSet.map { .itemIDSet($0) },
                newValue: .itemIDSet(newSet)
            )
            do {
                try gameState.apply(change)
            } catch {
                logger.warning("""
                    💥 Failed to apply pronoun change for '\(pronoun, privacy: .public)': \
                    \(error, privacy: .public)
                    """)
            }
        }
    }

    /// Moves an item to a new parent entity.
    ///
    /// - Parameters:
    ///   - itemID: The unique identifier of the item to move.
    ///   - newParent: The target parent entity.
    public func applyItemMove(itemID: ItemID, newParent: ParentEntity) async {
        guard let moveItem = item(itemID) else {
            logger.warning(
                "💥 Cannot move non-existent item '\(itemID.rawValue, privacy: .public)'."
            )
            return
        }
        let oldParent = moveItem.parent

        // Check if destination is valid (e.g., Location exists)
        if case .location(let locID) = newParent {
            guard location(with: locID) != nil else {
                logger.warning("""
                    💥 Cannot move item '\(itemID.rawValue, privacy: .public)' to \
                    non-existent location '\(locID.rawValue, privacy: .public)'.
                    """)
                return
            }
        } else if case .item(let containerID) = newParent {
             guard item(containerID) != nil else {
                 logger
                     .warning("""
                        💥 Cannot move item '\(itemID.rawValue, privacy: .public)' into \
                        non-existent container '\(containerID.rawValue, privacy: .public)'.
                        """)
                return
            }
            // TODO: Add container capacity check?
        }

        if oldParent != newParent {
            let change = StateChange(
                entityID: .item(itemID),
                attributeKey: .itemParent,
                oldValue: .parentEntity(oldParent),
                newValue: .parentEntity(newParent)
            )
            do {
                try gameState.apply(change)
            } catch {
                logger.warning("""
                    💥 Failed to apply item move for '\(itemID.rawValue, privacy: .public)': \
                    \(error, privacy: .public)
                    """)
            }
        }
    }

    /// Moves the player to a new location.
    ///
    /// - Parameter newLocationID: The unique identifier of the destination location.
    public func applyPlayerMove(to newLocationID: LocationID) async {
        let oldLocationID = gameState.player.currentLocationID

        // Check if destination is valid
        guard location(with: newLocationID) != nil else {
            logger
                .warning("""
                    💥 Cannot move player to non-existent location \
                    '\(newLocationID.rawValue, privacy: .public)'.
                    """)
            return
        }

        if oldLocationID != newLocationID {
            let change = StateChange(
                entityID: .player,
                attributeKey: .playerLocation,
                oldValue: .locationID(oldLocationID),
                newValue: .locationID(newLocationID)
            )
            do {
                try gameState.apply(change)

                // --- Trigger onEnterRoom Hook --- (Moved from changePlayerLocation)
                if let hook = onEnterRoom {
                    if await hook(self, newLocationID) {
                        // Hook handled everything, potentially quit game.
                        return
                    }
                }

            } catch {
                logger.warning("""
                    💥 Failed to apply player move to \
                    '\(newLocationID.rawValue, privacy: .public)': \(error, privacy: .public)
                    """)
            }
        }
    }

    /// Retrieves the full change history.
    ///
    /// - Returns: An array of `StateChange` objects.
    public func getChangeHistory() -> [StateChange] {
        gameState.changeHistory
    }

    /// Signals the engine to stop the main game loop after the current turn.
    public func requestQuit() {
        self.shouldQuit = true
    }

    /// Retrieves the current set of item IDs referenced by a pronoun.
    ///
    /// - Parameter pronoun: The pronoun string (e.g., "it").
    /// - Returns: The set of `ItemID`s the pronoun refers to, or `nil` if not set.
    public func getPronounReference(pronoun: String) -> Set<ItemID>? {
        gameState.pronouns[pronoun.lowercased()]
    }

    /// Retrieves the value of a game-specific state variable.
    ///
    /// - Parameter key: The key (`GameStateKey`) for the game-specific state variable.
    /// - Returns: The `StateValue` if found, otherwise `nil`.
    public func getStateValue(key: GameStateID) -> StateValue? {
        gameState.gameSpecificState[key]
    }

    /// Applies a change to a game-specific state variable.
    ///
    /// - Parameters:
    ///   - key: The key (`GameStateKey`) for the game-specific state.
    ///   - value: The new `StateValue`.
    public func applyGameSpecificStateChange(key: GameStateID, value: StateValue) async {
        let oldValue = gameState.gameSpecificState[key] // Read using GameStateKey

        // Only apply if the value is changing
        if value != oldValue {
            let change = StateChange( // Add explicit type
                entityID: .global,
                attributeKey: .gameSpecificState(key: key), // Use GameStateKey
                oldValue: oldValue, // Pass the existing StateValue? as oldValue
                newValue: value
            )
            do {
                try gameState.apply(change)
            } catch {
                logger.warning("""
                    💥 Failed to apply game specific state change for key \
                    '\(key.rawValue, privacy: .public)': \(error, privacy: .public)
                    """)
            }
        }
    }

    /// Checks if a specific global flag is currently set.
    ///
    /// - Parameter id: The `FlagID` to check.
    /// - Returns: `true` if the flag is present in the `GameState.flags` set, `false` otherwise.
    public func isFlagSet(_ id: FlagID) -> Bool {
        gameState.flags.contains(id)
    }
}

// MARK: - Player State Accessors

extension GameEngine {

    /// The player's current score.
    public var playerScore: Int {
        gameState.player.score
    }

    /// The number of turns the player has taken.
    public var playerMoves: Int {
        gameState.player.moves
    }

    /// Checks if the player can carry a given item based on their current inventory weight and capacity.
    /// - Parameter item: The item to check.
    /// - Returns: `true` if the player can carry the item, `false` otherwise.
    public func playerCanCarry(_ item: Item) -> Bool {
        let currentWeight = gameState.player.currentInventoryWeight(allItems: gameState.items)
        let capacity = gameState.player.carryingCapacity
        return (currentWeight + item.size) <= capacity
    }
}

// MARK: - Dynamic Attribute Accessors

extension GameEngine {

    /// Retrieves the current value of a potentially dynamic item property.
    /// Checks the `DynamicAttributeRegistry` for a compute handler first.
    /// If no handler exists, returns the value stored in the item's `attributes`.
    ///
    /// - Parameters:
    ///   - itemID: The unique identifier of the item.
    ///   - key: The `AttributeID` of the desired value.
    /// - Returns: The computed or stored `StateValue`, or `nil` if the item or value doesn't exist.
        private func getDynamicItemValue(itemID: ItemID, key: AttributeID) async -> StateValue? {
        guard let item = await gameState.items[itemID] else {
            logger.warning("""
                💥 Attempted to get dynamic value '\(key.rawValue)' for non-existent item: \
                \(itemID.rawValue)
                """)
            return nil
        }

        // Check registry for compute handler
        if let computeHandler = await dynamicAttributeRegistry.itemComputeHandler(for: key) {
            do {
                return try await computeHandler(item, gameState)
            } catch {
                logger.error("""
                    💥 Error computing dynamic value '\(key.rawValue)' \
                    for item \(itemID.rawValue): \(error)
                    """)
                // Fall through to return stored value or nil? Or return nil on error? Let's return nil.
                return nil
            }
        } else {
            // No compute handler, return stored value
            return item.attributes[key]
        }
    }

    /// Retrieves the current value of a potentially dynamic location property.
    /// (Implementation mirrors getDynamicItemValue)
    ///
    /// - Parameters:
    ///   - locationID: The unique identifier of the location.
    ///   - key: The `AttributeID` of the desired value.
    /// - Returns: The computed or stored `StateValue`, or `nil` if the location or value doesn't exist.
        private func getDynamicLocationValue(locationID: LocationID, key: AttributeID) async -> StateValue? {
        guard let location = await gameState.locations[locationID] else {
            logger.warning("""
                💥 Attempted to get dynamic value '\(key.rawValue)' \
                for non-existent location: \(locationID.rawValue)
                """)
            return nil
        }

        if let computeHandler = await dynamicAttributeRegistry.locationComputeHandler(for: key) {
            do {
                return try await computeHandler(location, gameState)
            } catch {
                logger.error("""
                    💥 Error computing dynamic value '\(key.rawValue)' \
                    for location \(locationID.rawValue): \(error)
                    """)
                return nil
            }
        } else {
            return location.attributes[key]
        }
    }

    /// Sets the value of an item property, performing validation via the `DynamicAttributeRegistry` if applicable.
    /// Creates and applies the appropriate `StateChange` if validation passes.
    ///
    /// - Parameters:
    ///   - itemID: The unique identifier of the item to modify.
    ///   - key: The `AttributeID` of the value to set.
    ///   - newValue: The new `StateValue`.
    /// - Throws: An `ActionError` if the item doesn't exist, validation fails, or state application fails.
    public func setDynamicItemValue(itemID: ItemID, key: AttributeID, newValue: StateValue) async throws {
        guard let item = await gameState.items[itemID] else {
            throw ActionError.internalEngineError("Attempted to set dynamic value '\(key.rawValue)' for non-existent item: \(itemID.rawValue)")
        }

        // Check registry for validate handler
        if let validateHandler = await dynamicAttributeRegistry.itemValidateHandler(for: key) {
            do {
                let isValid = try await validateHandler(item, newValue)
                if !isValid {
                    // Use a generic invalid value error, or could the handler throw a more specific one?
                    // For now, use invalidValue.
                    throw ActionError.invalidValue("Validation failed for dynamic item value '\(key.rawValue)' on \(itemID.rawValue): \(newValue)")
                }
            } catch {
                // If validator throws, propagate the error
                logger.error("""
                    💥 Error validating dynamic value '\(key.rawValue)' \
                    for item \(itemID.rawValue): \(error)
                    """)
                throw error
            }
        }

        // Validation passed (or no validator), proceed with StateChange
        let oldValue = item.attributes[key] // Get current value for oldValue

        // Only apply if value is actually changing
        if oldValue != newValue {
            let change = StateChange(
                entityID: .item(itemID),
                attributeKey: .itemAttribute(key), // Use the new key
                oldValue: oldValue,
                newValue: newValue
            )
            // Directly apply to gameState (we are already async)
            try gameState.apply(change)
        }
    }

    /// Sets the value of a location property, performing validation.
    /// (Implementation mirrors setDynamicItemValue)
    ///
    /// - Parameters:
    ///   - locationID: The unique identifier of the location to modify.
    ///   - key: The `AttributeID` of the value to set.
    ///   - newValue: The new `StateValue`.
    /// - Throws: An `ActionError` if the location doesn't exist, validation fails, or state application fails.
    public func setDynamicLocationValue(locationID: LocationID, key: AttributeID, newValue: StateValue) async throws {
        guard let location = await gameState.locations[locationID] else {
            throw ActionError.internalEngineError("Attempted to set dynamic value '\(key.rawValue)' for non-existent location: \(locationID.rawValue)")
        }

        if let validateHandler = await dynamicAttributeRegistry.locationValidateHandler(for: key) {
            do {
                let isValid = try await validateHandler(location, newValue)
                if !isValid {
                    throw ActionError.invalidValue("Validation failed for dynamic location value '\(key.rawValue)' on \(locationID.rawValue): \(newValue)")
                }
            } catch {
                logger.error("""
                    💥 Error validating dynamic value '\(key.rawValue)' \
                    for location \(locationID.rawValue): \(error)
                    """)
                throw error
            }
        }

        let oldValue = location.attributes[key]

        if oldValue != newValue {
            let change = StateChange(
                entityID: .location(locationID),
                attributeKey: .locationAttribute(key), // Use the new key
                oldValue: oldValue,
                newValue: newValue
            )
            // Directly apply to gameState (we are already async)
            try gameState.apply(change)
        }
    }

    public func fetch(_ itemID: ItemID, _ key: AttributeID) async throws -> Bool {
        let value = await getDynamicItemValue(itemID: itemID, key: key)
        switch value {
        case .bool(let boolValue):
            return boolValue
        case nil:
            return false
        default:
            throw ActionError.invalidValue("""
                Cannot fetch boolean value for \(itemID.rawValue).\(key.rawValue): \
                \(value ?? .undefined)
                """)
        }
    }

    public func fetch(_ itemID: ItemID, _ key: AttributeID) async throws -> Int {
        let value = await getDynamicItemValue(itemID: itemID, key: key)
        switch value {
        case .int(let intValue):
            return intValue
        default:
            throw ActionError.invalidValue("""
                Cannot fetch integer value for \(itemID.rawValue).\(key.rawValue): \
                \(value ?? .undefined)
                """)
        }
    }

    public func fetch(_ itemID: ItemID, _ key: AttributeID) async throws -> String {
        let value = await getDynamicItemValue(itemID: itemID, key: key)
        switch value {
        case .string(let stringValue):
            return stringValue
        default:
            throw ActionError.invalidValue("""
                Cannot fetch string value for \(itemID.rawValue).\(key.rawValue): \
                \(value ?? .undefined)
                """)
        }
    }

    public func fetch(_ locationID: LocationID, _ key: AttributeID) async throws -> String {
        let value = await getDynamicLocationValue(locationID: locationID, key: key)
        switch value {
        case .string(let stringValue):
            return stringValue
        default:
            throw ActionError.invalidValue("""
                Cannot fetch string value for \(locationID.rawValue).\(key.rawValue): \
                \(value ?? .undefined)
                """)
        }
    }
}

// MARK: - Registration Methods (Items)

extension GameEngine {
    /// Registers a compute handler for a specific item property.
    /// If a handler already exists for this key, it will be overwritten.
    /// - Parameters:
    ///   - key: The `AttributeID` of the property.
    ///   - handler: The closure to execute for computing the value.
    public func registerItemCompute(
        key: AttributeID,
        handler: @escaping DynamicAttributeRegistry.ItemComputeHandler
    ) {
        dynamicAttributeRegistry.registerItemCompute(key: key, handler: handler)
    }

    /// Registers a validation handler for a specific item property.
    /// If a handler already exists for this key, it will be overwritten.
    /// - Parameters:
    ///   - key: The `AttributeID` of the property.
    ///   - handler: The closure to execute for validating a new value.
    public func registerItemValidate(
        key: AttributeID,
        handler: @escaping DynamicAttributeRegistry.ItemValidateHandler
    ) {
        dynamicAttributeRegistry.registerItemValidate(key: key, handler: handler)
    }

    // MARK: - Registration Methods (Locations)

    /// Registers a compute handler for a specific location property.
    public func registerLocationCompute(
        key: AttributeID,
        handler: @escaping DynamicAttributeRegistry.LocationComputeHandler
    ) {
        dynamicAttributeRegistry.registerLocationCompute(key: key, handler: handler)
    }

    /// Registers a validation handler for a specific location property.
    public func registerLocationValidate(
        key: AttributeID,
        handler: @escaping DynamicAttributeRegistry.LocationValidateHandler
    ) {
        dynamicAttributeRegistry.registerLocationValidate(key: key, handler: handler)
    }
}
