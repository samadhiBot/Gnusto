import GnustoEngine

/// A Gnusto Engine port of Roger Firth's Cloak of Darkness.
struct CloakOfDarkness: GameBlueprint {
    var definitionRegistry: DefinitionRegistry
    var dynamicAttributeRegistry: DynamicAttributeRegistry
    var state: GameState

    init() {
        definitionRegistry = DefinitionRegistry(
            objectActionHandlers: [
                "cloak": Handlers.cloakHandler,
                "hook": OperaHouse.hookDescription,
                "message": Handlers.messageHandler
            ]
        )
        dynamicAttributeRegistry = DynamicAttributeRegistry()
        state = GameState(
            locations: OperaHouse.locations,
            items: OperaHouse.items,
            player: Player(in: "foyer")
        )
    }
}
