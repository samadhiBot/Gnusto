import Foundation
import GnustoEngine

/// A simple example game that demonstrates various Gnusto engine features.
/// This serves as both documentation and a reference implementation.
@MainActor
public class ExampleGame {
    // MARK: - Properties

    /// The game engine instance that manages the game state.
    private let engine: GameEngine

    /// The IO handler for printing messages
    private let ioHandler: IOHandler

    /// Flag to track if the game is currently running.
    private var isRunning = false

    // MARK: - Constants

    /// Constants for the lantern functionality
    private enum LanternConstants {
        /// Default number of turns the lantern stays lit
        static let defaultBatteryLife = 200

        /// Number of turns at which the "low battery" warning appears
        static let lowBatteryThreshold = 30

        /// ID for the lantern item
        static let lanternID: ItemID = "brassLantern"

        /// ID for the lantern timer daemon
        static let timerDaemonID: DaemonID = "lanternTimerDaemon"

        /// ID for the low battery warning fuse
        static let lowBatteryWarningFuseID: FuseID = "lanternLowBatteryWarning"

        /// Key for the battery life in gameSpecificState
        static let batteryLifeKey = "lanternBatteryLife"

        /// Flag for pending messages
        static let pendingMessageKey = "pendingMessage"
    }

    /// Constants for weather simulation
    private enum WeatherConstants {
        /// ID for the weather daemon
        static let weatherDaemonID: DaemonID = "weatherDaemon"

        /// Key for weather state
        static let weatherStateKey = "weatherState"
    }

    /// Constants for puzzle elements
    private enum PuzzleConstants {
        /// ID for the locked door
        static let doorID: ItemID = "ironDoor"

        /// ID for the key
        static let keyID: ItemID = "rustyKey"

        /// Flag for door unlocked state
        static let doorUnlockedFlag = "iron_door_unlocked"
    }

    // MARK: - Initialization

    /// Creates a new example game with all the necessary components set up.
    /// - Parameter customIOHandler: An optional custom IO handler. If nil, a ConsoleIOHandler is used.
    public init(customIOHandler: IOHandler? = nil) async {
        // Set up the game data
        let (initialState, registry) = ExampleGame.createGameData()

        // Create the parser
        let parser = StandardParser()

        // Create or use the provided IO handler
        let ioHandler: IOHandler
        if let customIOHandler = customIOHandler {
            ioHandler = customIOHandler
        } else {
            ioHandler = await ConsoleIOHandler()
        }
        self.ioHandler = ioHandler

        // Create a scope resolver
        let scopeResolver = ScopeResolver()

        // Create the engine with the initial components
        engine = GameEngine(
            initialState: initialState,
            parser: parser,
            ioHandler: ioHandler,
            scopeResolver: scopeResolver,
            registry: registry,
            onEnterRoom: ExampleGame.onEnterRoom,
            beforeTurn: ExampleGame.beforeEachTurn,
            onExamineItem: ExampleGame.onExamineItem
        )

        // Set up the lantern timer
        await setupLanternTimer()

        // Display an introduction message
        await ioHandler.print("Welcome to the Gnusto Example Adventure!", style: .strong)
        await ioHandler.print("""
            This small adventure demonstrates various features of the Gnusto Engine.
            Type 'help' for hints on what to try.
            """, style: .emphasis)
        await ioHandler.print("", style: .normal)
    }

    // MARK: - Game Data Setup

    /// Creates the initial game state and registry with all necessary game data.
    /// - Returns: A tuple containing the initial `GameState` and `GameDefinitionRegistry`.
    @MainActor
    private static func createGameData() -> (GameState, GameDefinitionRegistry) {
        // Create locations
        let locations = [
            // Starting location
            Location(
                id: "startRoom",
                name: "Cave Entrance",
                description: """
                    You stand at the entrance to a dark cave. Sunlight streams in from the \
                    opening behind you, but the passage ahead quickly disappears into darkness.
                    """,
                exits: [
                    .north: Exit(destination: "darkChamber"),
                    .south: Exit(destination: "outside"),
                    .east: Exit(destination: "narrowPassage")
                ]
            ),

            // Main cave areas
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
                    .south: Exit(destination: "startRoom"),
                    .west: Exit(destination: "crystalGrotto")
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

            // Outdoor areas
            Location(
                id: "outside",
                name: "Forest Path",
                description: """
                    A winding path leads through a dense forest. To the north, you can see \
                    the entrance to a cave. A small stream flows to the west.
                    """,
                exits: [
                    .north: Exit(destination: "startRoom"),
                    .west: Exit(destination: "streamBank")
                ],
                properties: [.inherentlyLit, .outside]
            ),
            Location(
                id: "streamBank",
                name: "Stream Bank",
                description: """
                    You stand beside a clear, bubbling stream. The water flows from north to south, \
                    disappearing into thick undergrowth. The forest path is to the east.
                    """,
                exits: [
                    .east: Exit(destination: "outside")
                ],
                properties: [.inherentlyLit, .outside]
            ),

            // Additional cave sections
            Location(
                id: "narrowPassage",
                name: "Narrow Passage",
                description: """
                    The walls close in here, forming a tight corridor that slopes downward. \
                    You have to duck to avoid hitting your head on the low ceiling. The passage \
                    continues east, and the cave entrance is to the west.
                    """,
                exits: [
                    .west: Exit(destination: "startRoom"),
                    .east: Exit(destination: "ironDoorRoom")
                ]
            ),
            Location(
                id: "ironDoorRoom",
                name: "Iron Door Chamber",
                description: """
                    This small chamber appears to be a dead end. The narrow passage leads back \
                    to the west. The eastern wall is dominated by a massive iron door.
                    """,
                exits: [
                    .west: Exit(destination: "narrowPassage"),
                    // East exit is added conditionally when the door is unlocked
                ]
            ),
            Location(
                id: "hiddenVault",
                name: "Hidden Vault",
                description: """
                    Beyond the iron door lies a secret vault. The walls are lined with carvings \
                    of ancient runes that seem to glow with a faint, otherworldly light. A small \
                    altar stands in the center of the room.
                    """,
                exits: [
                    .west: Exit(destination: "ironDoorRoom")
                ]
            ),
            Location(
                id: "crystalGrotto",
                name: "Crystal Grotto",
                description: """
                    This spectacular cavern is filled with towering crystal formations that \
                    catch and reflect any light in dazzling patterns. The floor is studded with \
                    smaller crystals in various hues. The dark chamber lies to the east.
                    """,
                exits: [
                    .east: Exit(destination: "darkChamber"),
                    .down: Exit(destination: "undergroundPool")
                ]
            ),
            Location(
                id: "undergroundPool",
                name: "Underground Pool",
                description: """
                    A still, dark pool of water occupies most of this chamber. The water is so \
                    clear and still that it mirrors the ceiling perfectly. Faint phosphorescent \
                    fungi on the walls cast everything in a ghostly blue glow.
                    """,
                exits: [
                    .up: Exit(destination: "crystalGrotto")
                ],
                properties: [.inherentlyLit]  // The phosphorescent fungi provide minimal light
            )
        ]

        // Create items
        let items = [
            // Player tools
            Item(
                id: "brassLantern",
                name: "lantern",
                adjectives: ["brass"],
                synonyms: ["lamp", "light"],
                description: "A sturdy brass lantern, useful for exploring dark places.",
                properties: [.takable, .lightSource],
                parent: .location("startRoom")
            ),

            // Treasures
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
            ),

            // Puzzle items
            Item(
                id: "rustyKey",
                name: "key",
                adjectives: ["rusty", "iron"],
                description: "An old, rusty iron key. It looks heavy and ornate.",
                properties: [.takable],
                parent: .location("streamBank")
            ),
            Item(
                id: "ironDoor",
                name: "door",
                adjectives: ["iron", "massive"],
                description: """
                    A massive door made of solid iron. Ancient runes are inscribed around its \
                    frame. There's a keyhole below the handle.
                    """,
                properties: [.door],
                parent: .location("ironDoorRoom")
            ),

            // Container example
            Item(
                id: "woodenChest",
                name: "chest",
                adjectives: ["wooden", "old"],
                description: "An old wooden chest with brass fittings. The lid is currently closed.",
                properties: [.container, .openable],
                parent: .location("crystalGrotto")
            ),
            Item(
                id: "silverCoin",
                name: "coin",
                adjectives: ["silver", "ancient"],
                description: "An ancient silver coin with unfamiliar markings.",
                properties: [.takable],
                parent: .item("woodenChest")
            ),

            // Atmospheric items
            Item(
                id: "mysteriousAltar",
                name: "altar",
                adjectives: ["mysterious", "stone"],
                description: """
                    A stone altar with intricate carvings. A shallow basin on top contains an \
                    iridescent liquid that seems to shift colors as you watch.
                    """,
                properties: [.ndesc],
                parent: .location("hiddenVault")
            ),
            Item(
                id: "largeGem",
                name: "gem",
                adjectives: ["large", "glowing"],
                synonyms: ["crystal", "stone"],
                description: """
                    A large gem that seems to pulse with an inner light. As you examine it, \
                    the color shifts between deep blue and violet.
                    """,
                properties: [.takable, .lightSource],
                parent: .location("hiddenVault")
            ),
            Item(
                id: "clearWater",
                name: "water",
                adjectives: ["clear", "cold"],
                synonyms: ["stream", "liquid"],
                description: "Clear, cold water that looks refreshing.",
                properties: [.ndesc],
                parent: .location("streamBank")
            ),
            Item(
                id: "darkPool",
                name: "pool",
                adjectives: ["dark", "still"],
                synonyms: ["water"],
                description: """
                    The water is perfectly still and incredibly clear. Looking down, you can see \
                    small, strange artifacts scattered on the bottom, just out of reach.
                    """,
                properties: [.ndesc],
                parent: .location("undergroundPool")
            )
        ]

        // Define verbs
        let verbs = [
            // Basic navigation and interaction
            Verb(id: "look", synonyms: ["l"]),
            Verb(id: "examine", synonyms: ["x", "inspect"]),
            Verb(id: "inventory", synonyms: ["i"]),
            Verb(id: "take", synonyms: ["get", "grab", "pick"]),
            Verb(id: "drop", synonyms: ["put", "place"]),
            Verb(id: "go", synonyms: ["move", "walk"]),

            // Directions
            Verb(id: "north", synonyms: ["n"]),
            Verb(id: "south", synonyms: ["s"]),
            Verb(id: "east", synonyms: ["e"]),
            Verb(id: "west", synonyms: ["w"]),
            Verb(id: "up", synonyms: ["u"]),
            Verb(id: "down", synonyms: ["d"]),

            // Light interaction
            Verb(id: "light", synonyms: ["turn on"]),
            Verb(id: "extinguish", synonyms: ["turn off"]),

            // Container interaction
            Verb(id: "open", synonyms: ["unlock"]),
            Verb(id: "close", synonyms: ["shut"]),

            // Special interactions
            Verb(id: "help", synonyms: ["hint", "info"]),
            Verb(id: "drink", synonyms: ["sip", "taste"]),
            Verb(id: "unlock", synonyms: []),
            Verb(id: "touch", synonyms: ["feel"])
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
        let registry = GameDefinitionRegistry(
            fuseDefinitions: [
                createLanternWarningFuse()
            ],
            daemonDefinitions: [
                createLanternTimerDaemon(),
                createWeatherDaemon()
            ]
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
        // Check for special room behaviors
        switch locationID {
        case "treasureRoom":
            // First-time treasure room discovery
            let flag = "visited_treasure_room"
            let hasVisited = engine.getCurrentGameState().flags[flag] ?? false

            if !hasVisited {
                await printMessage(engine: engine, "You've discovered the legendary treasure room!", style: .strong)
                engine.updateGameState { state in
                    state.flags[flag] = true
                    state.player.score += 10 // Award points for discovery
                }
            }

        case "undergroundPool":
            // Special atmosphere for the underground pool
            await printMessage(engine: engine, """
                The water in the pool ripples slightly as you enter, \
                disrupting the perfect mirror-like surface.
                """, style: .emphasis)

        case "hiddenVault":
            // First-time vault discovery
            let flag = "visited_vault"
            let hasVisited = engine.getCurrentGameState().flags[flag] ?? false

            if !hasVisited {
                await printMessage(engine: engine, """
                    As you enter, the runes on the walls pulse with energy. \
                    You feel you've discovered something truly ancient and powerful.
                    """, style: .strong)
                engine.updateGameState { state in
                    state.flags[flag] = true
                    state.player.score += 15 // Award points for discovery
                }
            }

        case "ironDoorRoom":
            // Check if door should be added as an exit
            if engine.getCurrentGameState().flags[PuzzleConstants.doorUnlockedFlag] == true {
                // Door is unlocked, ensure the exit exists
                let location = engine.getCurrentGameState().locations[locationID]
                if location?.exits[.east] == nil {
                    engine.updateGameState { state in
                        state.locations[locationID]?.exits[.east] = Exit(destination: "hiddenVault")
                    }
                }
            }

        default:
            break
        }

        // Dynamic darkness handling for rooms without inherent light
        let currentLocation = engine.getCurrentGameState().locations[locationID]
        if currentLocation?.hasProperty(.inherentlyLit) != true {
            // Check if player has a light source
            let hasLight = await hasActiveLight(engine: engine)

            if !hasLight {
                await printMessage(engine: engine, """
                    It is pitch black. You are likely to be eaten by a grue.
                    """, style: .strong)
            }
        }
    }

    /// Custom logic that runs at the start of each turn.
    /// - Parameter engine: The game engine.
    @MainActor
    private static func beforeEachTurn(engine: GameEngine) async {
        // Check for pending messages from daemons or fuses
        if let pendingMessage = engine.getCurrentGameState().gameSpecificState?[LanternConstants.pendingMessageKey]?.value as? String {
            await printMessage(engine: engine, pendingMessage)

            // Clear the pending message
            engine.updateGameState { state in
                state.gameSpecificState?[LanternConstants.pendingMessageKey] = nil
            }
        }

        // Process any custom commands
        // Get current input as processed by the parser
        let command = engine.getCurrentGameState().parser.currentCommand
        if await processCustomCommands(engine: engine, command: command) {
            // If we handled it, don't proceed with normal messages
            return
        }

        // Example: Add atmospheric messages based on location
        let locationID = engine.getCurrentGameState().player.currentLocationID
        let turnCount = engine.getCurrentGameState().player.moves

        // Only show atmospheric messages occasionally (every 5 turns)
        guard turnCount % 5 == 0 else { return }

        switch locationID {
        case "darkChamber":
            await printMessage(engine: engine, "A faint dripping sound echoes in the darkness.", style: .emphasis)
        case "treasureRoom":
            await printMessage(engine: engine, "The gems in the walls glitter mysteriously.", style: .emphasis)
        case "outside", "streamBank":
            // Weather effects for outside areas
            if let weatherState = engine.getCurrentGameState().gameSpecificState?[WeatherConstants.weatherStateKey]?.value as? String {
                switch weatherState {
                case "sunny":
                    await printMessage(engine: engine, "Sunlight filters through the trees above you.", style: .emphasis)
                case "cloudy":
                    await printMessage(engine: engine, "Gray clouds drift overhead, dimming the light.", style: .emphasis)
                case "rainy":
                    await printMessage(engine: engine, "Raindrops patter on the leaves around you.", style: .emphasis)
                default:
                    break
                }
            }
        case "crystalGrotto":
            await printMessage(engine: engine, "The crystals around you shimmer with refracted light.", style: .emphasis)
        case "undergroundPool":
            await printMessage(engine: engine, "The water in the pool is eerily still, like black glass.", style: .emphasis)
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
        switch itemID {
        case LanternConstants.lanternID:
            // Custom lantern examination
            let item = engine.itemSnapshot(with: itemID)

            // Get the battery life, if available
            if let batteryLife = engine.getCurrentGameState().gameSpecificState?[LanternConstants.batteryLifeKey]?.value as? Int {
                let status = item?.hasProperty(.on) == true ? "lit" : "unlit"

                let description = """
                    A sturdy brass lantern, currently \(status). It appears to have about \
                    \(batteryLife) turns of battery life remaining.
                    """

                await printMessage(engine: engine, description)
                return true
            }

        case "darkPool":
            // Custom pool examination
            await printMessage(engine: engine, """
                Looking into the clear, dark water, you can see what look like ancient \
                artifacts resting on the bottom. They're just out of reach, but seem \
                to be made of precious metals.
                """)
            return true

        case "ironDoor":
            // Custom door examination
            let isUnlocked = engine.getCurrentGameState().flags[PuzzleConstants.doorUnlockedFlag] == true

            if isUnlocked {
                await printMessage(engine: engine, """
                    A massive iron door that stands open now, revealing a passage to the east. \
                    The ancient runes around its frame glow with a faint blue light.
                    """)
            } else {
                await printMessage(engine: engine, """
                    A massive iron door, firmly shut. Ancient runes are inscribed around its \
                    frame, and there's a keyhole below the heavy handle. It appears to be locked.
                    """)
            }
            return true

        case "mysteriousAltar":
            // Custom altar examination
            await printMessage(engine: engine, """
                The altar is carved from a single piece of dark stone. The basin on top \
                contains a swirling, iridescent liquid that seems to change colors as you watch. \
                The liquid gives off a faint, pleasant aroma.
                """)
            return true

        default:
            return false
        }

        return false
    }

    /// Process custom commands like "help" or special actions
    /// - Parameters:
    ///   - engine: The game engine
    ///   - command: The current command
    /// - Returns: `true` if command was handled, `false` otherwise
    @MainActor
    private static func processCustomCommands(engine: GameEngine, command: Command?) async -> Bool {
        // Process special verbs
        guard let command = command, let verbID = command.verbID else { return false }

        switch verbID {
        case "help":
            await printMessage(engine: engine, """
                Gnusto Example Game Help:
                - Try exploring the cave with a lantern
                - Look for items that can be picked up and used
                - The iron door requires a key to unlock
                - The lantern has limited battery life
                - Weather changes affect outdoor locations

                Sample commands to try:
                "take lantern", "light lantern", "examine pool",
                "open chest", "unlock door with key"
                """, style: .strong)
            return true

        case "unlock":
            // Handle unlocking the iron door
            if command.directObject == "ironDoor" && command.indirectObject == "rustyKey" {
                // Get player's held items
                let gameState = engine.getCurrentGameState()
                let playerItems = gameState.player.inventory
                let hasKey = playerItems.contains(PuzzleConstants.keyID)

                if !hasKey {
                    await printMessage(engine: engine, "You don't have the key.")
                    return true
                }

                // Check if already unlocked
                if engine.getCurrentGameState().flags[PuzzleConstants.doorUnlockedFlag] == true {
                    await printMessage(engine: engine, "The door is already unlocked.")
                    return true
                }

                // Unlock the door
                await printMessage(engine: engine, """
                    You insert the rusty key into the lock. With effort, it turns with a \
                    heavy clunk. The door swings open, revealing a passage to the east.
                    """, style: .strong)

                engine.updateGameState { state in
                    state.flags[PuzzleConstants.doorUnlockedFlag] = true
                    state.locations["ironDoorRoom"]?.exits[.east] = Exit(destination: "hiddenVault")
                    state.player.score += 20 // Award points for solving puzzle
                }
                return true
            }
            return false

        case "drink":
            // Handle drinking from various water sources
            if command.directObject == "clearWater" {
                await printMessage(engine: engine, "You take a drink of the cold, clear water. It's refreshing!")
                return true
            } else if command.directObject == "darkPool" {
                await printMessage(engine: engine, """
                    You consider drinking from the dark pool, but something tells you \
                    that might not be wise.
                    """)
                return true
            }
            return false

        case "touch":
            // Handle touching the crystals in the grotto
            if let directObject = command.directObject,
               directObject == "crystal" &&
               engine.getCurrentGameState().player.currentLocationID == "crystalGrotto" {
                await printMessage(engine: engine, """
                    As your fingers brush against the crystal, it emits a clear, pure tone \
                    that echoes through the grotto. Other crystals seem to respond with \
                    harmonizing tones of their own.
                    """, style: .emphasis)
                return true
            }
            return false

        default:
            return false
        }
    }

    /// Helper function to print messages using the engine's IOHandler
    @MainActor
    private static func printMessage(engine: GameEngine, _ text: String, style: TextStyle = .normal) async {
        await engine.print(text, style: style)
    }

    /// Check if the player has an active light source
    @MainActor
    private static func hasActiveLight(engine: GameEngine) async -> Bool {
        // Get player's inventory
        let gameState = engine.getCurrentGameState()
        let playerItems = gameState.player.inventory

        // Check each item to see if it's a light source and turned on
        for itemID in playerItems {
            let item = gameState.items[itemID]
            if item?.hasProperty(.lightSource) == true && item?.hasProperty(.on) == true {
                return true
            }
        }

        // Also check if the player is holding the glowing gem
        if playerItems.contains("largeGem") {
            return true
        }

        return false
    }

    // MARK: - Lantern Timer Implementation

    /// Creates a daemon definition for the lantern timer.
    /// - Returns: A `DaemonDefinition` that tracks the lantern's battery consumption
    @MainActor
    private static func createLanternTimerDaemon() -> DaemonDefinition {
        return DaemonDefinition(
            id: LanternConstants.timerDaemonID,
            frequency: 1 // Run every turn
        ) { engine in
            // Closure runs every turn to update lantern battery

            let gameState = engine.getCurrentGameState()

            // Precondition: Lantern exists in the game
            guard let lantern = gameState.items[LanternConstants.lanternID] else {
                Swift.print("Warning: Lantern item not found in game state")
                return
            }

            // Only proceed if lantern is lit
            guard lantern.hasProperty(.lightSource) && lantern.hasProperty(.on) else {
                return
            }

            // Get current battery life from game state
            // Default to defaultBatteryLife if not set
            let batteryLifeValue = gameState.gameSpecificState?[LanternConstants.batteryLifeKey]?.value as? Int
                ?? LanternConstants.defaultBatteryLife

            // Decrement battery life by 1
            let newBatteryLife = max(0, batteryLifeValue - 1)

            // Update game state with new battery life
            engine.updateGameState { state in
                // Ensure gameSpecificState exists
                if state.gameSpecificState == nil {
                    state.gameSpecificState = [:]
                }

                state.gameSpecificState?[LanternConstants.batteryLifeKey] = AnyCodable(newBatteryLife)
            }

            // Handle different battery states
            switch newBatteryLife {
            case LanternConstants.lowBatteryThreshold:
                // When we hit the threshold, add a fuse for the final warning
                let _ = engine.addFuse(id: LanternConstants.lowBatteryWarningFuseID)

                // Store message to be displayed on next turn
                engine.updateGameState { state in
                    if state.gameSpecificState == nil {
                        state.gameSpecificState = [:]
                    }
                    state.gameSpecificState?[LanternConstants.pendingMessageKey] = AnyCodable("Your lantern is getting dim.")
                }

            case 0:
                // Battery is fully depleted
                // Store message to be displayed on next turn
                engine.updateGameState { state in
                    if state.gameSpecificState == nil {
                        state.gameSpecificState = [:]
                    }
                    state.gameSpecificState?[LanternConstants.pendingMessageKey] = AnyCodable("Your lantern has run out of power and is now dark.")
                }

                // Turn off the lantern
                engine.removeItemProperty(itemID: LanternConstants.lanternID, property: .on)

                // Optional: Add darkness-related consequences here
                // (e.g., being eaten by a grue if in a dungeon location)

            default:
                break  // No action needed for other battery levels
            }
        }
    }

    /// Creates a weather daemon that changes conditions outside
    @MainActor
    private static func createWeatherDaemon() -> DaemonDefinition {
        return DaemonDefinition(
            id: WeatherConstants.weatherDaemonID,
            frequency: 10 // Change every 10 turns
        ) { engine in
            // Only affects outdoor locations
            let locationID = engine.getCurrentGameState().player.currentLocationID
            let location = engine.getCurrentGameState().locations[locationID]

            // Randomly change the weather
            let weatherStates = ["sunny", "cloudy", "rainy"]
            let currentWeather = engine.getCurrentGameState().gameSpecificState?[WeatherConstants.weatherStateKey]?.value as? String ?? "sunny"

            // Choose a different weather state
            var newWeather = currentWeather
            while newWeather == currentWeather {
                newWeather = weatherStates.randomElement() ?? "sunny"
            }

            // Update the weather state
            engine.updateGameState { state in
                if state.gameSpecificState == nil {
                    state.gameSpecificState = [:]
                }
                state.gameSpecificState?[WeatherConstants.weatherStateKey] = AnyCodable(newWeather)
            }

            // Show weather change message if player is outside
            if location?.hasProperty(.outside) == true {
                var message = ""
                switch newWeather {
                case "sunny":
                    message = "The clouds part, allowing sunlight to stream down through the trees."
                case "cloudy":
                    message = "Clouds roll in, casting the forest in shadow."
                case "rainy":
                    message = "Rain begins to fall gently through the forest canopy."
                default:
                    break
                }

                if !message.isEmpty {
                    engine.updateGameState { state in
                        state.gameSpecificState?[LanternConstants.pendingMessageKey] = AnyCodable(message)
                    }
                }
            }
        }
    }

    /// Creates a fuse definition for the lantern's low battery warning.
    /// - Returns: A `FuseDefinition` that will trigger a final warning before the lantern dies
    @MainActor
    private static func createLanternWarningFuse() -> FuseDefinition {
        return FuseDefinition(
            id: LanternConstants.lowBatteryWarningFuseID,
            initialTurns: LanternConstants.lowBatteryThreshold / 2
        ) { engine in
            // This runs when the fuse triggers (halfway through the remaining battery life)
            // Store message to be displayed on next turn
            engine.updateGameState { state in
                if state.gameSpecificState == nil {
                    state.gameSpecificState = [:]
                }
                state.gameSpecificState?[LanternConstants.pendingMessageKey] = AnyCodable("Your lantern is getting very dim and will soon run out of power!")
            }
        }
    }

    /// Initializes the lantern timer system by registering the daemon and setting initial battery state.
    /// - Parameter initialBatteryLife: Optional custom initial battery life
    @MainActor
    private func setupLanternTimer(initialBatteryLife: Int = LanternConstants.defaultBatteryLife) async {
        // Make sure the lantern exists
        guard engine.getCurrentGameState().items[LanternConstants.lanternID] != nil else {
            Swift.print("Cannot setup lantern timer: lantern item not found")
            return
        }

        // Set initial battery life in game state
        engine.updateGameState { state in
            // Initialize gameSpecificState if it doesn't exist
            if state.gameSpecificState == nil {
                state.gameSpecificState = [:]
            }
            state.gameSpecificState?[LanternConstants.batteryLifeKey] = AnyCodable(initialBatteryLife)

            // Set initial weather
            state.gameSpecificState?[WeatherConstants.weatherStateKey] = AnyCodable("sunny")
        }

        // Register the daemon to start tracking battery life
        let _ = engine.registerDaemon(id: LanternConstants.timerDaemonID)

        // Register the weather daemon
        let _ = engine.registerDaemon(id: WeatherConstants.weatherDaemonID)
    }

    // MARK: - Helper Methods

    /// Print a message to the player
    @MainActor
    public func print(_ text: String, style: TextStyle = .normal) async {
        await ioHandler.print(text, style: style)
    }

    /// Print a blank line
    @MainActor
    public func printBlankLine() async {
        await ioHandler.print("", style: .normal)
    }

    // MARK: - Game Execution

    /// Runs the game.
    public func run() async {
        if isRunning {
            Swift.print("Game is already running")
            return
        }

        isRunning = true
        await engine.run()
        isRunning = false
    }
}
