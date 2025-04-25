import GnustoEngine

/// Provides the setup components for the Cloak of Darkness game.
public struct CloakOfDarkness: GameBlueprint {
    public var state: GameState

    public let registry: DefinitionRegistry

    @MainActor
    public init() {
        let items = OperaHouse.items

        registry = DefinitionRegistry(
            objectActionHandlers: [
                "cloak": Handlers().cloakHandler,
                "message": Handlers().messageHandler
            ]
        )

        state = GameState(
            locations: OperaHouse.locations,
            items: items,
            player: Player(in: "foyer"),
            vocabulary: .build(items: items)
        )
    }
}
