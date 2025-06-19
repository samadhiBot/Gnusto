import GnustoEngine

/// A minimal game implementation for testing purposes.
/// Provides sensible defaults that can be overridden in individual tests.
public struct MinimalGame: GameBlueprint {
    public let storyTitle = "Minimal Game"
    public let introduction = "Welcome to the Minimal Game!"
    public let release = "0.0.1"
    public let maximumScore = 10

    public var player: Player
    public var items: [Item]
    public var locations: [Location]
    public var customActionHandlers: [VerbID: ActionHandler]
    public var itemEventHandlers: [ItemID: ItemEventHandler]
    public var locationEventHandlers: [LocationID: LocationEventHandler]
    public var fuses: [FuseID: Fuse]
    public var daemons: [DaemonID: Daemon]
    public var itemComputers: [ItemID: ItemComputer]
    public var locationComputers: [LocationID: LocationComputer]
    public var messageProvider: MessageProvider

    public init(
        player: Player = Player(in: LocationID("startRoom")),
        locations: Location...,
        items: Item...,
        customActionHandlers: [VerbID: ActionHandler] = [:],
        itemEventHandlers: [ItemID: ItemEventHandler] = [:],
        locationEventHandlers: [LocationID: LocationEventHandler] = [:],
        fuses: [FuseID: Fuse] = [:],
        daemons: [DaemonID: Daemon] = [:],
        itemComputers: [ItemID: ItemComputer] = [:],
        locationComputers: [LocationID: LocationComputer] = [:],
        messageProvider: MessageProvider? = nil
    ) {
        self.player = player
        self.items = items.isEmpty ? [
            Item(
                id: .startItem,
                .name("pebble"),
                .in(.location(LocationID("startRoom"))),
                .isTakable
            ),
        ] : items
        self.locations = locations.isEmpty ? [
            Location(
                id: .startRoom,
                .name("Void"),
                .description("An empty void."),
                .inherentlyLit
            )
        ] : locations
        self.customActionHandlers = customActionHandlers
        self.itemEventHandlers = itemEventHandlers
        self.locationEventHandlers = locationEventHandlers
        self.fuses = fuses
        self.daemons = daemons
        self.itemComputers = itemComputers
        self.locationComputers = locationComputers
        self.messageProvider = messageProvider ?? MessageProvider(
            randomNumberGenerator: SeededGenerator()
        )
    }
}

public extension ItemID {
    static let startItem: ItemID = "startItem"
}

public extension LocationID {
    static let startRoom: LocationID = "startRoom"
}
