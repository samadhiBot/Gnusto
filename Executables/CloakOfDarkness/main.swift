import Foundation
import GnustoEngine

/// Main entry point for the Cloak of Darkness replica.
struct CloakOfDarkness {
    @MainActor
    static func main() async {
        print("Initializing Cloak of Darkness...\n")

        // --- World Setup ---
        // Setup remains local to the executable target.

        // Locations
        let foyer = Location(
            id: "foyer",
            name: "Foyer of the Opera House",
            description: """
                You are standing in a spacious hall, splendidly decorated in red and gold, which \
                serves as the lobby of the opera house. The walls are adorned with portraits of \
                famous singers, and the floor is covered with a thick crimson carpet. A grand \
                staircase leads upwards, and there are doorways to the south and west.
                """,
            exits: [
                .south: Exit(destination: "bar"),
                .west: Exit(destination: "cloakroom"),
            ],
            properties: .inherentlyLit
        )

        let cloakroom = Location(
            id: "cloakroom",
            name: "Cloakroom",
            description: """
                The walls of this small room were clearly once lined with hooks, though now only \
                one remains. The exit is a door to the east.
                """,
            exits: [
                .east: Exit(destination: "foyer"),
            ],
            properties: .inherentlyLit
        )

        let bar = Location(
            id: "bar",
            name: "Bar",
            description: "The bar, much rougher than you'd have guessed after the opulence of the foyer to the north, is completely empty. There seems to be some sort of message scrawled in the sawdust on the floor.",
            exits: [
                .north: Exit(destination: "foyer"),
            ]
        )

        // Items
        let hook = Item(
            id: "hook",
            name: "hook",
            adjectives: "brass",
            synonyms: "peg",
            parent: .location("cloakroom")
        )

        let cloak = Item(
            id: "cloak",
            name: "cloak",
            adjectives: "handsome", "velvet",
            properties: .takable, .wearable, .worn,
            parent: .player
        )

        let message = Item(
            id: "message",
            name: "message",
            properties: .ndesc, .read,
            parent: .location("bar"),
            readableText: "You have won!"
        )

        // Player
        let initialPlayer = Player(currentLocationID: "foyer")

        // All Items and Locations
        let allItems = [hook, cloak, message]
        let allLocations = [foyer, cloakroom, bar]

        // Vocabulary
        let vocabulary = Vocabulary.build(items: allItems)

        // Game State
        let gameState = GameState.initial(
            initialLocations: allLocations,
            initialItems: allItems,
            initialPlayer: initialPlayer,
            vocabulary: vocabulary
        )

        // Parser
        let parser = StandardParser()

        // Define Object-Specific Action Handlers
        let objectActionHandlers: [ItemID: ObjectActionHandler] = [
            "cloak": { engine, command in
                guard command.verbID == "examine" else { return false }
                await engine.output("The cloak is unnaturally dark.")
                return true
            },
            "message": { engine, command in
                // Ensure we are examining the message in the bar
                guard
                    command.verbID == "examine",
                    engine.playerLocationID() == "bar"
                else { return false } // Not the right action/location

                // Retrieve the disturbed counter from game-specific state
                // ZIL DISTURBED global: 0=safe, 1=safe(warning given), 2+=lose
                let disturbedCount = engine.getGameSpecificStateValue(key: "disturbedCounter")?.value as? Int ?? 0

                await engine.output("The message simply reads: \"You ")

                if disturbedCount > 1 {
                    await engine.output("lose.\"", style: .normal, newline: false)
                    engine.quitGame()
                } else {
                    await engine.output("win.\"", style: .normal, newline: false)
                    engine.quitGame()
                }
                // finishGame signals the engine loop should stop, but we still handled the action.
                return true
            }
        ]

        // --- Hooks ---
        // Define beforeTurn hook to handle disturbing things in the dark
        let beforeTurn: (@MainActor @Sendable (GameEngine, Command) async -> Void)? = { engine, command in
            let locationID = engine.playerLocationID()
            // Only apply in the bar
            guard locationID == "bar" else { return }

            // --- Dynamic Light Check for Bar ---
            // Check cloak status *every* turn while in the bar
            let cloakIsWorn = await engine.itemSnapshot(with: "cloak")?.hasProperty(.worn) ?? false
            if cloakIsWorn {
                // Ensure bar is dark if cloak is worn
                await engine.updateLocationProperties(id: "bar", removing: .isLit)
            } else {
                // Ensure bar is lit if cloak is not worn
                await engine.updateLocationProperties(id: "bar", adding: .isLit)
            }
            // -------------------------------------

            // Now, check if the bar is *currently* dark for the groping message
            let isLit = await engine.locationSnapshot(with: locationID)?.properties.contains(.isLit) ?? false
            guard !isLit else { return } // Only apply groping check if still dark

            // Check if the command is one that disturbs things in the dark
            // ZIL logic: Increment if NOT LOOK, THINK-ABOUT, or WALK NORTH
            let verb = command.verbID
            let isSafeVerb = verb == "look" || verb == "think-about"
            // Special check for WALK NORTH (leaving the bar)
            let isLeavingNorth = verb == "go" && command.preposition == "north" // Direct comparison
                                                                                  // Or adjust based on how GO handler sets Command fields

            if !isSafeVerb && !isLeavingNorth {
                await engine.output("You grope around clumsily in the dark. Better be careful.", style: .normal)
                // Increment the counter
                engine.incrementGameSpecificStateCounter(key: "disturbedCounter")
            }
        }

        // Define onEnterRoom hook to handle lighting in the bar
        let onEnterRoom: (@MainActor @Sendable (GameEngine, LocationID) async -> Void)? = { engine, enteredLocationID in
            // Only apply when entering the bar
            guard enteredLocationID == "bar" else { return }

            // Check if cloak is worn
            let cloakIsWorn = engine.itemSnapshot(with: "cloak")?.hasProperty(.worn) ?? false

            // Update bar's light status
            if cloakIsWorn {
                // Cloak worn: Make bar dark by removing .isLit
                engine.updateLocationProperties(id: "bar", removing: .isLit)
            } else {
                // Cloak not worn: Make bar lit by adding .isLit
                engine.updateLocationProperties(id: "bar", adding: .isLit)
            }
        }

        // --- Engine Setup ---
        let ioHandler = await ConsoleIOHandler()
        let engine = GameEngine(
            initialState: gameState,
            parser: parser,
            ioHandler: ioHandler,
            registry: GameDefinitionRegistry(
                objectActionHandlers: objectActionHandlers
            ),
            onEnterRoom: onEnterRoom,
            beforeTurn: beforeTurn
        )

        // --- Run Game ---
        await engine.run()

        print("\nThank you for playing Cloak of Darkness!")
    }
}

// Manually handle async main
extension CloakOfDarkness {
    static func main() {
        Task {
            await main() // Call the async main function
        }
        // Keep the process alive until all tasks complete
        RunLoop.main.run()
    }
}

// Call the main function to start the process
CloakOfDarkness.main()
