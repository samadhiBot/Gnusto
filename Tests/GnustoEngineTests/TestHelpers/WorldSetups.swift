import Foundation
@testable import GnustoEngine

/// Contains helper functions for setting up standard game worlds for testing.
struct WorldSetups {

    /// Sets up the minimal "Cloak of Darkness" world state for testing.
    ///
    /// Includes: Foyer, Cloakroom, Bar locations; Hook, Cloak items;
    /// Verbs: go, look, take, drop, wear, remove (and synonyms).
    ///
    /// - Returns: A tuple containing the initial `GameState`, a `StandardParser`, the `[VerbID: ActionHandler]` dictionary,
    ///            and the optional `@MainActor @Sendable` custom logic hook closures.
    static func setupCloakOfDarknessWorld() -> (GameState, StandardParser, [VerbID: ActionHandler], (@MainActor @Sendable (GameEngine, LocationID) async -> Void)?, (@MainActor @Sendable (GameEngine) async -> Void)?, (@MainActor @Sendable (GameEngine, ItemID) async -> Bool)?) {
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
        let hook = Item(id: "hook", name: "hook", adjectives: ["brass"], synonyms: ["peg"], properties: [.surface], parent: .location("cloakroom"))
        let cloak = Item(id: "cloak", name: "cloak", adjectives: ["handsome", "velvet"], properties: [.takable, .wearable], parent: .item("hook"))
        let message = Item(
            id: "message",
            name: "message",
            adjectives: ["scrawled"],
            synonyms: ["floor", "sawdust", "dust"],
            description: "The message simply reads... well, you'll need to examine it properly.",
            firstDescription: "There seems to be some sort of message scrawled in the sawdust on the floor.",
            properties: [],
            parent: .location("bar")
        )

        // Player
        let initialPlayer = Player(currentLocationID: "foyer")

        // All Items and Locations
        let allItems = [hook, cloak, message]
        let allLocations = [foyer, cloakroom, bar]

        // Vocabulary
        let verbs = [
            Verb(id: "go", syntax: [SyntaxRule(pattern: [.verb, .direction])]),
            Verb(id: "look", synonyms: ["l", "x", "examine"], syntax: [
                SyntaxRule(pattern: [.verb]),
                SyntaxRule(pattern: [.verb, .directObject])
            ]),
            Verb(id: "take", synonyms: ["get"],
                 syntax: [
                    SyntaxRule(pattern: [.verb, .directObject], directObjectConditions: [])
                 ]),
            Verb(id: "drop",
                 syntax: [
                    SyntaxRule(pattern: [.verb, .directObject], directObjectConditions: [.held])
                 ]),
            Verb(id: "wear", synonyms: ["don"],
                 syntax: [
                    SyntaxRule(pattern: [.verb, .directObject], directObjectConditions: [.held])
                 ]),
            Verb(id: "remove", synonyms: ["doff", "take off"],
                 syntax: [
                    SyntaxRule(pattern: [.verb, .directObject], directObjectConditions: [.worn])
                 ]),
        ]
        let vocabulary = Vocabulary.build(items: allItems, verbs: verbs)

        // Game State
        let gameState = GameState.initial(
            initialLocations: allLocations,
            initialItems: allItems,
            initialPlayer: initialPlayer,
            vocabulary: vocabulary
        )

        // Parser
        let parser = StandardParser()

        // Action Handlers (Keep custom ones defined here)
        let customHandlers: [VerbID: ActionHandler] = [
            // Default handlers (like go, look) are registered by the Engine itself.
            // Only list handlers that *override* defaults or add new verbs specific to this game.
            VerbID("take"): TakeActionHandler(),
            VerbID("get"): TakeActionHandler(),
            VerbID("drop"): DropActionHandler(),
            VerbID("wear"): WearActionHandler(),
            VerbID("don"): WearActionHandler(),
            VerbID("remove"): RemoveActionHandler(),
            VerbID("doff"): RemoveActionHandler(),
            VerbID("take off"): RemoveActionHandler()
            // Add other Cloak-specific verbs/overrides here if needed later.
        ]

        // --- Cloak of Darkness Custom Logic Hooks ---

        let onEnterRoom: @MainActor @Sendable (GameEngine, LocationID) async -> Void = { @MainActor @Sendable engine, locationID in
            guard locationID == LocationID("bar") else { return }

            // Access state via the engine's accessor
            let currentState = engine.getCurrentGameState()
            let cloakIsWorn = currentState.items[ItemID("cloak")]?.hasProperty(.worn) ?? false

            // Use the engine's mutator for state changes
            engine.updateGameState { state in
                if cloakIsWorn {
                    state.locations[LocationID("bar")]?.removeProperty(.lit)
                } else {
                    state.locations[LocationID("bar")]?.addProperty(.lit)
                }
            }
        }

        let beforeTurn: @MainActor @Sendable (GameEngine) async -> Void = { @MainActor @Sendable engine in
            let currentState = engine.getCurrentGameState()
            guard currentState.player.currentLocationID == LocationID("bar") else { return }

            let barIsLit = currentState.locations[LocationID("bar")]?.hasProperty(.lit) ?? false

            if !barIsLit {
                // ZIL logic: Only print the darkness message here.
                // The disturbed counter should only increment on specific actions (e.g., TAKE, DROP) while in the dark bar,
                // which would require checks in those specific ActionHandlers.
                await engine.ioHandler.print("It is pitch black. You are likely to be eaten by a grue.")

                // --- REMOVED Counter Increment Logic ---
                // engine.updateGameState { state in ... }
            }
        }

        let onExamineItem: @MainActor @Sendable (GameEngine, ItemID) async -> Bool = { @MainActor @Sendable engine, itemID in
            guard itemID == ItemID("message") else { return false } // Not the message, do default action

            let currentState = engine.getCurrentGameState()
            let key = "cod_disturbed_counter"
            let disturbedCount = currentState.gameSpecificState?[key]?.value as? Int ?? 0

            if disturbedCount > 1 {
                await engine.ioHandler.print("The message simply reads: \"You lose.\"")
            } else {
                await engine.ioHandler.print("The message simply reads: \"You win.\"")
            }
            await engine.ioHandler.print("\n*** The End ***") // A more thematic end message
            engine.quitGame() // Signal engine to stop using the new method

            return true // We handled the examination
        }

        // Return the initial state, parser, custom handlers, and the specific logic hooks
        return (gameState, parser, customHandlers, onEnterRoom, beforeTurn, onExamineItem)
    }

    // Add setup for Zork world later...
}
