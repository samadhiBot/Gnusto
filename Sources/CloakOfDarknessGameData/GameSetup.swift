import Foundation
import GnustoEngine

/// Provides the setup components for the Cloak of Darkness game.
@MainActor
public struct CloakOfDarknessGameData {

    // MARK: - Object Handlers (Static is okay)
    static let objectActionHandlers: [ItemID: ObjectActionHandler] = [
        "cloak": { engine, command in
            guard command.verbID == "examine" else { return false }
            await engine.output("The cloak is unnaturally dark.")
            return true
        },
        "message": { engine, command in
            guard command.verbID == "examine", engine.playerLocationID() == "bar" else { return false }
            guard engine.locationSnapshot(with: "bar")?.properties.contains(.isLit) ?? false else {
                await engine.output("It's too dark to do that.")
                return true
            }
            let disturbedCount = engine.getGameSpecificStateValue(key: "disturbedCounter")?.value as? Int ?? 0
            await engine.output("The message simply reads: \"You ", newline: false)
            if disturbedCount > 1 {
                await engine.output("lose.\"", style: .normal, newline: false)
                engine.quitGame()
            } else {
                await engine.output("win.\"", style: .normal, newline: false)
                engine.quitGame()
            }
            return true
        }
    ]

    // MARK: - Hooks (Static is okay)
    static let beforeTurnHook: (@MainActor @Sendable (GameEngine, Command) async -> Void)? = { engine, command in
        let locationID = engine.playerLocationID()
        guard locationID == "bar" else { return }
        let cloakIsWorn = engine.itemSnapshot(with: "cloak")?.hasProperty(.worn) ?? false
        if cloakIsWorn {
            engine.updateLocationProperties(id: "bar", removing: .isLit)
        } else {
            engine.updateLocationProperties(id: "bar", adding: .isLit)
        }
        let isLit = engine.locationSnapshot(with: locationID)?.properties.contains(.isLit) ?? false
        guard !isLit else { return }
        let verb = command.verbID
        let isSafeVerb = verb == "look" || verb == "examine" || verb == "drop" || verb == "inventory" || verb == "remove"
        let isLeavingNorth = verb == "go" && command.direction == .north
        if !isSafeVerb && !isLeavingNorth {
            await engine.output("You grope around clumsily in the dark. Better be careful.", style: .normal)
            engine.incrementGameSpecificStateCounter(key: "disturbedCounter")
        }
    }

    static let onEnterRoomHook: (@MainActor @Sendable (GameEngine, LocationID) async -> Void)? = { engine, enteredLocationID in
        guard enteredLocationID == "bar" else { return }
        let cloakIsWorn = engine.itemSnapshot(with: "cloak")?.hasProperty(.worn) ?? false
        if cloakIsWorn {
            engine.updateLocationProperties(id: "bar", removing: .isLit)
        } else {
            engine.updateLocationProperties(id: "bar", adding: .isLit)
        }
    }

    // MARK: - Public Setup Function

    /// Sets up and returns the initial components for the Cloak of Darkness game.
    /// - Returns: A tuple containing the initial `GameState`, `GameDefinitionRegistry`, `onEnterRoom` hook, and `beforeTurn` hook.
    @MainActor public static func setup() -> (
        initialState: GameState,
        registry: GameDefinitionRegistry,
        onEnterRoom: (@MainActor @Sendable (GameEngine, LocationID) async -> Void)?,
        beforeTurn: (@MainActor @Sendable (GameEngine, Command) async -> Void)?
    ) {
        // --- Define Locations INSIDE setup ---
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
            // Note: Bar lighting is handled dynamically by hooks
        )

        // --- Define Items INSIDE setup ---
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
            adjectives: "handsome", "velvet",
            properties: .takable, .wearable, .worn,
            parent: .player // Starts worn by player
        )

        let message = Item(
            id: "message",
            name: "message",
            properties: .ndesc, .read,
            parent: .location("bar"),
            readableText: "You have won!"
        )

        // Define the Player Item
        let playerItem = Item(
            id: "player",      // Standard ID
            name: "yourself",  // Name used in descriptions
            synonyms: "me", "myself", // How the player refers to self
            properties: .person // Mark as a person
            // Parent defaults to .nowhere, which is fine for the player object
            // Size defaults, capacity isn't relevant here
        )

        // --- Remaining Setup ---

        // Player
        let initialPlayer = Player(currentLocationID: "foyer")

        // Items & Locations (use locally defined instances)
        let allItems = [hook, cloak, message, playerItem]
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

        // Registry (Static handlers are fine)
        let registry = GameDefinitionRegistry(objectActionHandlers: objectActionHandlers)

        return (gameState, registry, onEnterRoomHook, beforeTurnHook)
    }
}
