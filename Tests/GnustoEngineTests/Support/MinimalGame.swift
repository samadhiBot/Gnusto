@testable import GnustoEngine

struct MinimalGame: GameBlueprint {
    var state: GameState
    var registry: DefinitionRegistry

    init(
        player: Player = Player(in: "startRoom"),
        locations: [Location]? = nil,
        items: [Item]? = nil,
        registry: DefinitionRegistry = DefinitionRegistry()
    ) {
        self.registry = registry

        let gameLocations = locations ?? [
            Location(
                id: "startRoom",
                name: "Void",
                longDescription: "An empty void.",
                properties: .inherentlyLit
            )
        ]
        let gameItems = items ?? [
            Item(
                id: "startItem",
                name: "pebble",
                properties: .takable,
                parent: .location("startRoom")
            )
        ]

        // Build vocabulary including verbs from custom handlers
        var customVerbs: [Verb] = []
        for verbID in registry.customActionHandlers.keys {
            // Create a basic definition; requiresLight=false is a safe default for tests
            let verbDef = Verb(id: verbID, syntax: [], requiresLight: false)
            customVerbs.append(verbDef)
        }
        let vocabulary = Vocabulary.build(items: gameItems, verbs: customVerbs)

        self.state = GameState(
            locations: gameLocations,
            items: gameItems,
            player: player,
            vocabulary: vocabulary // Provide the constructed vocabulary
        )
    }
}
