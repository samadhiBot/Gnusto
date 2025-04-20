import Foundation

/// The main orchestrator for the interactive fiction game.
/// This actor manages the game state, handles the game loop, interacts with the parser
/// and IO handler, and executes player commands using registered ActionHandlers.
@MainActor
public class GameEngine {

    // MARK: - Properties

    /// The current state of the game world.
    public private(set) var gameState: GameState

    /// The parser responsible for understanding player input.
    private let parser: Parser

    /// The handler for input and output operations.
    /// Use a nonisolated let for the IOHandler; calls to it must be await ioHandler.method().
    nonisolated internal let ioHandler: IOHandler

    /// The resolver for scope and visibility checks.
    lazy var scopeResolver: ScopeResolver = ScopeResolver(engine: self)

    /// The registry holding static game definitions (fuses, daemons, etc.).
    public let registry: GameDefinitionRegistry

    /// Registered handlers for specific verb commands.
    private var actionHandlers: [VerbID: ActionHandler]

    /// Active timed events (Fuses) - Runtime storage with closures.
    private var activeFuses: [FuseID: Fuse] // Use FuseID type alias

    /// Flag to control the main game loop.
    private var shouldQuit: Bool = false

    // MARK: - Custom Game Hooks (Closures)

    /// Custom logic called after the player successfully enters a new location.
    /// The closure receives the engine and the ID of the location entered.
    /// It can modify the game state (e.g., change location properties based on player state).
    public var onEnterRoom: (@MainActor @Sendable (GameEngine, LocationID) async -> Void)?

    /// Custom logic called at the very start of each turn, before command processing.
    /// The closure receives the engine and the command.
    /// It can modify game state or print messages based on the current state.
    public var beforeTurn: (@MainActor @Sendable (GameEngine, Command) async -> Void)?

    // MARK: - Initialization

    /// Creates a new GameEngine instance.
    /// - Parameters:
    ///   - initialState: The starting state of the game.
    ///   - parser: The command parser to use.
    ///   - ioHandler: The I/O handler for player interaction.
    ///   - registry: The game definition registry to use.
    ///   - customHandlers: Optional dictionary of custom action handlers to override or supplement defaults.
    ///   - onEnterRoom: Optional closure for custom logic after entering a room.
    ///   - beforeTurn: Optional closure for custom logic before each turn.
    public init(
        initialState: GameState,
        parser: Parser,
        ioHandler: IOHandler,
        registry: GameDefinitionRegistry = GameDefinitionRegistry(),
        customHandlers: [VerbID: ActionHandler] = [:],
        onEnterRoom: (@MainActor @Sendable (GameEngine, LocationID) async -> Void)? = nil,
        beforeTurn: (@MainActor @Sendable (GameEngine, Command) async -> Void)? = nil
    ) {
        self.gameState = initialState
        self.parser = parser
        self.ioHandler = ioHandler
        self.registry = registry
        self.actionHandlers = customHandlers
        self.onEnterRoom = onEnterRoom
        self.beforeTurn = beforeTurn

        // Reconstruct runtime fuses from saved state and registry
        self.activeFuses = [:] // Start with empty runtime fuses
        for (fuseID, turnsRemaining) in gameState.activeFuses {
            guard let definition = registry.fuseDefinition(for: fuseID) else {
                // Log warning: Saved fuse state exists but no definition found
                print("Warning: No FuseDefinition found for saved fuse ID '\(fuseID)'. Skipping.")
                // Optionally, remove the orphaned state from gameState?
                // self.gameState.activeFuses.removeValue(forKey: fuseID)
                continue
            }
            // Create runtime Fuse with loaded turns and defined action
            let runtimeFuse = Fuse(id: fuseID, turns: turnsRemaining, action: definition.action)
            self.activeFuses[fuseID] = runtimeFuse
        }
    }

    /// Registers the default action handlers for common verbs.
    /// Called from run() after initialization.
    private func registerDefaultHandlers() {
        // Define default handlers corresponding to Vocabulary.defaultVerbs
        // Use VerbID("verbName") for clarity
        let defaultHandlers: [VerbID: ActionHandler] = [
            // Core
            VerbID("look"): LookActionHandler(),
            VerbID("examine"): LookActionHandler(), // Handles both LOOK and EXAMINE X
            VerbID("inventory"): InventoryActionHandler(), // Need to create this
            VerbID("quit"): QuitActionHandler(),
            VerbID("score"): ScoreActionHandler(),
            VerbID("wait"): WaitActionHandler(),

            // Movement
            VerbID("go"): GoActionHandler(),

            // Common Interactions
            VerbID("take"): TakeActionHandler(), // Use the real handler
            VerbID("drop"): DropActionHandler(), // Use the real handler
            VerbID("put"): PutActionHandler(),    // <--- Add Put Handler
            VerbID("hang"): PutActionHandler(),   // <--- Alias Hang to Put
            VerbID("open"): OpenActionHandler(), // Use the real handler
            VerbID("close"): CloseActionHandler(), // Use the real handler
            VerbID("read"): ReadActionHandler(), // Use the real handler
            VerbID("wear"): WearActionHandler(), // Use the real handler
            VerbID("remove"): RemoveActionHandler(), // Use the real handler
            // Removed incorrect direct mappings for turn/switch
            // Register specific turn_on/turn_off IDs
            VerbID("turn_on"): TurnOnActionHandler(),
            VerbID("light"): TurnOnActionHandler(), // Direct mapping for LIGHT verb
            VerbID("turn_off"): TurnOffActionHandler(),
            VerbID("extinguish"): TurnOffActionHandler(), // Direct mapping for EXTINGUISH verb
            VerbID("blow out"): TurnOffActionHandler(), // Direct mapping for BLOW OUT verb
            VerbID("lock"): LockActionHandler(),          // Added lock handler
            VerbID("unlock"): UnlockActionHandler(),      // Added unlock handler

            // Sensory
            VerbID("smell"): SmellActionHandler(),
            VerbID("listen"): ListenActionHandler(),
            VerbID("taste"): TasteActionHandler(),
            VerbID("touch"): PlaceholderActionHandler(verb: "touch"), // Placeholder

            // Meta
            VerbID("help"): PlaceholderActionHandler(verb: "help"), // Placeholder
            VerbID("save"): PlaceholderActionHandler(verb: "save"), // Placeholder
            VerbID("restore"): PlaceholderActionHandler(verb: "restore"), // Placeholder
            VerbID("verbose"): PlaceholderActionHandler(verb: "verbose"), // Placeholder
            VerbID("brief"): PlaceholderActionHandler(verb: "brief"), // Placeholder
        ]

        // Merge defaults, keeping custom handlers provided during init if they exist
        self.actionHandlers.merge(defaultHandlers) { (custom, _) in custom }
    }

    // Add Placeholder Handler Struct (Temporary)
    fileprivate struct PlaceholderActionHandler: ActionHandler {
        let verb: String

        func perform(
            command: Command,
            engine: GameEngine
        ) async throws {
            await engine.output("Sorry, the default handler for '\(verb)' is not implemented yet.")
        }
    }

    // Need InventoryActionHandler
//    fileprivate struct InventoryActionHandler: ActionHandler {
//        func perform(
//            command: Command,
//            engine: GameEngine
//        ) async throws {
//             let heldItems = await engine.itemSnapshots(withParent: .player)
//             if heldItems.isEmpty {
//                 await engine.output("You aren't carrying anything.")
//             } else {
//                 await engine.output("You are carrying:")
//                 for item in heldItems {
//                     await engine.output("  A \(item.name)") // TODO: Proper article/listing
//                 }
//             }
//         }
//     }

    // MARK: - Fuse & Daemon Management

    /// Adds or updates a fuse based on its definition in the registry.
    /// If a fuse with the same ID already exists, its timer is reset using the provided or default turns.
    /// - Parameters:
    ///   - id: The `FuseID` of the fuse to add or update.
    ///   - overrideTurns: Optional number of turns to set for the fuse. If `nil`, the default turns from the `FuseDefinition` are used.
    /// - Returns: `true` if the fuse was successfully added or updated, `false` if no definition was found for the ID.
    @discardableResult
    public func addFuse(
        id: FuseID,
        overrideTurns: Int? = nil
    ) -> Bool {
        // 1. Find the definition in the registry.
        guard let definition = registry.fuseDefinition(for: id) else {
            // Log warning or error: Attempting to add an undefined fuse.
            print("Warning: No FuseDefinition found for fuse ID '\(id)'. Cannot add fuse.")
            // Consider throwing an error or returning a more specific result.
            return false
        }

        // 2. Determine the number of turns.
        let turns = overrideTurns ?? definition.initialTurns

        // 3. Create the runtime Fuse instance.
        let runtimeFuse = Fuse(id: id, turns: turns, action: definition.action)

        // 4. Update runtime dictionary.
        activeFuses[id] = runtimeFuse

        // 5. Update persistent state in GameState.
        gameState.activeFuses[id] = turns

        return true
    }

    /// Removes a fuse by its ID (runtime and persistent state).
    public func removeFuse(id: FuseID) {
        // Remove from runtime dictionary
        activeFuses.removeValue(forKey: id)
        // Remove from persistent state in GameState
        gameState.activeFuses.removeValue(forKey: id)
    }

    /// Registers a daemon to run periodically by adding its ID to the active set in GameState.
    /// The daemon must be defined in the registry.
    /// - Parameter id: The `DaemonID` of the daemon to register.
    /// - Returns: `true` if the daemon was successfully registered, `false` if no definition was found for the ID.
    @discardableResult
    public func registerDaemon(id: DaemonID) -> Bool {
        // 1. Verify the definition exists in the registry.
        guard registry.daemonDefinition(for: id) != nil else {
            print("Warning: No DaemonDefinition found for daemon ID '\(id)'. Cannot register daemon.")
            return false
        }
        // 2. Add the ID to the active set in GameState.
        gameState.activeDaemons.insert(id)
        return true
    }

    /// Unregisters a daemon by removing its ID from the active set in GameState.
    /// Does nothing if no daemon with the given ID is active.
    /// - Parameter id: The `DaemonID` to unregister.
    public func unregisterDaemon(id: DaemonID) {
        gameState.activeDaemons.remove(id)
    }

    // MARK: - Game Loop

    /// Starts and runs the main game loop.
    public func run() async {
        // Register handlers *after* actor initialization
        registerDefaultHandlers()

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
        gameState.player.moves += 1

        // 3. Execute Command or Handle Error
        switch parseResult {
        case .success(let command):
            // --- Custom Hook: Before Turn (called only on success) ---
            await beforeTurn?(self, command)
            guard !shouldQuit else { return } // Hook might quit
            // ---------------------------------------------------------
            await execute(command: command)
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
        let fuseIDs = Array(activeFuses.keys)

        for id in fuseIDs {
            guard var fuse = activeFuses[id] else { continue } // Ensure fuse wasn't removed

            fuse.turnsRemaining -= 1

            if fuse.turnsRemaining <= 0 {
                expiredFuseIDs.append(id)
                fusesToExecute.append(fuse)
                // Remove from persistent state now that it has expired
                gameState.activeFuses.removeValue(forKey: id)
            } else {
                // Update runtime fuse state
                activeFuses[id] = fuse
                // Update persistent state with new remaining turns
                gameState.activeFuses[id] = fuse.turnsRemaining
            }
        }

        // Remove expired fuses from runtime dictionary *before* executing actions
        for id in expiredFuseIDs {
            activeFuses.removeValue(forKey: id)
        }

        // Execute actions of expired fuses
        for fuse in fusesToExecute {
            await fuse.action(self)
            if shouldQuit { return }
        }

        // --- Process Daemons ---
        // Execute daemons whose frequency matches the current turn
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
    private func execute(command: Command) async {
        var actionHandled = false
        var actionError: Error? = nil // To store error from object handlers

        // --- Room BeforeTurn Hook ---
        let currentLocationID = playerLocationID()
        if let roomHandler = registry.roomActionHandler(for: currentLocationID) {
            do {
                // Call handler, pass command using correct enum case syntax
                let handledByRoom = try await roomHandler(self, RoomActionMessage.beforeTurn(command))
                if handledByRoom {
                    // Room handler blocked further action, return immediately.
                    // We don't increment moves or run afterTurn hook here.
                    return
                }
            } catch {
                // Log error and potentially halt turn?
                await ioHandler.print("Error in room beforeTurn handler: \(error)", style: .debug)
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
                await ioHandler.print("An unexpected error occurred in an object handler: \(error)", style: .debug)
                await ioHandler.print("Sorry, something went wrong performing that action on the specific item.")
            }
        } else if !actionHandled {
            // No object handler took charge, run the default verb handler
            guard let verbHandler = actionHandlers[command.verbID] else {
                // No handler registered for this verb
                await ioHandler.print("I don't understand how to '\(command.verbID.rawValue)'.")
                return
            }

            // Execute the default handler
            do {
                try await verbHandler.perform(command: command, engine: self)
            } catch let actionError as ActionError {
                // Handle specific action failures
                await report(actionError: actionError)
            } catch {
                // Handle unexpected errors during action execution
                await ioHandler.print("An unexpected error occurred while performing the action: \(error)", style: .debug)
                await ioHandler.print("Sorry, something went wrong.")
            }
        }
        // If actionHandled is true and error is nil, the object handler succeeded silently (or printed its own msg).

        // --- Room AfterTurn Hook ---
        if let roomHandler = registry.roomActionHandler(for: currentLocationID) {
            do {
                // Call handler, ignore return value, use correct enum case syntax
                _ = try await roomHandler(self, RoomActionMessage.afterTurn(command))
            } catch {
                await ioHandler.print("Error in room afterTurn handler: \(error)", style: .debug)
            }
            // Check if handler quit the game
            if shouldQuit { return }
        }
    }

    // MARK: - Output & Error Reporting

    /// Displays the description of the current location, considering light level.
    internal func describeCurrentLocation() async {
        let locationID = gameState.player.currentLocationID

        // 1. Check for light
        guard scopeResolver.isLocationLit(locationID: locationID) else {
            // It's dark!
            await ioHandler.print("It is pitch black. You are likely to be eaten by a grue.")
            // Do not describe the room or list items.
            return
        }

        // 2. If lit, proceed with description
        guard let currentLocation = gameState.locations[locationID] else {
            await ioHandler.print("Error: Current location not found!", style: .debug)
            return
        }
        await ioHandler.print("--- \(currentLocation.name) ---", style: .strong)
        await ioHandler.print(currentLocation.description)

        // 3. List visible items
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
            for item in visibleItems { // Iterate through visible Items
                // TODO: Use item descriptions (firstDesc, subDesc) based on touched state?
                // TODO: Proper sentence formatting with articles
                await ioHandler.print("  A \(item.name)")
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
        // Provide more user-friendly messages
        let message: String
        switch parseError {
        case .emptyInput:
            message = "I beg your pardon?" // More classic response
        case .unknownVerb(let verb):
            message = "I don't know the verb '\(verb)'."
        case .unknownNoun(let noun):
            message = "I don't see any '\(noun)' here."
        case .itemNotInScope(let noun):
            message = "You can't see any '\(noun)' here."
        case .modifierMismatch(let noun, let modifiers):
            message = "I don't see any '\(modifiers.joined(separator: " ")) \(noun)' here."
        case .ambiguity(let text), .ambiguousPronounReference(let text):
            message = text // Use the message generated by the parser
        case .badGrammar(let text):
            message = text
        case .pronounNotSet(let pronoun):
            message = "I don't know what '\(pronoun)' refers to."
        case .pronounRefersToOutOfScopeItem(let pronoun):
            message = "You can't see what '\(pronoun)' refers to right now."
        case .internalError(let details):
            message = "A weird parsing error occurred: \(details)" // Should be rare
        }
        await ioHandler.print(message)
    }

    /// Reports user-friendly messages for action failures to the player.
    private func report(actionError: ActionError) async {
        let message = switch actionError {
        case .containerIsClosed(let item):
            "\(theThat(item).capitalizedFirst) is closed."
        case .containerIsFull(let item):
            ""
        case .containerIsOpen(let item):
            ""
        case .directionIsBlocked(let reason):
            reason ?? "Something is blocking the way."
        case .internalEngineError(let item):
            ""
        case .invalidDirection:
            "You can't go that way."
        case .itemAlreadyClosed(let item):
            ""
        case .itemAlreadyOpen(let item):
            ""
        case .itemIsLocked(let item):
            "That is locked."
        case .itemIsUnlocked(let item):
            ""
        case .itemNotAccessible(let item):
            ""
        case .itemNotCloseable(let item):
            "You can't close \(theThat(item))."
        case .itemNotDroppable(let item):
            ""
        case .itemNotEdible(let item):
            ""
        case .itemNotHeld(let item):
            "You aren't holding \(theThat(item))."
        case .itemNotInContainer(item: let item, container: let container):
            ""
        case .itemNotLockable(let item):
            ""
        case .itemNotOnSurface(item: let item, surface: let surface):
            ""
        case .itemNotOpenable(let item):
            "You can't open \(theThat(item))."
        case .itemNotReadable(let item):
            ""
        case .itemNotRemovable(let item):
            ""
        case .itemNotTakable(let item):
            "You can't take \(theThat(item))."
        case .itemNotUnlockable(let item):
            ""
        case .itemNotWearable(let item):
            "You can't wear \(theThat(item))."
        case .playerCannotCarryMore:
            "Your hands are full."
        case .prerequisiteNotMet(let item):
            ""
        case .roomIsDark:
            ""
        case .targetIsNotAContainer(let item):
            ""
        case .targetIsNotASurface(let item):
            ""
        case .wrongKey(keyID: let keyID, lockID: let lockID):
            ""
        }
        await ioHandler.print(message)
    }
    
    /// <#Description#>
    /// - Parameter itemID: <#itemID description#>
    /// - Returns: <#description#>
    private func theThat(_ itemID: ItemID) -> String {
        itemSnapshot(with: itemID)?.theName ?? "that"
    }

    // MARK: - State Access Helpers (Public but @MainActor isolated)

    /// Safely retrieves a snapshot of an item by its ID from the current game state.
    /// This method runs on the GameEngine's actor context.
    /// - Parameter id: The `ItemID` of the item to retrieve.
    /// - Returns: An `ItemSnapshot` if the item is found, otherwise `nil`.
    public func itemSnapshot(with id: ItemID) -> ItemSnapshot? {
        guard let item = gameState.items[id] else { return nil }
        return ItemSnapshot(item: item)
    }

    /// Safely retrieves snapshots of items that have a specific parent entity.
    /// This method runs on the GameEngine's actor context.
    /// - Parameter parent: The `ParentEntity` to filter by.
    /// - Returns: An array of `ItemSnapshot`s for items with the specified parent.
    public func itemSnapshots(withParent parent: ParentEntity) -> [ItemSnapshot] {
        return gameState.items.values
            .filter { $0.parent == parent }
            .map { ItemSnapshot(item: $0) }
    }

    /// Safely retrieves the player's current location ID.
    public func playerLocationID() -> LocationID {
        return gameState.player.currentLocationID
    }

    /// Safely retrieves a snapshot of the player's current location.
    public func playerLocationSnapshot() -> LocationSnapshot? {
        locationSnapshot(with: gameState.player.currentLocationID)
    }

    /// Safely retrieves the player's score.
    public func playerScore() -> Int {
        return gameState.player.score
    }

    /// Safely retrieves the player's move count.
    public func playerMoves() -> Int {
        return gameState.player.moves
    }

    /// Checks if the player can carry an item of the given size based on current inventory weight and capacity.
    /// - Parameter itemSize: The size/weight of the item to potentially carry.
    /// - Returns: `true` if the player can carry the item, `false` otherwise.
    public func canPlayerCarry(itemSize: Int) -> Bool {
        let currentWeight = gameState.player.currentInventoryWeight(allItems: gameState.items)
        let playerCapacity = gameState.player.carryingCapacity
        // ZIL often allowed exactly matching capacity
        return (currentWeight + itemSize) <= playerCapacity
    }

    /// Safely retrieves a snapshot of a location by its ID from the current game state.
    /// This method runs on the GameEngine's actor context.
    /// - Parameter id: The `LocationID` of the location to retrieve.
    /// - Returns: A `LocationSnapshot` if the location is found, otherwise `nil`.
    public func locationSnapshot(with id: LocationID) -> LocationSnapshot? {
        guard let location = gameState.locations[id] else { return nil }
        return LocationSnapshot(location: location)
    }

    // MARK: - State Mutation Helpers (Public but @MainActor isolated)

    /// Updates the properties of a specific location.
    /// - Parameters:
    ///   - id: The `LocationID` of the location to update.
    ///   - adding: A set of `LocationProperty` to add. Pass `nil` to ignore.
    ///   - removing: A set of `LocationProperty` to remove. Pass `nil` to ignore.
    public func updateLocationProperties(
        id: LocationID,
        adding: LocationProperty...,
        removing: LocationProperty...
    ) {
        guard let location = gameState.locations[id] else {
            // Log warning: Location not found
            print("Warning: Attempted to update properties for non-existent location '\(id)'.")
            return
        }
        location.properties.formUnion(adding)
        location.properties.subtract(removing)
        // Reassign the modified location object back to the dictionary
        gameState.locations[id] = location
    }

    /// Updates the parent entity of a specific item.
    /// - Parameters:
    ///   - itemID: The ID of the item to move.
    ///   - newParent: The new `ParentEntity` for the item.
    public func updateItemParent(
        itemID: ItemID,
        newParent: ParentEntity
    ) {
        guard let item = gameState.items[itemID] else {
            print("Warning: Attempted to update parent for non-existent item '\(itemID)'.")
            return
        }
        // TODO: Add checks? (e.g., prevent moving item inside itself?)
        item.parent = newParent
        gameState.items[itemID] = item
    }

    /// Updates the properties of a specific item.
    /// - Parameters:
    ///   - itemID: The `ItemID` of the item to update.
    ///   - adding: A set of `ItemProperty` to add. Pass `nil` to ignore.
    ///   - removing: A set of `ItemProperty` to remove. Pass `nil` to ignore.
    public func updateItemProperties(
        itemID: ItemID,
        adding: ItemProperty...,
        removing: ItemProperty...
    ) {
        guard let item = gameState.items[itemID] else {
            print("Warning: Attempted to update properties for non-existent item '\(itemID)'.")
            return
        }
        if !adding.isEmpty {
            item.properties.formUnion(adding)
        }
        if !removing.isEmpty {
            item.properties.subtract(removing)
        }
        gameState.items[itemID] = item
    }

    /// Updates the exits of a specific location.
    /// - Parameters:
    ///   - id: The `LocationID` of the location to update.
    ///   - adding: A dictionary of `[Direction: Exit]` to add/update. Pass `nil` to ignore.
    ///   - removing: An array of `Direction`s whose exits should be removed. Pass `nil` to ignore.
    public func updateLocationExits(
        id: LocationID,
        adding: [Direction: Exit] = [:],
        removing: Direction...
    ) {
        guard let location = gameState.locations[id] else {
            print("Warning: Attempted to update exits for non-existent location '\(id)'.")
            return
        }
        for (direction, exit) in adding {
            location.exits[direction] = exit
        }
        for direction in removing {
            location.exits.removeValue(forKey: direction)
        }
        gameState.locations[id] = location
    }

    /// Updates the referent for a specific pronoun (e.g., "it").
    /// - Parameters:
    ///   - pronoun: The pronoun string (e.g., "it", "them").
    ///   - itemID: The ID of the item the pronoun now refers to.
    public func updatePronounReference(
        pronoun: String,
        itemID: ItemID
    ) {
        // Assumes single item reference for now, like ZIL default
        gameState.updatePronoun(pronoun.lowercased(), referringTo: itemID)
    }

    /// Updates the referents for a specific pronoun (e.g., "them").
    /// - Parameters:
    ///   - pronoun: The pronoun string (e.g., "it", "them").
    ///   - itemIDs: The set of item IDs the pronoun now refers to.
    public func updatePronounReference(
        pronoun: String,
        itemIDs: Set<ItemID>
    ) {
        gameState.updatePronoun(pronoun.lowercased(), referringTo: itemIDs)
    }

    /// Updates a value in the game-specific state dictionary.
    /// Creates the dictionary if it doesn't exist.
    /// - Parameters:
    ///   - key: The key for the state value.
    ///   - value: The `AnyCodable` value to set.
    public func updateGameSpecificState(key: String, value: AnyCodable) {
        if gameState.gameSpecificState == nil {
            gameState.gameSpecificState = [:]
        }
        gameState.gameSpecificState?[key] = value
    }

    /// Increments an integer value stored in the game-specific state.
    /// Initializes the value to 1 if the key doesn't exist or the current value is not an Int.
    /// - Parameter key: The key for the integer counter.
    public func incrementGameSpecificStateCounter(key: String) {
        let currentValue = gameState.gameSpecificState?[key]?.value as? Int ?? 0
        updateGameSpecificState(key: key, value: AnyCodable(currentValue + 1))
    }

    /// Safely retrieves a value from the game-specific state dictionary as AnyCodable.
    /// - Parameter key: The key for the state value.
    /// - Returns: The `AnyCodable` value if found, otherwise `nil`.
    public func getGameSpecificStateValue(key: String) -> AnyCodable? {
        return gameState.gameSpecificState?[key]
    }

    /// Safely retrieves a String value from the game-specific state dictionary.
    /// Performs the type casting within the MainActor context.
    /// - Parameter key: The key for the state value.
    /// - Returns: The `String` value if found and castable, otherwise `nil`.
    public func getGameSpecificStateString(key: String) -> String? {
        return gameState.gameSpecificState?[key]?.value as? String
    }

    /// Safely retrieves the value of a boolean flag from the game state.
    /// - Parameter key: The key for the flag.
    /// - Returns: The `Bool` value if the flag exists, otherwise `nil`.
    public func getFlagValue(key: String) -> Bool? {
        return gameState.flags[key]
    }

    /// Safely sets the value of a boolean flag in the game state.
    /// - Parameters:
    ///   - key: The key for the flag.
    ///   - value: The `Bool` value to set.
    public func setFlagValue(key: String, value: Bool) {
        gameState.flags[key] = value
    }

    /// Safely removes a key-value pair from the game-specific state dictionary.
    /// - Parameter key: The key to remove.
    public func removeGameSpecificStateValue(key: String) {
        gameState.gameSpecificState?.removeValue(forKey: key)
    }

    /// Safely updates the player's score by a given delta.
    /// - Parameter delta: The amount to add to the score (can be negative).
    public func updatePlayerScore(delta: Int) {
        gameState.player.score += delta
    }

    // MARK: - Debug/Testing Helpers

    /// Adds an item directly to the game state's item dictionary using its constituent data.
    ///
    /// Creates the item within the actor's context.
    ///
    /// - Warning: Use with caution! This function is only intended to be used when setting up
    ///            test scenarios.
    func debugAddItem(
        id: ItemID,
        name: String,
        description: String? = nil,
        properties: Set<ItemProperty> = [],
        size: Int = 5,
        parent: ParentEntity = .nowhere,
        readableText: String? = nil
    ) {
        let newItem = Item.init(
            id: id,
            name: name,
            description: description,
            properties: properties,
            size: size,
            parent: parent,
            readableText: readableText
        )
        gameState.items[newItem.id] = newItem
    }

    // MARK: - Public Accessors & Mutators (Thread-Safe)

    /// Updates the player's current location and triggers the onEnterRoom hook.
    public func changePlayerLocation(to locationID: LocationID) async {
        guard gameState.locations[locationID] != nil else {
            await ioHandler.print("Error: Attempted to move player to invalid location \(locationID)", style: .debug)
            return
        }
        gameState.player.currentLocationID = locationID

        // --- Call the general onEnterRoom hook ---
        await onEnterRoom?(self, locationID)
        // Check if hook quit the game
        if shouldQuit { return }

        // --- Call RoomActionHandler: On Enter Room ---
        if let roomHandler = registry.roomActionHandler(for: locationID) {
            do {
                // Call handler, ignore return value for onEnter, use correct enum case syntax
                _ = try await roomHandler(self, RoomActionMessage.onEnter)
            } catch {
                await ioHandler.print("Error in room onEnter handler: \(error)", style: .debug)
            }
            // Check if handler quit the game
            if shouldQuit { return }
        }
    }

    /// Sets the flag to end the game loop after the current turn.
    public func quitGame() {
        shouldQuit = true
        // Optionally print a final message immediately or let the loop handle it.
        // await ioHandler.print("Goodbye!") // Can be done here or in run()
    }

    // MARK: - Output Helpers

    /// Displays text to the player using the configured IOHandler.
    /// - Parameters:
    ///   - text: The text to display.
    ///   - style: The desired text style.
    ///   - newline: Whether to append a newline (defaults to true).
    public func output(
        _ text: String,
        style: TextStyle = .normal,
        newline: Bool = true
    ) async {
        await ioHandler.print(text, style: style, newline: newline)
    }
}
