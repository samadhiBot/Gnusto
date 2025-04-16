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
    public let scopeResolver: ScopeResolver

    /// Registered handlers for specific verb commands.
    private var actionHandlers: [VerbID: ActionHandler]

    /// Flag to control the main game loop.
    private var shouldQuit: Bool = false

    // MARK: - Custom Game Hooks (Closures)

    /// Custom logic called after the player successfully enters a new location.
    /// The closure receives the engine and the ID of the location entered.
    /// It can modify the game state (e.g., change location properties based on player state).
    public var onEnterRoom: (@MainActor @Sendable (GameEngine, LocationID) async -> Void)?

    /// Custom logic called at the very start of each turn, before command processing.
    /// The closure receives the engine.
    /// It can modify game state or print messages based on the current state.
    public var beforeTurn: (@MainActor @Sendable (GameEngine) async -> Void)?

    /// Custom logic called when attempting to examine a specific item.
    /// The closure receives the engine and the ID of the item being examined.
    /// It should return `true` if it handled the examination (e.g., printed a custom description or performed an action),
    /// or `false` to let the default examination logic proceed.
    public var onExamineItem: (@MainActor @Sendable (GameEngine, ItemID) async -> Bool)?

    // MARK: - Initialization

    /// Creates a new GameEngine instance.
    /// - Parameters:
    ///   - initialState: The starting state of the game.
    ///   - parser: The command parser to use.
    ///   - ioHandler: The I/O handler for player interaction.
    ///   - scopeResolver: The resolver for scope checks (defaults to a new instance).
    ///   - customHandlers: Optional dictionary of custom action handlers to override or supplement defaults.
    ///   - onEnterRoom: Optional closure for custom logic after entering a room.
    ///   - beforeTurn: Optional closure for custom logic before each turn.
    ///   - onExamineItem: Optional closure for custom logic when examining an item.
    public init(
        initialState: GameState,
        parser: Parser,
        ioHandler: IOHandler,
        scopeResolver: ScopeResolver = ScopeResolver(),
        customHandlers: [VerbID: ActionHandler] = [:],
        onEnterRoom: (@MainActor @Sendable (GameEngine, LocationID) async -> Void)? = nil,
        beforeTurn: (@MainActor @Sendable (GameEngine) async -> Void)? = nil,
        onExamineItem: (@MainActor @Sendable (GameEngine, ItemID) async -> Bool)? = nil
    ) {
        self.gameState = initialState
        self.parser = parser
        self.ioHandler = ioHandler
        self.scopeResolver = scopeResolver
        self.actionHandlers = customHandlers // Start with custom handlers
        self.onEnterRoom = onEnterRoom
        self.beforeTurn = beforeTurn
        self.onExamineItem = onExamineItem
    }

    /// Registers the default action handlers for common verbs.
    /// Called from run() after initialization.
    private func registerDefaultHandlers() {
        let defaultHandlers: [VerbID: ActionHandler] = [
            VerbID("look"): LookActionHandler(),
            VerbID("examine"): LookActionHandler(), // Add synonyms
            VerbID("x"): LookActionHandler(),       // Add synonyms
            VerbID("l"): LookActionHandler(),        // Add synonyms
            VerbID("go"): GoActionHandler()          // Register Go handler
            // VerbID("take"): TakeActionHandler(),
            // ... etc.
        ]
        // Merge defaults, keeping custom handlers if they exist
        self.actionHandlers.merge(defaultHandlers) { (custom, _) in custom }
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
        await beforeTurn?(self)
        // Check if the beforeTurn hook requested a quit
        guard !shouldQuit else { return }
        // --------------------------------

        // 1. Get Player Input
        guard let input = await ioHandler.readLine(prompt: "> ") else {
            await ioHandler.print("Goodbye!")
            shouldQuit = true
            return
        }

        // Basic quit command check (can be expanded)
        if input.lowercased() == "quit" {
            shouldQuit = true
            return
        }

        // 2. Parse Input
        // Use the vocabulary stored within the GameState
        let vocabulary = gameState.vocabulary
        let parseResult = parser.parse(input: input, vocabulary: vocabulary, gameState: gameState)

        // Increment turn counter (typically happens even if command fails)
        gameState.player.moves += 1

        // 3. Execute Command or Handle Error
        switch parseResult {
        case .success(let command):
            await execute(command: command)
        case .failure(let error):
            await report(parseError: error)
        }
    }

    // MARK: - Command Execution

    /// Looks up and executes the appropriate ActionHandler for the given command.
    /// - Parameter command: The command to execute.
    private func execute(command: Command) async {
        // Find the handler for the verb
        guard let handler = actionHandlers[command.verbID] else {
            // No handler registered for this verb
            // TODO: Improve default message based on Zork ("You can't...", "I don't know how...")
            await ioHandler.print("I don't understand how to '\(command.verbID.rawValue)'.")
            return
        }

        // Execute the handler
        do {
            try await handler.perform(command: command, engine: self)
            // Optional: Print a default success message like "Done." if the handler didn't?
            // Often handlers print their own specific success messages (e.g., "Taken.").
        } catch let actionError as ActionError {
            // Handle specific action failures
            await report(actionError: actionError)
        } catch {
            // Handle unexpected errors during action execution
            await ioHandler.print("An unexpected error occurred while performing the action: \(error)", style: .debug)
            await ioHandler.print("Sorry, something went wrong.")
        }
    }

    // MARK: - Output & Error Reporting

    /// Displays the description of the current location, considering light level.
    internal func describeCurrentLocation() async {
        let locationID = gameState.player.currentLocationID

        // 1. Check for light
        guard scopeResolver.isLocationLit(locationID: locationID, gameState: gameState) else {
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
        let visibleItemIDs = scopeResolver.visibleItemsIn(locationID: locationID, gameState: gameState)

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
            message = "Please enter a command."
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

    /// Reports an action execution error to the player.
    private func report(actionError: ActionError) async {
        // Provide user-friendly messages for action failures
        // TODO: Implement messages for all ActionError cases
        let message: String
        switch actionError {
        case .invalidDirection:
            message = "You can't go that way."
        case .directionIsBlocked(let reason):
            message = reason ?? "Something is blocking the way."
        case .itemNotTakable:
            message = "You can't take that."
        case .containerIsClosed:
            message = "That is closed."
        case .itemIsLocked:
            message = "That is locked."
        case .playerCannotCarryMore:
            message = "Your hands are full."
        case .itemNotHeld(let itemID):
            // Use safe snapshot accessor for item name
            let itemName = itemSnapshot(with: itemID)?.name ?? "that item"
            message = "You aren't holding \(itemName)."
        // Add more cases here...
        default:
            message = "You can't do that right now."
        }
        await ioHandler.print(message)
    }

    // MARK: - Safe State Accessors for Handlers

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

    // Add other necessary safe accessors here...

    // Note: We also need a way to modify state safely. Example:
    /// Safely updates the parent of an item.
    public func updateItemParent(itemID: ItemID, newParent: ParentEntity) {
        gameState.items[itemID]?.parent = newParent
    }

    /// Safely adds a property to an item.
    public func addItemProperty(itemID: ItemID, property: ItemProperty) {
        gameState.items[itemID]?.addProperty(property)
    }

    /// Safely removes a property from an item.
    public func removeItemProperty(itemID: ItemID, property: ItemProperty) {
        gameState.items[itemID]?.removeProperty(property)
    }

    /// Safely updates the player's current location ID.
    public func updatePlayerLocation(newLocationID: LocationID) {
        // TODO: Add check if newLocationID exists in gameState.locations?
        gameState.player.currentLocationID = newLocationID
    }

    // Add other mutation methods as needed (e.g., update score, flags)

    // MARK: - Debug/Testing Helpers

    /// **Testing Only:** Adds an item directly to the game state's item dictionary using its constituent data.
    /// Use with caution, primarily for setting up test scenarios.
    /// Creates the item within the actor's context.
    internal func debugAddItem(id: ItemID, name: String, properties: Set<ItemProperty> = [], size: Int = 5, parent: ParentEntity = .nowhere) {
        let newItem = Item(id: id, name: name, properties: properties, size: size, parent: parent)
        gameState.items[newItem.id] = newItem
    }

    // MARK: - Public Accessors & Mutators (Thread-Safe)

    /// Provides read-only access to the current game state snapshot.
    public func getCurrentGameState() -> GameState {
        return gameState
    }

    /// Allows controlled mutation of the game state.
    /// Use this for handlers or custom hooks to modify the state.
    public func updateGameState(_ updateBlock: (inout GameState) -> Void) {
        updateBlock(&gameState)
    }

    /// Updates the player's current location and triggers the onEnterRoom hook.
    public func changePlayerLocation(to locationID: LocationID) async {
        guard gameState.locations[locationID] != nil else {
            await ioHandler.print("Error: Attempted to move player to invalid location \(locationID)", style: .debug)
            return
        }
        gameState.player.currentLocationID = locationID
        // --- Custom Hook: On Enter Room ---
        await onEnterRoom?(self, locationID)
        // ----------------------------------
    }

    /// Sets the flag to end the game loop after the current turn.
    public func quitGame() {
        shouldQuit = true
        // Optionally print a final message immediately or let the loop handle it.
        // await ioHandler.print("Goodbye!") // Can be done here or in run()
    }
}

// Remove the temporary vocabulary extension on GameState
/*
extension GameState {
    var vocabulary: Vocabulary {
        Vocabulary()
    }
}
*/
