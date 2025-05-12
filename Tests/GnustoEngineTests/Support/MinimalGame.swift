@testable import GnustoEngine

struct MinimalGame: GameBlueprint {
    var state: GameState
    var definitionRegistry: DefinitionRegistry
    var dynamicAttributeRegistry: DynamicAttributeRegistry

    init(
        player: Player = Player(in: .startRoom),
        locations: [Location]? = nil,
        items: [Item]? = nil,
        globalState: [GlobalID: StateValue]? = nil,
        definitionRegistry: DefinitionRegistry = DefinitionRegistry(),
        dynamicAttributeRegistry: DynamicAttributeRegistry = DynamicAttributeRegistry()
    ) {
        self.definitionRegistry = definitionRegistry
        self.dynamicAttributeRegistry = dynamicAttributeRegistry

        let gameLocations = locations ?? [
            Location(
                id: .startRoom,
                .name("Void"),
                .description("An empty void."),
                .inherentlyLit
            )
        ]
        let gameItems = items ?? [
            Item(
                id: "startItem",
                .name("pebble"),
                .in(.location(.startRoom)),
                .isTakable
            ),
            Item(
                id: "self",
                .name("self"),
                .description("You are your usual self."),
                .in(.player),
                .isScenery
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
            vocabulary: vocabulary,
            globalState: globalState ?? [:]
        )
    }
}

extension LocationID {
    static let startRoom: LocationID = "startRoom"
}
