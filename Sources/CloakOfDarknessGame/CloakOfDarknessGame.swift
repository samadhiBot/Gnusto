import GnustoEngine

/// Provides the setup components for the Cloak of Darkness game.
public struct CloakOfDarknessGame: GameDefinition {
    public var state: GameState

    public let registry: GameDefinitionRegistry

    @MainActor
    public init() {
        let items = OperaHouse.items

        registry = GameDefinitionRegistry(
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
