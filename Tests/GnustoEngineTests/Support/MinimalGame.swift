@testable import GnustoEngine

struct MinimalGame: GameBlueprint {
    var state: GameState
    var definitionRegistry: DefinitionRegistry
    var dynamicPropertyRegistry: DynamicPropertyRegistry

    init(
        player: Player = Player(in: "startRoom"),
        locations: [Location]? = nil,
        items: [Item]? = nil,
        flags: [FlagID]? = nil,
        definitionRegistry: DefinitionRegistry = DefinitionRegistry(),
        dynamicPropertyRegistry: DynamicPropertyRegistry = DynamicPropertyRegistry()
    ) {
        self.definitionRegistry = definitionRegistry
        self.dynamicPropertyRegistry = dynamicPropertyRegistry

        let gameLocations = locations ?? [
            Location(
                id: "startRoom",
                name: "Void",
                description: "An empty void.",
                isLit: true
            )
        ]
        let gameItems = items ?? [
            Item(
                id: "startItem",
                name: "pebble",
                parent: .location("startRoom"),
                attributes: [
                    .isTakable: true
                ]
            )
        ]

        // Build vocabulary including verbs from custom handlers
        var customVerbs: [Verb] = []
        for verbID in definitionRegistry.customActionHandlers.keys {
            // Create a basic definition; requiresLight=false is a safe default for tests
            let verbDef = Verb(id: verbID, syntax: [], requiresLight: false)
            customVerbs.append(verbDef)
        }
        let vocabulary = Vocabulary.build(items: gameItems, verbs: customVerbs)

        self.state = GameState(
            locations: gameLocations,
            items: gameItems,
            player: player,
            vocabulary: vocabulary, // Provide the constructed vocabulary
            flags: Set(flags ?? []) // Pass the initial flags here
        )
    }
}
