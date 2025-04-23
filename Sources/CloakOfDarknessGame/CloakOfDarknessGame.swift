import GnustoEngine

/// Provides the setup components for the Cloak of Darkness game.
public struct CloakOfDarknessGame: GameDefinition {
    public var state: GameState

    public let registry: GameDefinitionRegistry

    @MainActor
    public init() {
        let items = Items.all()
        let locations = Locations.all()

        registry = GameDefinitionRegistry(
            objectActionHandlers: [
                "cloak": Handlers().cloakHandler,
                "message": Handlers().messageHandler
            ]
        )

        state = GameState(
            locations: locations,
            items: items,
            player: Player(in: "foyer"),
            vocabulary: .build(items: items)
        )
    }
}
