import GnustoEngine

struct MinimalGame: GameDefinition {
    var state: GameState
    var registry: GameDefinitionRegistry

    init(
        locations: [Location] = [Self.startRoom],
        items: [Item] = [Self.pebble],
        registry: GameDefinitionRegistry = GameDefinitionRegistry()
    ) {
        self.registry = registry
        self.state = GameState(
            locations: locations,
            items: items,
            player: Player(in: "startRoom"),
            vocabulary: .build(items: items)
        )
    }

    static let pebble = Item(
        id: "startItem",
        name: "pebble",
        properties: .takable,
        parent: .location("startRoom")
    )

    static let startRoom = Location(
        id: "startRoom",
        name: "Void",
        description: "An empty void.",
        properties: .inherentlyLit
    )
}
