import Foundation
@testable import GnustoEngine

/// Contains helper functions for setting up standard game worlds for testing.
struct WorldSetups {

    /// Sets up the minimal "Cloak of Darkness" world state for testing.
    ///
    /// Includes: Foyer, Cloakroom, Bar locations; Hook, Cloak items;
    /// Verbs: go, look, take, drop, wear, remove (and synonyms).
    ///
    /// - Returns: A tuple containing the initial `GameState`, a `StandardParser`, and the `[VerbID: ActionHandler]` dictionary.
    static func setupCloakOfDarknessWorld() -> (GameState, StandardParser, [VerbID: ActionHandler]) {
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

        // Player
        let initialPlayer = Player(currentLocationID: "foyer")

        // All Items and Locations
        let allItems = [hook, cloak]
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

        // Action Handlers
        let customHandlers: [VerbID: ActionHandler] = [
            VerbID("go"): GoActionHandler(), // Go should be registered too
            VerbID("look"): LookActionHandler(),
            VerbID("examine"): LookActionHandler(),
            VerbID("x"): LookActionHandler(),
            VerbID("l"): LookActionHandler(),
            VerbID("take"): TakeActionHandler(),
            VerbID("get"): TakeActionHandler(),
            VerbID("drop"): DropActionHandler(),
            VerbID("wear"): WearActionHandler(),
            VerbID("don"): WearActionHandler(),
            VerbID("remove"): RemoveActionHandler(),
            VerbID("doff"): RemoveActionHandler(),
            VerbID("take off"): RemoveActionHandler()
        ]

        return (gameState, parser, customHandlers)
    }

    // Add setup for Zork world later...
}
