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
    private var actionHandlers = [VerbID: ActionHandler]()

    /// Active timed events (Fuses) - Runtime storage with closures.
    private var activeFuses = [FuseID: Fuse]()

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

    // MARK: - Initialization
    
    /// Creates a new `GameEngine` instance from a game definition.
    ///
    /// - Parameters:
    ///   - game: The game definition.
    ///   - parser: The command parser.
    ///   - ioHandler: The I/O handler for player interaction.
    public init(
        game: GameDefinition,
        parser: Parser,
        ioHandler: IOHandler
    ) {
        self.gameState = game.state
        self.parser = parser
        self.ioHandler = ioHandler
        self.registry = game.registry
        self.actionHandlers = game.registry.customActionHandlers
            .merging(Self.actionHandlerDefaults) { (custom, _) in custom }
        self.onEnterRoom = game.onEnterRoom
        self.beforeTurn = game.beforeTurn
        self.activeFuses = initializeFuses(from: game.state, registry: game.registry)
    }

//    /// Creates a new `GameEngine` instance.
//    ///
//    /// - Parameters:
//    ///   - initialState: The starting state of the game.
//    ///   - parser: The command parser.
//    ///   - ioHandler: The I/O handler for player interaction.
//    ///   - registry: The game definition registry.
//    ///   - onEnterRoom: Optional closure for custom logic after entering a room.
//    ///   - beforeTurn: Optional closure for custom logic before each turn.
//    init(
//        initialState: GameState,
//        parser: Parser,
//        ioHandler: IOHandler,
//        registry: GameDefinitionRegistry = GameDefinitionRegistry(),
//        onEnterRoom: (@MainActor @Sendable (GameEngine, LocationID) async -> Bool)? = nil,
//        beforeTurn: (@MainActor @Sendable (GameEngine, Command) async -> Bool)? = nil
//    ) {
//        self.gameState = initialState
//        self.parser = parser
//        self.ioHandler = ioHandler
//        self.registry = registry
//        self.actionHandlers = registry.customActionHandlers
//            .merging(Self.actionHandlerDefaults) { (custom, _) in custom }
//        self.onEnterRoom = onEnterRoom
//        self.beforeTurn = beforeTurn
//        self.activeFuses = initializeFuses(from: initialState, registry: registry)
//    }

    private func initializeFuses(from state: GameState, registry: GameDefinitionRegistry) -> [Fuse.ID: Fuse] {
        var fuses: [Fuse.ID: Fuse] = [:]
        for (fuseID, turnsRemaining) in state.activeFuses {
            guard let definition = registry.fuseDefinition(for: fuseID) else {
                print("Warning: No FuseDefinition found for saved fuse ID '\(fuseID)'. Skipping.")
                continue
            }
            let runtimeFuse = Fuse(id: fuseID, turns: turnsRemaining, action: definition.action)
            fuses[fuseID] = runtimeFuse
        }
        return fuses
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
        actionHandlers.merge(Self.actionHandlerDefaults) { (custom, _) in custom }

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
            if await beforeTurn?(self, command) ?? false {
                return
            }
            guard !shouldQuit else {
                return // Hook might quit
            }
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
                if try await roomHandler(self, RoomActionMessage.beforeTurn(command)) {
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
            // No object handler took charge, check for darkness before running default verb handler

            let isLit = scopeResolver.isLocationLit(locationID: currentLocationID)

            // Retrieve verb definition to check requiresLight property
            // Note: Parser should ensure command.verbID exists in vocabulary
            // Correct: Look up the Verb definition directly
            guard let verb = gameState.vocabulary.verbDefinitions[command.verbID] else {
                // This case should ideally not be reached if parser validates verbs
                await ioHandler.print("Internal Error: Unknown verb ID '\(command.verbID)' reached execution.", style: .debug)
                await ioHandler.print("I don't know how to '\(command.verbID.rawValue)'.")
                return
            }

            // If the room is dark and the verb requires light, report the error and stop.
            if !isLit && verb.requiresLight {
                await report(actionError: .roomIsDark)
                // Do not proceed to execute the handler
            } else {
                // Room is lit OR verb doesn't require light, proceed with default handler execution.
                guard let verbHandler = actionHandlers[command.verbID] else {
                    // No handler registered for this verb (should match vocabulary definition)
                    await ioHandler.print("Internal Error: No ActionHandler registered for verb ID '\(command.verbID)'.", style: .debug)
                    await ioHandler.print("I don't know how to '\(command.verbID.rawValue)'.")
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
            "The \(theThat(item)) is full."
        case .containerIsOpen(let item):
            "\(theThat(item).capitalizedFirst) is already open."
        case .directionIsBlocked(let reason):
            reason ?? "Something is blocking the way."
        case .internalEngineError(let msg):
            // User-facing generic message; more details could be logged.
            "A strange buzzing sound indicates something is wrong.\n  • \(msg)"
        case .invalidDirection:
            "You can't go that way."
        case .itemAlreadyClosed(let item):
            "\(theThat(item).capitalizedFirst) is already closed."
        case .itemAlreadyOpen(let item):
            "\(theThat(item).capitalizedFirst) is already open."
        case .itemIsLocked(let item):
            "\(theThat(item).capitalizedFirst) is locked."
        case .itemIsUnlocked(let item):
            "\(theThat(item).capitalizedFirst) is already unlocked."
        case .itemNotAccessible(let item):
            // This often implies visibility/reachability issues.
            "You don't see \(theThat(item, alternate: "any")) here."
        case .itemNotCloseable(let item):
            "You can't close \(theThat(item))."
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
            // Use the custom message if provided, otherwise a generic one.
            customMessage.isEmpty ? "You can't do that." : customMessage
        case .roomIsDark:
            // Usually handled by describeCurrentLocation, but a fallback action error.
            "It's too dark to do that."
        case .targetIsNotAContainer(let item):
            "You can't put things in \(theThat(item))."
        case .targetIsNotASurface(let item):
            "You can't put things on \(theThat(item))."
        case .wrongKey(keyID: let keyID, lockID: let lockID):
            // Correct: Calculate keyDesc inline to fix switch expression structure
            "The \(itemSnapshot(with: keyID)?.name ?? keyID.rawValue) doesn't fit \(theThat(lockID))."
        }
        // Only print if the message isn't empty (some errors might be handled silently)
        if !message.isEmpty {
            await ioHandler.print(message)
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
        itemSnapshot(with: itemID)?.theName ?? alternate
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
        gameState.gameSpecificState[key] = value
    }

    /// Increments an integer value stored in the game-specific state.
    /// Initializes the value to 1 if the key doesn't exist or the current value is not an Int.
    /// - Parameter key: The key for the integer counter.
    public func incrementGameSpecificStateCounter(key: String) {
        let currentValue = gameState.gameSpecificState[key]?.value as? Int ?? 0
        updateGameSpecificState(key: key, value: AnyCodable(currentValue + 1))
    }

    /// Safely retrieves a value from the game-specific state dictionary as AnyCodable.
    /// - Parameter key: The key for the state value.
    /// - Returns: The `AnyCodable` value if found, otherwise `nil`.
    public func getGameSpecificStateValue(key: String) -> AnyCodable? {
        return gameState.gameSpecificState[key]
    }

    /// Safely retrieves a String value from the game-specific state dictionary.
    /// Performs the type casting within the MainActor context.
    /// - Parameter key: The key for the state value.
    /// - Returns: The `String` value if found and castable, otherwise `nil`.
    public func getGameSpecificStateString(key: String) -> String? {
        return gameState.gameSpecificState[key]?.value as? String
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
        gameState.gameSpecificState.removeValue(forKey: key)
    }

    /// Safely updates the player's score by a given delta.
    /// - Parameter delta: The amount to add to the score (can be negative).
    public func updatePlayerScore(delta: Int) {
        gameState.player.score += delta
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
        if await onEnterRoom?(self, locationID) ?? false { return }

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

    // MARK: - State Query Helpers

    /// Checks if the player currently holds the specified item.
    /// - Parameter itemID: The ID of the item to check for.
    /// - Returns: `true` if the player holds the item, `false` otherwise.
    public func playerHasItem(itemID: ItemID) -> Bool {
        // Access gameState safely within the MainActor context
        return gameState.items[itemID]?.parent == .player
        // Alternative, if itemsInInventory is efficient:
        // return gameState.itemsInInventory().contains(itemID)
    }
}

extension GameEngine {
    private static let actionHandlerDefaults: [VerbID: ActionHandler] = [
        "blow out": TurnOffActionHandler(),
        "close": CloseActionHandler(),
        "drop": DropActionHandler(),
        "examine": LookActionHandler(),
        "extinguish": TurnOffActionHandler(),
        "go": GoActionHandler(),
        "hang": PutActionHandler(),
        "light": TurnOnActionHandler(),
        "listen": ListenActionHandler(),
        "lock": LockActionHandler(),
        "look": LookActionHandler(),
        "open": OpenActionHandler(),
        "put": PutActionHandler(),
        "read": ReadActionHandler(),
        "remove": RemoveActionHandler(),
        "smell": SmellActionHandler(),
        "take": TakeActionHandler(),
        "taste": TasteActionHandler(),
        "think-about": ThinkAboutActionHandler(),
        "touch": PlaceholderActionHandler(verb: "touch"),
        "turn_off": TurnOffActionHandler(),
        "turn_on": TurnOnActionHandler(),
        "unlock": UnlockActionHandler(),
        "wait": WaitActionHandler(),
        "wear": WearActionHandler(),

        // Meta
        "brief": PlaceholderActionHandler(verb: "brief"), // Placeholder
        "help": PlaceholderActionHandler(verb: "help"), // Placeholder
        "inventory": InventoryActionHandler(), // Need to create this
        "quit": QuitActionHandler(),
        "restore": PlaceholderActionHandler(verb: "restore"), // Placeholder
        "save": PlaceholderActionHandler(verb: "save"), // Placeholder
        "score": ScoreActionHandler(),
        "verbose": PlaceholderActionHandler(verb: "verbose"), // Placeholder
    ]
}
