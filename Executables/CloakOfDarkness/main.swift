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
            properties: .surface,
            parent: .location("cloakroom")
        )

        let cloak = Item(
            id: "cloak",
            name: "cloak",
            adjectives: "handsome",
            "velvet",
            properties: .takable,
            .wearable,
            parent: .item("hook")
        )

        let message = Item(
            id: "message",
            name: "message",
            adjectives: "scrawled",
            synonyms: "floor", "sawdust", "dust",
            firstDescription: "There seems to be some sort of message scrawled in the sawdust on the floor.",
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
        // Define key for disturbed state
        let disturbedKey = "cod_disturbed"
        let initialGameState = GameState.initial(
            initialLocations: allLocations,
            initialItems: allItems,
            initialPlayer: initialPlayer,
            vocabulary: vocabulary,
            // Initialize disturbed state to 0
            gameSpecificState: [disturbedKey: AnyCodable(0)]
        )

        // Parser
        let parser = StandardParser()

        // Define Object-Specific Action Handlers
        let objectActionHandlers: [ItemID: ObjectActionHandler] = [
            "cloak": { engine, command in
                guard command.verbID == "examine" else { return false }
                await engine.output("The cloak is unnaturally dark.")
                return true // Handled
            },
            "message": { engine, command in
                guard command.verbID == "examine" else { return false }

                // Get disturbed count from game state
                let disturbedCount = engine.gameState.gameSpecificState?[disturbedKey]?.value as? Int ?? 0

                // Determine win/lose message based on ZIL logic
                let outcome = disturbedCount > 1 ? "lose." : "win."
                let output = "The message simply reads: \"You \(outcome)\""

                await engine.output(output)
                engine.quitGame() // Mimics V-QUIT
                return true // Action handled
            }
        ]

        // Define Room-Specific Action Handler for the Bar (BAR-R)
        let barActionHandler: RoomActionHandler = { engine, message in
            switch message {
            case .onEnter:
                // Update Bar light based on cloak status
                let cloakSnapshot = engine.itemSnapshot(with: "cloak")
                let isCloakWorn = cloakSnapshot?.parent == .player
                let barShouldBeLit = !isCloakWorn

                let currentBar = await engine.locationSnapshot(with: "bar")
                let isBarCurrentlyLit = currentBar?.properties.contains(.inherentlyLit) ?? false

                if barShouldBeLit && !isBarCurrentlyLit {
                    await engine.updateLocationProperties(id: "bar", adding: [.inherentlyLit])
                } else if !barShouldBeLit && isBarCurrentlyLit {
                    await engine.updateLocationProperties(id: "bar", removing: [.inherentlyLit])
                }
                return false // Do not block further actions

            case .beforeTurn(let command):
                // Handle groping message if Bar is dark and command is interactive
                let currentBar = await engine.locationSnapshot(with: "bar")
                let isBarDark = !(currentBar?.properties.contains(.inherentlyLit) ?? true)

                guard isBarDark else { return false } // Only act if dark

                let nonInteractiveVerbs: Set<VerbID> = [
                    "go", "look", "examine", "x", "l", "inventory", "quit", "score", "wait"
                    // Add other non-disturbing verbs as needed
                ]
                guard !nonInteractiveVerbs.contains(command.verbID) else { return false }

                // Print groping message and increment counter
                await engine.output("You grope around clumsily in the dark. Better be careful.")
                await engine.incrementGameSpecificStateCounter(key: disturbedKey)
                return false // Do not block the actual command

            case .afterTurn:
                // No action needed for M-END equivalent in BAR-R
                return false
            }
        }

        // --- Engine Setup ---
        let ioHandler = await ConsoleIOHandler()
        let engine = GameEngine(
            initialState: initialGameState,
            parser: parser,
            ioHandler: ioHandler,
            registry: GameDefinitionRegistry(
                // Register both object and room handlers
                objectActionHandlers: objectActionHandlers,
                roomActionHandlers: ["bar": barActionHandler]
            )
            // No custom hooks needed (onEnterRoom, beforeTurn are replaced by RoomActionHandler)
        )

        // --- Run Game ---
        await engine.run()

        print("\nThank you for playing Cloak of Darkness!")
    }
}
