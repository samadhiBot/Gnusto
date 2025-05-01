import Foundation
import OSLog

/// The main orchestrator for the interactive fiction game.
/// This actor manages the game state, handles the game loop, interacts with the parser
/// and IO handler, and executes player commands using registered ActionHandlers.
@MainActor
public class GameEngine: Sendable {
    /// The current state of the game world.
    public internal(set) var gameState: GameState

    /// The parser responsible for understanding player input.
    private let parser: Parser

    /// The handler for input and output operations.
    /// Use a nonisolated let for the IOHandler; calls to it must be await ioHandler.method().
    nonisolated internal let ioHandler: IOHandler

    /// The resolver for scope and visibility checks.
    lazy var scopeResolver: ScopeResolver = ScopeResolver(engine: self)

    /// The registry holding static game definitions (fuses, daemons, etc.).
    public let registry: DefinitionRegistry

    /// The registry for dynamic description handlers.
    public let descriptionHandlerRegistry: DescriptionHandlerRegistry

    /// Registered handlers for specific verb commands.
    private var actionHandlers = [VerbID: EnhancedActionHandler]()

    /// Active timed events (Fuses) - Runtime storage with closures.
    private var activeFuses = [FuseID: Fuse]()

    /// A logger used for unhandled error warnings.
    private let logger = Logger(subsystem: "GnustoEngine", category: "GameEngine")

    /// Flag to control the main game loop.
    private var shouldQuit: Bool = false

    // MARK: - Custom Game Hooks (Closures)

    /// Custom logic called after the player successfully enters a new location.
    ///
    /// The closure receives the engine and the ID of the location entered. It can modify the
    /// game state (e.g., change location properties based on player state). The closure returns
    /// `true` if the hook handled the situation, and no further action is required.
    public var onEnterRoom: (@MainActor @Sendable (GameEngine, LocationID) async -> Bool)?

    /// Custom logic called at the very start of each turn, before command processing.
    ///
    /// The closure receives the engine and the command. It can modify game state or print messages
    /// based on the current state. The closure returns `true` if the hook handled the command,
    /// and no further action is required.
    public var beforeTurn: (@MainActor @Sendable (GameEngine, Command) async -> Bool)?

    // MARK: - Default Handlers

    /// Default action handlers provided by the engine.
    /// Games can override these via the `DefinitionRegistry`.
    private static let defaultActionHandlers: [VerbID: EnhancedActionHandler] = [
        // Movement & World Interaction
        "close": CloseActionHandler(),
        "examine": ExamineActionHandler(),
        "go": GoActionHandler(),
        "insert": InsertActionHandler(),
        "lock": LockActionHandler(),
        "look": LookActionHandler(),
        "open": OpenActionHandler(),
        "put-on": PutOnActionHandler(),
        "unlock": UnlockActionHandler(),

        // Inventory Management
        "drop": DropActionHandler(),
        "inventory": InventoryActionHandler(),
        "remove": RemoveActionHandler(),
        "take": TakeActionHandler(),
        "wear": WearActionHandler(),

        // Other Actions
        "listen": ListenActionHandler(),
        "read": ReadActionHandler(),
        "smell": SmellActionHandler(),
        "taste": TasteActionHandler(),
        "think": ThinkAboutActionHandler(),
        "touch": TouchActionHandler(),
        "turn off": TurnOffActionHandler(),
        "turn on": TurnOnActionHandler(),
        "wait": WaitActionHandler(),

        // Meta Actions
        "quit": QuitActionHandler(),
        "score": ScoreActionHandler(),

        // TODO: Add more default handlers (Attack, Read, Eat, Drink, etc.)
    ]

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
    ) {
        self.gameState = game.state
        self.parser = parser
        self.ioHandler = ioHandler
        self.registry = game.registry
        self.descriptionHandlerRegistry = DescriptionHandlerRegistry()
        self.actionHandlers = game.registry.customActionHandlers
            .merging(Self.defaultActionHandlers) { (custom, _) in custom }
        self.onEnterRoom = game.onEnterRoom
        self.beforeTurn = game.beforeTurn

        var fuses: [Fuse.ID: Fuse] = [:]
        for (fuseID, turnsRemaining) in game.state.activeFuses {
            guard let definition = registry.fuseDefinition(for: fuseID) else {
                print("Warning: No FuseDefinition found for saved fuse ID '\(fuseID)'. Skipping.")
                continue
            }
            let runtimeFuse = Fuse(id: fuseID, turns: turnsRemaining, action: definition.action)
            fuses[fuseID] = runtimeFuse
        }
        self.activeFuses = fuses
    }

    // MARK: - Fuse & Daemon Management (Runtime Only)

    /// Adds or updates a fuse in the ENGINE'S RUNTIME state based on its definition.
    /// Does NOT modify persistent GameState.
    /// If a fuse with the same ID already exists, its timer is reset.
    private func updateRuntimeFuse(
        id: FuseID,
        overrideTurns: Int? = nil
    ) throws {
        // Find definition
        guard let definition = registry.fuseDefinition(for: id) else {
            throw ActionError.internalEngineError("No FuseDefinition found for fuse ID '\(id)'. Cannot update runtime fuse.")
        }
        // Determine turns
        let turns = overrideTurns ?? definition.initialTurns
        // Create/update runtime instance
        let runtimeFuse = Fuse(id: id, turns: turns, action: definition.action)
        self.activeFuses[id] = runtimeFuse
    }

    /// Removes a fuse from the ENGINE'S RUNTIME state by its ID.
    /// Does NOT modify persistent GameState.
    private func removeRuntimeFuse(id: FuseID) {
        self.activeFuses.removeValue(forKey: id)
    }

    // Note: Daemons do not currently have separate runtime state managed by the engine,
    // they operate directly based on the gameState.activeDaemons set each tick.
    // Therefore, registerDaemon and unregisterDaemon helpers are no longer needed.

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
        let parseResult = parser.parse(input: input, vocabulary: vocabulary, gameState: gameState)

        // Increment turn counter AFTER clock tick and BEFORE command execution
        do {
            let oldMoves = gameState.player.moves
            let change = StateChange(
                entityId: .player,
                propertyKey: .playerMoves,
                oldValue: .int(oldMoves),
                newValue: .int(oldMoves + 1)
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
        var expiredFuseIDs: [FuseID] = []
        var fusesToExecute: [Fuse] = []

        // Create a copy of keys to iterate over, allowing safe modification
        // Need to iterate over the runtime activeFuses managed by the engine
        let runtimeFuseIDs = Array(self.activeFuses.keys)

        for id in runtimeFuseIDs {
            guard var fuse = self.activeFuses[id] else { continue } // Check runtime fuse
            let oldTurns = fuse.turnsRemaining

            fuse.turnsRemaining -= 1
            let newTurns = fuse.turnsRemaining

            // Update runtime fuse state immediately
            self.activeFuses[id] = fuse

            // Create StateChange to update persistent state
            let updateChange = StateChange(
                entityId: .global,
                propertyKey: .updateFuseTurns(fuseId: id),
                oldValue: .int(oldTurns),
                newValue: .int(newTurns)
            )
            do {
                try gameState.apply(updateChange)
            } catch {
                print("TickClock Error: Failed to apply fuse turn update for \(id): \(error)")
                // Consider how to handle this failure - continue or halt?
            }

            if newTurns <= 0 {
                expiredFuseIDs.append(id)
                fusesToExecute.append(fuse)

                // Create StateChange to remove from persistent state
                let removeChange = StateChange(
                    entityId: .global,
                    propertyKey: .removeActiveFuse(fuseId: id),
                    oldValue: .int(oldTurns),
                    newValue: .int(0)
                )
                do {
                    try gameState.apply(removeChange)
                } catch {
                    print("TickClock Error: Failed to apply fuse removal for \(id): \(error)")
                    // Consider how to handle this failure
                }
            }
            // Removed direct modification of gameState.activeFuses
        }

        // Remove expired fuses from ENGINE'S runtime dictionary *before* executing actions
        // Persistent state removal is handled by the StateChange above
        for id in expiredFuseIDs {
            self.activeFuses.removeValue(forKey: id)
        }

        // Execute actions of expired fuses
        for fuse in fusesToExecute {
            await fuse.action(self)
            if shouldQuit { return }
        }

        // --- Process Daemons ---
        // Daemons are only checked against gameState.activeDaemons, no direct state change here.
        for daemonID in gameState.activeDaemons {
            // Get definition from registry
            guard let definition = registry.daemonDefinition(for: daemonID) else {
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
        if let roomHandler = registry.roomActionHandler(for: currentLocationID) {
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
           let objectHandler = registry.objectActionHandlers[doID] {
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
           let objectHandler = registry.objectActionHandlers[ioID] {
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
                logger.warning("💥 An unexpected error occurred in an object handler: \(error, privacy: .public)")
                await ioHandler.print("Sorry, something went wrong performing that action on the specific item.")
            }
        } else if !actionHandled {
            // No object handler took charge, check for darkness before running default verb handler

            let isLit = scopeResolver.isLocationLit(locationID: currentLocationID)

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
                    // Directly use the enhanced handler pipeline
                    try await verbHandler.validate(command: command, engine: self)
                    let result = try await verbHandler.process(command: command, engine: self)

                    // Process the result (apply changes, print message)
                    try await processActionResult(result)

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
        if let roomHandler = registry.roomActionHandler(for: currentLocationID) {
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
    /// - Parameter result: The `ActionResult` returned by an `EnhancedActionHandler`.
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
        let fuseId = effect.targetId.rawValue // Assuming targetId is FuseID for fuse effects
        let daemonId = effect.targetId.rawValue // Assuming targetId is DaemonID for daemon effects

        switch effect.type {
        case .startFuse:
            // 1. Get definition to find initial turns
            guard let definition = registry.fuseDefinition(for: fuseId) else {
                throw ActionError.internalEngineError("No FuseDefinition found for fuse ID '\(fuseId)' in startFuse side effect.")
            }
            // 2. Determine turns (use parameter if provided, else definition)
            let initialTurns: Int
            if case .int(let t)? = effect.parameters["turns"] {
                initialTurns = t
            } else {
                initialTurns = definition.initialTurns
            }
            // 3. Create StateChange to add to persistent state
            let addChange = StateChange(
                entityId: .global,
                propertyKey: .addActiveFuse(fuseId: fuseId, initialTurns: initialTurns),
                // No oldValue for add
                newValue: .int(initialTurns) // The value being set
            )
            // 4. Apply the StateChange
            try gameState.apply(addChange)
            // 5. Update the engine's runtime fuse state
            try updateRuntimeFuse(id: fuseId, overrideTurns: initialTurns)

        case .stopFuse:
            // 1. Get current turns from persistent state for oldValue validation
            let oldTurns = gameState.activeFuses[fuseId]
            // 2. Create StateChange to remove from persistent state
            let removeChange = StateChange(
                entityId: .global,
                propertyKey: .removeActiveFuse(fuseId: fuseId),
                oldValue: oldTurns != nil ? .int(oldTurns!) : nil,
                newValue: .int(0)
            )
            // 3. Apply the StateChange
            try gameState.apply(removeChange)
            // 4. Remove from engine's runtime fuse state
            removeRuntimeFuse(id: fuseId)

        case .runDaemon:
            // 1. Check definition exists (required for daemon execution later)
            guard registry.daemonDefinition(for: daemonId) != nil else {
                throw ActionError.internalEngineError("No DaemonDefinition found for daemon ID '\(daemonId)' in runDaemon side effect.")
            }
            // 2. Check if already active in persistent state
            let isAlreadyActive = gameState.activeDaemons.contains(daemonId)
            // 3. Create StateChange only if not already active
            if !isAlreadyActive {
                let addDaemonChange = StateChange(
                    entityId: .global,
                    propertyKey: .addActiveDaemon(daemonId: daemonId),
                    oldValue: .bool(false), // Explicitly stating it wasn't present
                    newValue: .bool(true) // Representing the state of being active
                )
                // 4. Apply the StateChange
                try gameState.apply(addDaemonChange)
            }

        case .stopDaemon:
            // 1. Check if active in persistent state for oldValue validation
            let wasActive = gameState.activeDaemons.contains(daemonId)
            // 2. Create StateChange only if it was active
            if wasActive {
                let removeDaemonChange = StateChange(
                    entityId: .global,
                    propertyKey: .removeActiveDaemon(daemonId: daemonId),
                    oldValue: .bool(true), // Explicitly stating it was present
                    newValue: .bool(false) // Representing the state of being inactive
                )
                // 3. Apply the StateChange
                try gameState.apply(removeDaemonChange)
            }

        case .scheduleEvent:
            print("Warning: SideEffectType.scheduleEvent not yet implemented.")
        }
    }

    // MARK: - Output & Error Reporting

    /// Displays the description of the current location, considering light level.
    internal func describeCurrentLocation() async {
        let locationID = gameState.player.currentLocationID

        // 1. Check for light
        let isLitResult = scopeResolver.isLocationLit(locationID: locationID)
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

        // 3. Generate and print the description using the handler
        if let descriptionHandler = location.longDescription {
            let description = await descriptionHandlerRegistry.generateDescription(
                for: location,
                using: descriptionHandler,
                engine: self
            )
            await ioHandler.print(description)
        } else {
            // Fallback if no description handler is set
            await ioHandler.print("You are in \(location.name).") // Default message
        }

        // 4. List visible items
        await listItemsInLocation(locationID: locationID)
    }

    /// Helper to list items visible in a location (only called if lit).
    private func listItemsInLocation(locationID: LocationID) async {
        // 1. Get visible item IDs using ScopeResolver
        let visibleItemIDs = scopeResolver.visibleItemsIn(locationID: locationID)

        // 2. Get the actual Item objects/snapshots for the visible IDs
        let visibleItems = visibleItemIDs.compactMap { gameState.items[$0] } // Fetch full Item objects

        if !visibleItems.isEmpty {
            await ioHandler.print("You can see:")
            for itemID in visibleItemIDs {
                // TODO: Fetch actual item state for description if needed
                if let item = item(with: itemID) {
                    if let fdesc = item.firstDescription { // Placeholder for FDESC logic
                        ioHandler.print(await fdesc.generate(item, self), style: .itemDescription)
                    } else if let sdesc = item.shortDescription { // Default to short description
                        ioHandler.print(await sdesc.generate(item, self), style: .itemDescription)
                    }
                }
            }
        }
    }

    /// Displays the status line.
    private func showStatus() async {
        guard let currentLocation = gameState.locations[gameState.player.currentLocationID] else { return }
        await ioHandler.showStatusLine(
            roomName: currentLocation.name,
            score: gameState.player.score, // Use actual score/turns
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
        case .itemNotCloseable(let item):
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
        case .playerCannotCarryMore:
            "Your hands are full."
        case .prerequisiteNotMet(let customMessage):
            customMessage.isEmpty ? "You can't do that." : customMessage
        case .roomIsDark:
            "It's too dark to do that."
        case .targetIsNotAContainer(let item):
            "You can't put things in \(theThat(item))."
        case .targetIsNotASurface(let item):
            "You can't put things on \(theThat(item))."
        case .toolMissing(let tool):
            "You need \(tool) for that."
        case .unknownVerb(let verb):
            "I don't know how to \"\(verb)\" something."
        case .wrongKey(keyID: let keyID, lockID: let lockID):
            "The \(item(with: keyID)?.name ?? keyID.rawValue) doesn't fit \(theThat(lockID))."
        }
        await ioHandler.print(message)

        if case .internalEngineError(let msg) = actionError {
            logger.error("💥 ActionError: \(msg, privacy: .public)")
        }
    }

    private func anySuch(_ itemID: ItemID) -> String {
        if let item = item(with: itemID), item.hasProperty(.touched) {
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
        if let item = item(with: itemID) {
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
    public func item(with id: ItemID) -> Item? {
        gameState.items[id]
    }

    /// Retrieves the current state of all items with a specific parent.
    /// - Parameter parent: The `ParentEntity` to filter items by.
    /// - Returns: An array of `Item` structs for items with the specified parent.
    public func items(withParent parent: ParentEntity) -> [Item] {
        gameState.items.values
            .filter { $0.parent == parent }
    }

    // MARK: - State Mutation Helpers (Public API for Handlers/Hooks)

    /// Applies a change to a specific item's properties.
    /// This creates and applies the necessary `StateChange`.
    /// It logs an error and returns if the item doesn't exist or the change fails.
    ///
    /// - Parameters:
    ///   - itemID: The ID of the item to modify.
    ///   - adding: A set of properties to add (optional).
    ///   - removing: A set of properties to remove (optional).
    public func applyItemPropertyChange(
        itemID: ItemID,
        adding: Set<ItemProperty> = [],
        removing: Set<ItemProperty> = []
    ) async {
        guard let item = item(with: itemID) else {
            logger
                .warning("""
                    💥 Cannot apply property change to non-existent item \
                    '\(itemID.rawValue, privacy: .public)'.
                    """)
            return
        }
        let oldProps = item.properties
        var newProps = oldProps
        newProps.formUnion(adding)
        newProps.subtract(removing)

        // Only apply if there's an actual change
        if oldProps != newProps {
            let change = StateChange(
                entityId: .item(itemID),
                propertyKey: .itemProperties,
                oldValue: .itemProperties(oldProps),
                newValue: .itemProperties(newProps)
            )
            do {
                try gameState.apply(change)
            } catch {
                logger.warning("""
                    💥 Failed to apply item property change for \
                    '\(itemID.rawValue, privacy: .public)': \(error, privacy: .public)
                    """)
            }
        }
    }

    /// Applies a change to a global flag.
    ///
    /// - Parameters:
    ///   - flag: The key of the flag to set.
    ///   - value: The new boolean value for the flag.
    public func applyFlagChange(flag: String, value: Bool) async {
        let oldValue = gameState.flags[flag]
        // Only apply if value is actually changing
        if oldValue != value {
            let change = StateChange(
                entityId: .global,
                propertyKey: .globalFlag(key: flag),
                oldValue: oldValue != nil ? .bool(oldValue!) : nil,
                newValue: .bool(value)
            )
            do {
                try gameState.apply(change)
            } catch {
                logger
                    .warning("""
                        💥 Failed to apply flag change for '\(flag, privacy: .public)': \
                        \(error, privacy: .public)
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
                entityId: .global,
                propertyKey: .pronounReference(pronoun: pronoun),
                oldValue: oldSet != nil ? .itemIDSet(oldSet!) : nil,
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
    ///   - itemID: The ID of the item to move.
    ///   - newParent: The target parent entity.
    public func applyItemMove(itemID: ItemID, newParent: ParentEntity) async {
        guard let item = item(with: itemID) else {
            logger
                .warning("💥 Cannot move non-existent item '\(itemID.rawValue, privacy: .public)'.")
            return
        }
        let oldParent = item.parent

        // Check if destination is valid (e.g., Location exists)
        if case .location(let locID) = newParent {
            guard location(with: locID) != nil else {
                logger
                    .warning("""
                        💥 Cannot move item '\(itemID.rawValue, privacy: .public)' to \
                        non-existent location '\(locID.rawValue, privacy: .public)'.
                        """
                    )
                return
            }
        } else if case .item(let containerID) = newParent {
             guard item(with: containerID) != nil else {
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
                entityId: .item(itemID),
                propertyKey: .itemParent,
                oldValue: .parentEntity(oldParent),
                newValue: .parentEntity(newParent)
            )
            do {
                try gameState.apply(change)
            } catch {
                logger.warning("💥 Failed to apply item move for '\(itemID.rawValue, privacy: .public)': \(error, privacy: .public)")
            }
        }
    }

    /// Moves the player to a new location.
    ///
    /// - Parameter newLocationID: The ID of the destination location.
    public func applyPlayerMove(to newLocationID: LocationID) async {
        let oldLocationID = gameState.player.currentLocationID

        // Check if destination is valid
        guard location(with: newLocationID) != nil else {
            logger
                .warning(
                    "💥 Cannot move player to non-existent location '\(newLocationID.rawValue, privacy: .public)'."
                )
            return
        }

        if oldLocationID != newLocationID {
            let change = StateChange(
                entityId: .player,
                propertyKey: .playerLocation,
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
                logger
                    .warning(
                        "💥 Failed to apply player move to '\(newLocationID.rawValue, privacy: .public)': \(error, privacy: .public)"
                    )
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
    /// - Parameter key: The key for the game-specific state variable.
    /// - Returns: The `AnyCodable` value if found, otherwise `nil`.
    public func getGameSpecificStateValue(forKey key: String) -> AnyCodable? {
        gameState.gameSpecificState[key]
    }

    /// Applies a change to a specific location's properties.
    ///
    /// - Parameters:
    ///   - locationID: The ID of the location to modify.
    ///   - adding: A set of properties to add (optional).
    ///   - removing: A set of properties to remove (optional).
    public func applyLocationPropertyChange(
        locationID: LocationID,
        adding: Set<LocationProperty> = [],
        removing: Set<LocationProperty> = []
    ) async {
        guard let location = location(with: locationID) else {
            logger
                .warning("""
                    💥 Cannot apply property change to non-existent location \
                    '\(locationID.rawValue, privacy: .public)'.
                    """)
            return
        }
        let oldProps = location.properties
        var newProps = oldProps
        newProps.formUnion(adding)
        newProps.subtract(removing)

        if oldProps != newProps {
            let change = StateChange(
                entityId: .location(locationID),
                propertyKey: .locationProperties,
                oldValue: .locationProperties(oldProps),
                newValue: .locationProperties(newProps)
            )
            do {
                try gameState.apply(change)
            } catch {
                logger.warning("""
                    💥 Failed to apply location property change for \
                    '\(locationID.rawValue, privacy: .public)': \(error, privacy: .public)
                    """)
            }
        }
    }

    /// Applies a change to a game-specific state variable.
    /// Only supports simple types (Bool, Int, String) via AnyCodable.
    ///
    /// - Parameters:
    ///   - key: The key for the game-specific state.
    ///   - value: The new value (Bool, Int, or String).
    public func applyGameSpecificStateChange(key: String, value: StateValue) async {
        // Note: StateValue should be .bool, .int, or .string for this
        let oldValue = gameState.gameSpecificState[key]
        let actualOldValue: StateValue? // Convert AnyCodable back for comparison if possible
        if let oldAny = oldValue {
            if let v = oldAny.value as? Bool { actualOldValue = .bool(v) }
            else if let v = oldAny.value as? Int { actualOldValue = .int(v) }
            else if let v = oldAny.value as? String { actualOldValue = .string(v) }
            else { actualOldValue = nil } // Cannot represent complex type
        } else {
            actualOldValue = nil
        }

        // Only apply if the value is changing (and types are compatible)
        if value != actualOldValue {
            let change = StateChange(
                entityId: .global,
                propertyKey: .gameSpecificState(key: key),
                oldValue: actualOldValue, // Pass converted old value for validation
                newValue: value
            )
            do {
                try gameState.apply(change)
            } catch {
                logger.warning("💥 Failed to apply game specific state change for '\(key, privacy: .public)': \(error, privacy: .public)")
            }
        }
    }

    /// Retrieves the value of a global flag.
    ///
    /// - Parameter key: The key of the flag to retrieve.
    /// - Returns: The boolean value of the flag, or `false` if not set.
    public func getFlagValue(key: String) -> Bool {
        gameState.flags[key] ?? false
    }

    /// Retrieves the optional value of a global flag.
    ///
    /// - Parameter key: The key of the flag to retrieve.
    /// - Returns: The boolean value of the flag if set, otherwise `nil`.
    public func getOptionalFlagValue(key: String) -> Bool? {
        gameState.flags[key]
    }

    // TODO: Add helpers for score/move updates if needed by standard ActionHandlers?

    // MARK: - Scope Resolution Delegation

    /// Finds items directly visible to the player in their current location.
    public func itemsVisibleInCurrentLocation(excludeScenery: Bool = false) async -> [ItemID] {
        await scopeResolver.itemsVisibleInLocation(
            locationID: gameState.player.currentLocationID, // Use gameState.player.currentLocationID
            engine: self,
            excludeScenery: excludeScenery
        )
    }

    /// Finds items potentially reachable by the player (inventory, visible location items).
    public func itemsReachableByPlayer() async -> [ItemID] {
        await scopeResolver.itemsReachableByPlayer(engine: self)
    }

    /// Checks if the player can currently see a specific item.
    public func canPlayerSeeItem(itemID: ItemID) async -> Bool {
        guard let item = await item(with: itemID) else { return false } // Use item(with:)
        return await scopeResolver.canPlayerSeeItem(item: item, engine: self)
    }

    /// Checks if an item is directly or indirectly inside a container.
    public func isItem(_ itemID: ItemID, inside containerID: ItemID) async -> Bool {
        guard await item(with: itemID) != nil else { return false } // Use item(with:)
        var currentParent = await self.itemParent(itemID)
        while case .item(let parentID) = currentParent {
            if parentID == containerID { return true }
            // Check if the container we found actually exists before continuing up the chain
            guard await item(with: parentID) != nil else { return false } // Use item(with:)
            currentParent = await self.itemParent(parentID)
        }
        return false
    }

    /// Finds the outermost container of an item, or the location ID if it's not in a container.
    public func ultimateParent(of itemID: ItemID) async -> ParentEntity {
        guard let initialParent = await itemParent(itemID) else { return .nowhere } // Should exist if item exists
        var currentParent = initialParent
        while case .item(let parentID) = currentParent {
            // Check if the container we found actually exists before continuing up the chain
            guard let nextParent = await itemParent(parentID) else {
                // If parent doesn't exist, treat the last valid container as ultimate parent
                // Or if the initial item wasn't in a container, return its parent.
                return currentParent
            }
            // Stop if we hit .nowhere or a .location
            guard case .item = nextParent else { return nextParent }
            currentParent = nextParent
        }
        return currentParent // Will be .location(id), .player, or .nowhere
    }

    /// Checks if the player's current location is lit.
    public func isCurrentLocationLit() async -> Bool {
        guard let location = await location(with: gameState.player.currentLocationID) else { return false } // Use location(with:) and gameState.player.currentLocationID
        return await scopeResolver.isLocationLit(location: location, engine: self)
    }

    /// Checks if a specific location is lit.
    public func isLocationLit(locationID: LocationID) async -> Bool {
        guard let location = await location(with: locationID) else { return false } // Use location(with:)
        return await scopeResolver.isLocationLit(location: location, engine: self)
    }

    /// Checks if an item is considered scenery (usually fixed, non-interactive elements).
    public func isScenery(itemID: ItemID) async -> Bool {
        guard let item = await item(with: itemID) else { return false } // Use item(with:)
        return item.hasProperty(.scenery)
    }

    /// Checks if an item is currently worn by the player.
    public func isWorn(itemID: ItemID) async -> Bool {
        guard let item = await item(with: itemID) else { return false } // Use item(with:)
        return item.parent == .player && item.hasProperty(.worn)
    }

    /// Checks if a container is open.
    public func isOpen(containerID: ItemID) async -> Bool {
        guard let item = await item(with: containerID) else { return false } // Use item(with:)
        // Ensure it's actually a container before checking open status
        return item.hasProperty(.container) && item.hasProperty(.open)
    }

    /// Gets the total size/weight of items currently held by the player.
    public func currentInventoryWeight() async -> Int {
        gameState.player.currentInventoryWeight(allItems: gameState.items)
    }

    /// Checks if the player can carry an item of the given size.
    public func canPlayerCarry(itemSize: Int) async -> Bool {
        let currentWeight = await currentInventoryWeight()
        let playerCapacity = gameState.player.carryingCapacity
        return (currentWeight + itemSize) <= playerCapacity
    }

    /// Checks if an item ID refers to an existing item.
    public func itemExists(itemID: ItemID) async -> Bool {
        await item(with: itemID) != nil // Use item(with:)
    }

    /// Checks if a location ID refers to an existing location.
    public func locationExists(locationID: LocationID) async -> Bool {
        await location(with: locationID) != nil // Use location(with:)
    }

    private func lookInLocation(_ location: Location) async {
        let description = await description(for: location)
        ioHandler.print(description, style: .locationDescription)

        // Describe visible items (not scenery/globals)
        let visibleItems = await scopeResolver.itemsVisibleInLocation(
            locationID: location.id,
            engine: self,
            excludeScenery: true
        )

        if !visibleItems.isEmpty {
            // TODO: Add Zork-style grouping ("There is a KEY and a LAMP here.")
            // TODO: Handle FDESC (first description)
            for itemID in visibleItems {
                // TODO: Fetch actual item state for description if needed
                if let item = await item(with: itemID) {
                    if let fdesc = item.firstDescription { // Placeholder for FDESC logic
                        ioHandler.print(await fdesc.generate(item, self), style: .itemDescription)
                    } else if let sdesc = item.shortDescription { // Default to short description
                        ioHandler.print(await sdesc.generate(item, self), style: .itemDescription)
                    }
                }
            }
        }
    }

    // MARK: - Actor Method Implementation

    public nonisolated func run() async throws {
        // Initial setup - show starting location description
        // Use gameState.player.currentLocationID and location(with:)
        if let startLocation = await location(with: gameState.player.currentLocationID) {
            await showLocationDescription(location: startLocation)
        } else {
            throw ActionError.internalEngineError("Initial player location ID '\\(gameState.player.currentLocationID)' is invalid.")
        }

        // ... existing code ...

        // 1. Check if the location exists
        // Use location(with:) instead of location(with:)
        guard let currentLoc = await location(with: player.currentLocationID) else {
            throw ActionError.internalEngineError("Player is in an invalid location: \\(player.currentLocationID)")
        }

        // ... existing code ...
        // Use item(with:) instead of item(with:)
        if let keyItem = await item(with: keyID), keyItem.parent == .player {
            // Proceed with unlock logic
        } else {
            let keyName = await item(with: keyID)?.name ?? keyID.rawValue
            // Use item(with:) instead of item(with:)
            return ActionResult(
                success: false,
                message: "The \\(await item(with: keyID)?.name ?? keyID.rawValue) doesn't fit \\(theThat(lockID))." // Example update
            )
        }

        // If we reach here, item is unlocked.
        return ActionResult(
            success: true,
            message: "You unlock the \\(theThat(lockID))."
        )
    }

    /// Helper to check if an item has been touched (handled by the engine).
    public func hasBeenTouched(itemID: ItemID) async -> Bool {
        // Use item(with:) instead of item(with:)
        if let item = await item(with: itemID), item.hasProperty(.touched) {
            return true
        }
        return false
    }

    /// Sets the touched flag on an item if it exists.
    public func setTouchedFlag(itemID: ItemID) async throws {
        // Use item(with:) instead of item(with:)
        if let item = await item(with: itemID) {
            if !item.hasProperty(.touched) {
                let change = StateChange(
                    entityId: .item(itemID),
                    propertyKey: .itemProperties,
                    oldValue: .itemProperties(item.properties),
                    newValue: .itemProperties(item.properties.union([.touched]))
                )
                try applyStateChange(change)
            }
        } else {
            throw ActionError.internalEngineError("Attempted to set touched flag on non-existent item: \\(itemID)")
        }
    }
}
