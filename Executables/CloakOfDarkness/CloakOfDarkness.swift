import GnustoEngine

/// A Gnusto Engine port of Roger Firth's Cloak of Darkness.
struct CloakOfDarkness: GameBlueprint {
    var definitionRegistry: DefinitionRegistry
    var dynamicAttributeRegistry: DynamicAttributeRegistry
    var state: GameState

    init() {
        definitionRegistry = DefinitionRegistry(
            objectActionHandlers: [
                "cloak": OperaHouse.cloakHandler,
                "hook": OperaHouse.hookHandler,
                "message": OperaHouse.messageHandler
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
