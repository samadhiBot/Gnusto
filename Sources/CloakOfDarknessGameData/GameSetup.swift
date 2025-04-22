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
    /// Before turn hook for Cloak of Darkness game logic.
    /// - Returns: `true` if the hook handled the command and normal processing should stop, `false` otherwise.
    static let beforeTurnHook: (@MainActor @Sendable (GameEngine, Command) async -> Bool)? = { engine, command in
        let locationID = engine.playerLocationID()
        guard locationID == "bar" else { return false } // Only care about the bar

        let cloakIsWorn = engine.itemSnapshot(with: "cloak")?.hasProperty(.worn) ?? false

        if cloakIsWorn {
            // Ensure bar is dark if cloak is worn
            engine.updateLocationProperties(id: "bar", removing: .isLit)

            // Now check for unsafe actions IN THE DARK
            // Re-check lit status *after* potentially removing it
            let isLitNow = engine.locationSnapshot(with: locationID)?.properties.contains(.isLit) ?? false
            if !isLitNow { // Should definitely be false here if update worked
                 let verb = command.verbID

                 // Original ZIL safe verbs in dark Bar: LOOK, GAME-VERB?, THINK-ABOUT, GO NORTH
                 // GAME-VERB? includes meta verbs like QUIT, SCORE, VERBOSE, etc.
                 // Let's assume INVENTORY is also implicitly safe as a game state query.
                 let isMetaVerb = verb == "quit" || verb == "score" || verb == "save" || verb == "restore" || verb == "verbose" || verb == "brief" || verb == "help" || verb == "inventory"
                 let isSafeVerb = verb == "look" || verb == "examine" || verb == "think-about" || isMetaVerb
                 let isLeavingNorth = verb == "go" && command.direction == .north

                 if !isSafeVerb && !isLeavingNorth {
                     await engine.output("You grope around clumsily in the dark. Better be careful.", style: .normal)
                     engine.incrementGameSpecificStateCounter(key: "disturbedCounter")
                     return true // Handled
                 }
            }
            // If we get here, either the room was somehow still lit, or the verb was safe/leaving.
            return false
        } else {
            // Cloak is not worn, ensure bar is lit
            engine.updateLocationProperties(id: "bar", adding: .isLit)
            return false // Hook didn't handle the command itself
        }
    }

    static let onEnterRoomHook: (@MainActor @Sendable (GameEngine, LocationID) async -> Bool)? = { engine, enteredLocationID in
        guard enteredLocationID == "bar" else { return false }
        let cloakIsWorn = engine.itemSnapshot(with: "cloak")?.hasProperty(.worn) ?? false
        if cloakIsWorn {
            engine.updateLocationProperties(id: "bar", removing: .isLit)
        } else {
            engine.updateLocationProperties(id: "bar", adding: .isLit)
        }
        return false
    }

    // MARK: - Public Setup Function

    /// Sets up and returns the initial components for the Cloak of Darkness game.
    /// - Returns: A tuple containing the initial `GameState`, `GameDefinitionRegistry`, `onEnterRoom` hook, and `beforeTurn` hook.
    @MainActor public static func setup() -> (
        initialState: GameState,
        registry: GameDefinitionRegistry,
        onEnterRoom: (@MainActor @Sendable (GameEngine, LocationID) async -> Bool)?,
        beforeTurn: (@MainActor @Sendable (GameEngine, Command) async -> Bool)?
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
