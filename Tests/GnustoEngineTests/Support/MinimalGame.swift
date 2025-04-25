import GnustoEngine

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
        self.state = GameState(
            locations: locations ?? [
                Location(
                    id: "startRoom",
                    name: "Void",
                    description: "An empty void.",
                    properties: .inherentlyLit
                )
            ],
            items: items ?? [
                Item(
                    id: "startItem",
                    name: "pebble",
                    properties: .takable,
                    parent: .location("startRoom")
                )
            ],
            player: player
        )
    }
}
