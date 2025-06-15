import GnustoEngine

/// A minimal game implementation for testing purposes.
/// Provides sensible defaults that can be overridden in individual tests.
public struct MinimalGame: GameBlueprint {
    public var constants: GameConstants
    public var player: Player
    public var randomNumberGenerator: FixedRandomNumberGenerator
    public var items: [Item]
    public var locations: [Location]
    public var customActionHandlers: [VerbID: ActionHandler]
    public var itemEventHandlers: [ItemID: ItemEventHandler]
    public var locationEventHandlers: [LocationID: LocationEventHandler]
    public var fuses: [FuseID: FuseDefinition]
    public var daemons: [DaemonID: DaemonDefinition]
    public var itemComputers: [ItemID: ItemComputer]
    public var locationComputers: [LocationID: LocationComputer]
    public var messageProvider: MessageProvider

    public init(
        constants: GameConstants = GameConstants(
            storyTitle: "Minimal Game",
            introduction: "Welcome to the Minimal Game!",
            release: "0.0.1",
            maximumScore: 10
        ),
        player: Player = Player(in: LocationID("startRoom")),
        randomNumberGenerator: FixedRandomNumberGenerator = FixedRandomNumberGenerator(
            values: [0.1, 0.9, 0.3, 0.7, 0.5, 0.6, 0.4, 0.8, 0.2, 1.0]
        ),
        locations: [Location] = [
            Location(
                id: .startRoom,
                .name("Void"),
                .description("An empty void."),
                .inherentlyLit
            )
        ],
        items: [Item] = [
            Item(
                id: .startItem,
                .name("pebble"),
                .in(.location(LocationID("startRoom"))),
                .isTakable
            ),
            Item(
                id: "self",
                .name("self"),
                .description("You are your usual self."),
                .in(.player),
                .omitDescription
            )
        ],
        customActionHandlers: [VerbID: ActionHandler] = [:],
        itemEventHandlers: [ItemID: ItemEventHandler] = [:],
        locationEventHandlers: [LocationID: LocationEventHandler] = [:],
        fuses: [FuseID: FuseDefinition] = [:],
        daemons: [DaemonID: DaemonDefinition] = [:],
        itemComputers: [ItemID: ItemComputer] = [:],
        locationComputers: [LocationID: LocationComputer] = [:],
        messageProvider: MessageProvider? = nil
    ) {
        self.constants = constants
        self.player = player
        self.randomNumberGenerator = randomNumberGenerator
        self.items = items
        self.locations = locations
        self.customActionHandlers = customActionHandlers
        self.itemEventHandlers = itemEventHandlers
        self.locationEventHandlers = locationEventHandlers
        self.fuses = fuses
        self.daemons = daemons
        self.itemComputers = itemComputers
        self.locationComputers = locationComputers
        self.messageProvider = messageProvider ?? MessageProvider(
            randomNumberGenerator: randomNumberGenerator
        )
    }
}

public extension ItemID {
    static let startItem: ItemID = "startItem"
}

public extension LocationID {
    static let startRoom: LocationID = "startRoom"
}
