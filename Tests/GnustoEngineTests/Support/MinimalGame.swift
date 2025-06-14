import GnustoEngine

/// A minimal game implementation for testing purposes.
/// Provides sensible defaults that can be overridden in individual tests.
public struct MinimalGame: GameBlueprint {
    public var constants: GameConstants
    public var player: Player
    public var randomNumberGenerator: any RandomNumberGenerator { fixedGenerator }
    public var items: [Item]
    public var locations: [Location]
    public var customActionHandlers: [VerbID: ActionHandler]
    public var itemEventHandlers: [ItemID: ItemEventHandler]
    public var locationEventHandlers: [LocationID: LocationEventHandler]
    public var fuses: [FuseID: FuseDefinition]
    public var daemons: [DaemonID: DaemonDefinition]
    public var itemComputers: [ItemID: ItemComputer]
    public var locationComputers: [LocationID: LocationComputer]

    private var fixedGenerator: FixedRandomNumberGenerator

    public init(
        constants: GameConstants = GameConstants(
            storyTitle: "Minimal Game",
            introduction: "Welcome to the Minimal Game!",
            release: "0.0.1",
            maximumScore: 10
        ),
        player: Player = Player(in: LocationID("startRoom")),
        randomNumberGeneratorValues: [Double] = [0.5, 0.25, 0.75, 0, 1],
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
        locationComputers: [LocationID: LocationComputer] = [:]
    ) {
        self.constants = constants
        self.player = player
        self.fixedGenerator = FixedRandomNumberGenerator(values: randomNumberGeneratorValues)
        self.items = items
        self.locations = locations
        self.customActionHandlers = customActionHandlers
        self.itemEventHandlers = itemEventHandlers
        self.locationEventHandlers = locationEventHandlers
        self.fuses = fuses
        self.daemons = daemons
        self.itemComputers = itemComputers
        self.locationComputers = locationComputers
    }
}

public extension ItemID {
    static let startItem: ItemID = "startItem"
}

public extension LocationID {
    static let startRoom: LocationID = "startRoom"
}
