import GnustoEngine

/// A Gnusto Engine port of Roger Firth's Cloak of Darkness.
struct CloakOfDarkness: GameBlueprint {
    var definitionRegistry: DefinitionRegistry
    var dynamicAttributeRegistry: DynamicAttributeRegistry
    var state: GameState

    init() {
        definitionRegistry = DefinitionRegistry(
            objectActionHandlers: [
                .cloak: OperaHouse.cloakHandler,
                .hook: OperaHouse.hookHandler,
                .message: OperaHouse.messageHandler,
            ],
            locationActionHandlers: [
                .bar: OperaHouse.barHandler,
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

extension ItemID {
    static let cloak = ItemID("cloak")
    static let hook = ItemID("hook")
    static let message = ItemID("message")
}

extension LocationID {
    static let bar = LocationID("bar")
    static let cloakroom = LocationID("cloakroom")
    static let foyer = LocationID("foyer")
}
