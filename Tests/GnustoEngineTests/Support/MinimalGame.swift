@testable import GnustoEngine

struct MinimalGame: GameBlueprint {
    let constants = GameConstants(
        storyTitle: "Minimal Game",
        introduction: "Welcome to the Minimal Game!",
        release: "0.0.1",
        maximumScore: 10
    )
    var player: Player
    var items: [Item]
    var locations: [Location]
    var customActionHandlers: [VerbID: ActionHandler]
    var itemEventHandlers: [ItemID: ItemEventHandler]
    var locationEventHandlers: [LocationID: LocationEventHandler]
    var timeRegistry: TimeRegistry
    var dynamicAttributeRegistry: DynamicAttributeRegistry

    init(
        player: Player = Player(in: .startRoom),
        locations: [Location]? = nil,
        items: [Item]? = nil,
        globalState: [GlobalID: StateValue]? = nil,
        customActionHandlers: [VerbID: ActionHandler] = [:],
        itemEventHandlers: [ItemID: ItemEventHandler] = [:],
        locationEventHandlers: [LocationID: LocationEventHandler] = [:],
        timeRegistry: TimeRegistry = TimeRegistry(),
        dynamicAttributeRegistry: DynamicAttributeRegistry = DynamicAttributeRegistry()
    ) {
        self.player = player
        self.items = items ?? [
            Item(
                id: .startItem,
                .name("pebble"),
                .in(.location(.startRoom)),
                .isTakable
            ),
            Item(
                id: "self",
                .name("self"),
                .description("You are your usual self."),
                .in(.player),
                .isScenery
            )
        ]
        self.locations = locations ?? [
            Location(
                id: .startRoom,
                .name("Void"),
                .description("An empty void."),
                .inherentlyLit
            )
        ]
        self.customActionHandlers = customActionHandlers
        self.timeRegistry = timeRegistry
        self.dynamicAttributeRegistry = dynamicAttributeRegistry
        self.itemEventHandlers = itemEventHandlers
        self.locationEventHandlers = locationEventHandlers

        // Build vocabulary including verbs from custom handlers
        var customVerbs: [Verb] = []
        for verbID in customActionHandlers.keys {
            // Create a basic definition; requiresLight=false is a safe default for tests
            let verbDef = Verb(id: verbID, syntax: [], requiresLight: false)
            customVerbs.append(verbDef)
        }
//        let vocabulary = Vocabulary.build(items: gameItems, verbs: customVerbs)

//        self.state = GameState(
//            locations: gameLocations,
//            items: gameItems,
//            player: player,
//            vocabulary: vocabulary,
//            globalState: globalState ?? [:]
//        )
    }
}

extension ItemID {
    static let startItem: ItemID = "startItem"
}

extension LocationID {
    static let startRoom: LocationID = "startRoom"
}
