import GnustoEngine

/// A Gnusto Engine port of Roger Firth's Cloak of Darkness.
struct CloakOfDarkness: GameBlueprint {
    let constants = GameConstants(
        storyTitle: "Cloak of Darkness",
        introduction: """
            A basic IF demonstration.
            
            Hurrying through the rainswept November night, you're glad to see the
            bright lights of the Opera House. It's surprising that there aren't more
            people about but, hey, what do you expect in a cheap demo game...?
            """,
        release: "0.0.3",
        maximumScore: 2
    )
    var definitionRegistry: DefinitionRegistry
    var dynamicAttributeRegistry: DynamicAttributeRegistry
    var state: GameState

    init() {
        definitionRegistry = DefinitionRegistry(
            itemActionHandlers: [
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
            player: Player(in: "foyer"),
            globalState: [
                .barMessageDisturbances: 0
            ]
        )
    }
}

extension GlobalID {
    static let barMessageDisturbances = GlobalID("barMessageDisturbances")
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
