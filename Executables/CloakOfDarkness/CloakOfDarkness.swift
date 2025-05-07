import GnustoEngine

/// A Gnusto Engine port of Roger Firth's Cloak of Darkness.
struct CloakOfDarkness: GameBlueprint {
    var state: GameState

    let definitionRegistry: DefinitionRegistry

        init() {
        state = GameState(
            locations: OperaHouse.locations,
            items: OperaHouse.items,
            player: Player(in: "foyer")
        )
        registry = DefinitionRegistry(
            objectActionHandlers: [
                "cloak": Handlers().cloakHandler,
                "message": Handlers().messageHandler
            ]
        )
    }
}
