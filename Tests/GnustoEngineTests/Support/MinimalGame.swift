@testable import GnustoEngine

struct MinimalGame: GameBlueprint {
    let constants = GameConstants(
        storyTitle: "Minimal Game",
        introduction: "Welcome to the Minimal Game!",
        release: "0.0.1",
        maximumScore: 10
    )
    
    let areas: [any AreaBlueprint.Type] = [MinimalArea.self]
    
    let player = Player(in: .startRoom)
}

struct MinimalArea: AreaBlueprint {
    init() {}
    
    static var items: [Item] {
        [
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
    }
    
    static var locations: [Location] {
        [
            Location(
                id: .startRoom,
                .name("Void"),
                .description("An empty void."),
                .inherentlyLit
            )
        ]
    }
    
    static var itemEventHandlers: [ItemID: ItemEventHandler] { [:] }
    static var locationEventHandlers: [LocationID: LocationEventHandler] { [:] }
    static var fuseDefinitions: [FuseID: FuseDefinition] { [:] }
    static var daemonDefinitions: [DaemonID: DaemonDefinition] { [:] }
    static var dynamicAttributeRegistry: DynamicAttributeRegistry { DynamicAttributeRegistry() }
}

extension ItemID {
    static let startItem: ItemID = "startItem"
}

extension LocationID {
    static let startRoom: LocationID = "startRoom"
}
