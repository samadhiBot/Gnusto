import GnustoEngine

/// A minimal game implementation for testing purposes.
/// Provides sensible defaults that can be overridden in individual tests.
public struct MinimalGame: GameBlueprint {
    public var constants: GameConstants
    public var player: Player
    public var items: [Item]
    public var locations: [Location]
    public var customActionHandlers: [VerbID: ActionHandler]
    public var itemEventHandlers: [ItemID: ItemEventHandler]
    public var locationEventHandlers: [LocationID: LocationEventHandler]
    public var fuseDefinitions: [FuseID: FuseDefinition]
    public var daemonDefinitions: [DaemonID: DaemonDefinition]
    public var dynamicAttributeRegistry: DynamicAttributeRegistry

    public init(
        constants: GameConstants = GameConstants(
            storyTitle: "Minimal Game",
            introduction: "Welcome to the Minimal Game!",
            release: "0.0.1",
            maximumScore: 10
        ),
        player: Player = Player(in: LocationID("startRoom")),
        locations: [Location] = [
            Location(
                id: LocationID("startRoom"),
                .name("Void"),
                .description("An empty void."),
                .inherentlyLit
            )
        ],
        items: [Item] = [
            Item(
                id: ItemID("startItem"),
                .name("pebble"),
                .in(.location(LocationID("startRoom"))),
                .isTakable
            ),
            Item(
                id: "self",
                .name("self"),
                .description("You are your usual self."),
                .in(.player),
                .isScenery
            )
        ],
        customActionHandlers: [VerbID: ActionHandler] = [:],
        itemEventHandlers: [ItemID: ItemEventHandler] = [:],
        locationEventHandlers: [LocationID: LocationEventHandler] = [:],
        fuseDefinitions: [FuseDefinition] = [],
        daemonDefinitions: [DaemonDefinition] = [],
        dynamicAttributeRegistry: DynamicAttributeRegistry = DynamicAttributeRegistry()
    ) {
        self.constants = constants
        self.player = player
        self.items = items
        self.locations = locations
        self.customActionHandlers = customActionHandlers
        self.itemEventHandlers = itemEventHandlers
        self.locationEventHandlers = locationEventHandlers
        self.fuseDefinitions = Dictionary(
            uniqueKeysWithValues: fuseDefinitions.map { ($0.id, $0) }
        )
        self.daemonDefinitions = Dictionary(
            uniqueKeysWithValues: daemonDefinitions.map { ($0.id, $0) }
        )
        self.dynamicAttributeRegistry = dynamicAttributeRegistry
    }
}

public extension ItemID {
    static let startItem: ItemID = "startItem"
}

public extension LocationID {
    static let startRoom: LocationID = "startRoom"
}
