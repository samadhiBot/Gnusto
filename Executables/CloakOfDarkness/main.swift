import Foundation
import GnustoEngine
import CloakOfDarknessGameData

/// Main entry point for the Cloak of Darkness replica.
struct CloakOfDarkness {
    @MainActor
    static func main() async {
        print("Initializing Cloak of Darkness...\n")

        // --- Setup using the shared game data library ---
        let (initialState, registry, onEnterRoom, beforeTurn) = CloakOfDarknessGameData.setup()

        // --- Engine Setup ---
        let parser = StandardParser()
        let ioHandler = await ConsoleIOHandler()
        let engine = GameEngine(
            initialState: initialState,
            parser: parser,
            ioHandler: ioHandler,
            registry: registry,
            onEnterRoom: onEnterRoom,
            beforeTurn: beforeTurn
        )

        // --- Run Game ---
        await engine.run()

        print("\nThank you for playing Cloak of Darkness!")
    }
}

// MARK: - Locations

@MainActor
extension CloakOfDarkness {
    static let foyer = Location(
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

    static let cloakroom = Location(
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

    static let bar = Location(
        id: "bar",
        name: "Bar",
        description: "The bar, much rougher than you'd have guessed after the opulence of the foyer to the north, is completely empty. There seems to be some sort of message scrawled in the sawdust on the floor.",
        exits: [
            .north: Exit(destination: "foyer"),
        ]
    )
}

// MARK: - Items

@MainActor
extension CloakOfDarkness {
    static let hook = Item(
        id: "hook",
        name: "hook",
        adjectives: "brass",
        synonyms: "peg",
        properties: .surface,
        parent: .location("cloakroom")
    )

    static let cloak = Item(
        id: "cloak",
        name: "cloak",
        adjectives: "handsome", "velvet",
        properties: .takable, .wearable, .worn,
        parent: .player
    )

    static let message = Item(
        id: "message",
        name: "message",
        properties: .ndesc, .read,
        parent: .location("bar"),
        readableText: "You have won!"
    )
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
