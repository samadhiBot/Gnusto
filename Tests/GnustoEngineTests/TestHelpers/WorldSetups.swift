import Foundation
@testable import GnustoEngine

/// Contains helper functions for setting up standard game worlds for testing.
@MainActor
struct WorldSetups {

    /// Sets up the minimal "Cloak of Darkness" world state for testing.
    ///
    /// Includes: Foyer, Cloakroom, Bar locations; Hook, Cloak items;
    /// Verbs: go, look, take, drop, wear, remove (and synonyms).
    ///
    /// - Returns: A tuple containing the initial `GameState`, a `StandardParser`, the `[VerbID: ActionHandler]` dictionary,
    ///            the `[ItemID: ObjectActionHandler]` dictionary, and the optional `@MainActor @Sendable` custom logic hook closures.
    static func setupCloakOfDarknessWorld() async -> (
        GameState,
        StandardParser,
        [VerbID: ActionHandler],
        [ItemID: ObjectActionHandler],
        (@MainActor @Sendable (GameEngine, LocationID) async -> Void)?,
        (@MainActor @Sendable (GameEngine) async -> Void)?
    ) {
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
        let hook = Item(id: "hook", name: "hook", adjectives: "brass", synonyms: "peg", properties: .surface, parent: .location("cloakroom"))
        let cloak = Item(id: "cloak", name: "cloak", adjectives: "handsome", "velvet", properties: .takable, .wearable, parent: .item("hook"))
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
        let verbs = [
            Verb(id: "go", syntax: [SyntaxRule(pattern: [.verb, .direction])]),
            Verb(id: "look", synonyms: "l", "x", "examine", syntax: [
                SyntaxRule(pattern: [.verb]),
                SyntaxRule(pattern: [.verb, .directObject])
            ]),
            Verb(id: "take", synonyms: "get",
                 syntax: [
                    SyntaxRule(pattern: [.verb, .directObject], directObjectConditions: [])
                 ]),
            Verb(id: "drop",
                 syntax: [
                    SyntaxRule(pattern: [.verb, .directObject], directObjectConditions: [.held])
                 ]),
            Verb(id: "wear", synonyms: "don",
                 syntax: [
                    SyntaxRule(pattern: [.verb, .directObject], directObjectConditions: [.held])
                 ]),
            Verb(id: "remove", synonyms: "doff", "take off",
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

        // --- Define Object Action Handlers ---
        let objectActionHandlers: [ItemID: ObjectActionHandler] = [
            "message": { engine, command in
                guard
                    command.verbID == "examine",
                    engine.playerLocationID() == "bar"
                else { return false }

                let cloakSnapshot = engine.itemSnapshot(with: "cloak")
                guard cloakSnapshot?.parent == .player else { return false }

                // Match the output in main.swift
                await engine.output("\n*** You have won ***")
                engine.quitGame()
                return true
            }
        ]

        // --- Cloak of Darkness Custom Logic Hooks ---

        let onEnterRoom: (@MainActor @Sendable (GameEngine, LocationID) async -> Void)? = nil // No custom onEnterRoom logic needed now

        let beforeTurn: (@MainActor @Sendable (GameEngine) async -> Void)? = nil // No custom beforeTurn logic needed now

        // Return the initial state, parser, custom handlers, and the specific logic hooks
        return (gameState, parser, customHandlers, objectActionHandlers, onEnterRoom, beforeTurn)
    }

    // Add setup for Zork world later...
}
