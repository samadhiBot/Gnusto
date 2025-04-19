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
            ]
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
            ]
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
            adjectives: "handsome",
            "velvet",
            properties: .takable,
            .wearable,
            parent: .item("hook")
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
            "message": { engine, command in
                guard
                    command.verbID == "examine",
                    engine.playerLocationID() == "bar"
                else { return false }

                let cloakSnapshot = engine.itemSnapshot(with: "cloak")
                guard cloakSnapshot?.parent == .player else {
                    return false
                }

                await engine.output("\n*** You have won ***")
                engine.quitGame()
                return true
            }
        ]

        // --- Engine Setup ---
        let ioHandler = await ConsoleIOHandler()
        let engine = GameEngine(
            initialState: gameState,
            parser: parser,
            ioHandler: ioHandler,
            registry: GameDefinitionRegistry(
                objectActionHandlers: objectActionHandlers
            )
        )

        // --- Run Game ---
        await engine.run()

        print("\nThank you for playing Cloak of Darkness!")
    }
}
