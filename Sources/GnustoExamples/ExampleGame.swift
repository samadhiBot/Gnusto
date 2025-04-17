import Foundation
import GnustoEngine

/// A simple example game that demonstrates various Gnusto engine features.
/// This serves as both documentation and a reference implementation.
@MainActor
public class ExampleGame {
    // MARK: - Properties

    /// The game engine instance that manages the game state.
    private let engine: GameEngine

    /// Flag to track if the game is currently running.
    private var isRunning = false

    // MARK: - Initialization

    /// Creates a new example game with all the necessary components set up.
    /// - Parameter customIOHandler: An optional custom IO handler. If nil, a ConsoleIOHandler is used.
    public init(customIOHandler: IOHandler? = nil) async {
        // Set up the game data
        let (initialState, registry) = await Self.createGameData()

        // Create the parser
        let parser = SimpleParser()

        // Create or use the provided IO handler
        let ioHandler = customIOHandler ?? await ConsoleIOHandler()

        // Create a scope resolver
        let scopeResolver = ScopeResolver()

        // Create the engine with the initial components
        engine = GameEngine(
            initialState: initialState,
            parser: parser,
            ioHandler: ioHandler,
            scopeResolver: scopeResolver,
            registry: registry,
            onEnterRoom: Self.onEnterRoom,
            beforeTurn: Self.beforeEachTurn,
            onExamineItem: Self.onExamineItem
        )

        // Set up the lantern timer
        await setupLanternTimer(engine: engine)
    }

    // MARK: - Game Data Setup

    /// Creates the initial game state and registry with all necessary game data.
    /// - Returns: A tuple containing the initial `GameState` and `GameDefinitionRegistry`.
    @MainActor
    private static func createGameData() -> (GameState, GameDefinitionRegistry) {
        // Create locations
        let locations = [
            Location(
                id: "startRoom",
                name: "Cave Entrance",
                description: """
                    You stand at the entrance to a dark cave. Sunlight streams in from the \
                    opening behind you, but the passage ahead quickly disappears into darkness.
                    """,
                exits: [
                    .north: Exit(destination: "darkChamber"),
                    .south: Exit(destination: "outside")
                ]
            ),
            Location(
                id: "darkChamber",
                name: "Dark Chamber",
                description: """
                    This is a large cavern with walls that disappear into darkness overhead. \
                    Strange echoes bounce around as you move. The cave continues to the north, \
                    and the entrance is to the south.
                    """,
                exits: [
                    .north: Exit(destination: "treasureRoom"),
                    .south: Exit(destination: "startRoom")
                ]
            ),
            Location(
                id: "treasureRoom",
                name: "Treasure Room",
                description: """
                    This small chamber sparkles with reflections from numerous precious gems \
                    embedded in the walls. A stone pedestal in the center of the room holds \
                    what appears to be a golden crown.
                    """,
                exits: [
                    .south: Exit(destination: "darkChamber")
                ]
            ),
            Location(
                id: "outside",
                name: "Forest Path",
                description: """
                    A winding path leads through a dense forest. To the north, you can see \
                    the entrance to a cave.
                    """,
                exits: [
                    .north: Exit(destination: "startRoom")
                ],
                properties: [.inherentlyLit, .outside]
            )
        ]

        // Create items
        let items = [
            Item(
                id: "brassLantern",
                name: "lantern",
                adjectives: ["brass"],
                synonyms: ["lamp", "light"],
                description: "A sturdy brass lantern, useful for exploring dark places.",
                properties: [.takable, .lightSource],
                parent: .location("startRoom")
            ),
            Item(
                id: "goldCrown",
                name: "crown",
                adjectives: ["gold", "golden"],
                description: "A magnificent golden crown, adorned with precious jewels.",
                properties: [.takable],
                parent: .location("treasureRoom")
            ),
            Item(
                id: "stonePedestal",
                name: "pedestal",
                adjectives: ["stone"],
                description: "A weathered stone pedestal in the center of the room.",
                properties: [.surface],
                parent: .location("treasureRoom")
            )
        ]

        // Define verbs
        let verbs = [
            Verb(id: "look", synonyms: ["l"]),
            Verb(id: "examine", synonyms: ["x", "inspect"]),
            Verb(id: "inventory", synonyms: ["i"]),
            Verb(id: "take", synonyms: ["get", "grab", "pick"]),
            Verb(id: "drop", synonyms: ["put", "place"]),
            Verb(id: "go", synonyms: ["move", "walk"]),
            Verb(id: "north", synonyms: ["n"]),
            Verb(id: "south", synonyms: ["s"]),
            Verb(id: "east", synonyms: ["e"]),
            Verb(id: "west", synonyms: ["w"]),
            Verb(id: "light", synonyms: ["turn on"]),
            Verb(id: "extinguish", synonyms: ["turn off"])
        ]

        // Create player
        let player = Player(currentLocationID: "startRoom")

        // Build vocabulary
        let vocabulary = Vocabulary.build(items: items, verbs: verbs)

        // Create state
        let initialState = GameState.initial(
            initialLocations: locations,
            initialItems: items,
            initialPlayer: player,
            vocabulary: vocabulary
        )

        // Create registry with fuses and daemons
        let fuseDefinitions = [
            createLanternWarningFuse()
        ]

        let daemonDefinitions = [
            createLanternTimerDaemon()
        ]

        let registry = GameDefinitionRegistry(
            fuseDefinitions: fuseDefinitions,
            daemonDefinitions: daemonDefinitions
        )

        return (initialState, registry)
    }

    // MARK: - Game Hooks

    /// Custom logic that runs when the player enters a room.
    /// - Parameters:
    ///   - engine: The game engine.
    ///   - locationID: The ID of the location being entered.
    @MainActor
    private static func onEnterRoom(engine: GameEngine, locationID: LocationID) async {
        // Example: Check if this is the first time entering the treasure room
        if locationID == "treasureRoom" {
            let flag = "visited_treasure_room"
            let hasVisited = engine.getCurrentGameState().flags[flag] ?? false

            if !hasVisited {
                await engine.ioHandler.print("You've discovered the legendary treasure room!", style: .strong)
                engine.updateGameState { state in
                    state.flags[flag] = true
                    state.player.score += 10 // Award points for discovery
                }
            }
        }
    }

    /// Custom logic that runs at the start of each turn.
    /// - Parameter engine: The game engine.
    @MainActor
    private static func beforeEachTurn(engine: GameEngine) async {
        // Example: Add atmospheric messages based on location
        let locationID = engine.getCurrentGameState().player.currentLocationID
        let turnCount = engine.getCurrentGameState().player.moves

        // Only show atmospheric messages occasionally (every 5 turns)
        guard turnCount % 5 == 0 else { return }

        switch locationID {
        case "darkChamber":
            await engine.ioHandler.print("A faint dripping sound echoes in the darkness.", style: .emphasis)
        case "treasureRoom":
            await engine.ioHandler.print("The gems in the walls glitter mysteriously.", style: .emphasis)
        case "outside":
            await engine.ioHandler.print("A gentle breeze rustles the leaves around you.", style: .emphasis)
        default:
            break
        }
    }

    /// Custom logic that runs when examining specific items.
    /// - Parameters:
    ///   - engine: The game engine.
    ///   - itemID: The ID of the item being examined.
    /// - Returns: `true` if the examination was handled, `false` to use default behavior.
    @MainActor
    private static func onExamineItem(engine: GameEngine, itemID: ItemID) async -> Bool {
        // Example: Custom behavior when examining the lantern
        if itemID == "brassLantern" {
            let item = engine.itemSnapshot(with: itemID)

            // Get the battery life, if available
            if let batteryLife = await getLanternBatteryLife(engine: engine) {
                let status = item?.hasProperty(.on) == true ? "lit" : "unlit"

                await engine.ioHandler.print("""
                    A sturdy brass lantern, currently \(status). It appears to have about \
                    \(batteryLife) turns of battery life remaining.
                    """)
                return true
            }
        }

        // Return false to use default examination for other items
        return false
    }

    // MARK: - Game Execution

    /// Runs the game.
    public func run() async {
        if isRunning {
            print("Game is already running")
            return
        }

        isRunning = true
        await engine.run()
        isRunning = false
    }
}
