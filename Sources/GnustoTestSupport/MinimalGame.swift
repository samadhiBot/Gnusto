import GnustoEngine

/// A minimal game implementation designed for unit testing interactive fiction games.
///
/// `MinimalGame` provides a complete, functional game world with sensible defaults that can be
/// easily customized in individual tests. It automatically creates essential components like
/// a starting room and takeable item if they're not explicitly provided, ensuring tests have
/// a valid game state to work with.
///
/// ## Default Components
/// - **Starting Location**: "Void" room (inherently lit)
/// - **Starting Item**: "pebble" (takeable, in starting room)
/// - **Player**: Positioned in the starting room
/// - **Messenger**: Seeded for deterministic output
///
/// ## Example Usage
/// ```swift
/// // Basic test game with defaults
/// let game = MinimalGame()
///
/// // Custom game with specific items and locations
/// let customGame = MinimalGame(
///     player: Player(in: "library"),
///     locations: Location(id: "library", .name("Library"), .inherentlyLit),
///     items: Item(id: "book", .name("old book"), .isTakable, .in("library"))
/// )
/// ```
///
/// All components use deterministic seeding to ensure reproducible test behavior across runs.
public struct MinimalGame: GameBlueprint {
    /// The full title of the test game.
    public let title = "Minimal Game"

    /// The abbreviated title used for save files and compact displays.
    public let abbreviatedTitle = "MinimalGame"

    /// The introductory text shown when the game starts.
    public let introduction = "Welcome to the Minimal Game!"

    /// The version string for this test game.
    public let release = "0.0.1"

    /// The maximum possible score in this test game.
    public let maximumScore = 10

    /// The player character and their initial state.
    public var player: Player

    /// All items in the game world, including auto-generated defaults.
    public var items: [Item]

    /// All locations in the game world, including auto-generated defaults.
    public var locations: [Location]

    /// Custom action handlers for specialized game mechanics.
    public var customActionHandlers: [ActionHandler]

    /// Combat systems mapped by item ID for items that can engage in combat.
    public var combatSystems: [ItemID: any CombatSystem]

    /// Event handlers for specific items to customize their behavior.
    public var itemEventHandlers: [ItemID: ItemEventHandler]

    /// Event handlers for specific locations to customize their behavior.
    public var locationEventHandlers: [LocationID: LocationEventHandler]

    /// Timed events that fire once after a specified number of turns.
    public var fuses: [FuseID: Fuse]

    /// Recurring events that fire every specified number of turns.
    public var daemons: [DaemonID: Daemon]

    /// Dynamic property computers for items that need runtime-calculated values.
    public var itemComputers: [ItemID: ItemComputer]

    /// Dynamic property computers for locations that need runtime-calculated values.
    public var locationComputers: [LocationID: LocationComputer]

    /// The message provider for all player-facing text, seeded for deterministic output.
    public var messenger: StandardMessenger

    public let randomNumberGenerator: any RandomNumberGenerator & Sendable

    /// Creates a minimal game with the specified components and sensible defaults.
    ///
    /// Any omitted components will be automatically provided with functional defaults:
    /// - If no starting room exists, creates a "Void" location
    /// - If no starting item exists, creates a "pebble" item
    /// - If no messenger is provided, creates one with the specified random seed
    ///
    /// - Parameters:
    ///   - player: The player character. Defaults to starting in "startRoom".
    ///   - locations: Variadic list of locations to include in the game world.
    ///   - items: Variadic list of items to include in the game world.
    ///   - customActionHandlers: Custom action handlers for specialized game mechanics.
    ///   - combatSystems: Combat systems mapped by item ID.
    ///   - itemEventHandlers: Event handlers for specific items.
    ///   - locationEventHandlers: Event handlers for specific locations.
    ///   - fuses: Timed events that fire once.
    ///   - daemons: Recurring timed events.
    ///   - itemComputers: Dynamic property computers for items.
    ///   - locationComputers: Dynamic property computers for locations.
    ///   - messenger: Custom message provider. If `nil`, creates a seeded `StandardMessenger`.
    public init(
        player: Player = Player(in: .startRoom),
        locations: Location...,
        items: Item...,
        customActionHandlers: [ActionHandler] = [],
        combatSystems: [ItemID: any CombatSystem] = [:],
        itemEventHandlers: [ItemID: ItemEventHandler] = [:],
        locationEventHandlers: [LocationID: LocationEventHandler] = [:],
        fuses: [FuseID: Fuse] = [:],
        daemons: [DaemonID: Daemon] = [:],
        itemComputers: [ItemID: ItemComputer] = [:],
        locationComputers: [LocationID: LocationComputer] = [:],
        messenger: StandardMessenger? = nil,
        randomSeed: UInt64 = 71
    ) {
        let rng = SeededRandomNumberGenerator(seed: randomSeed)

        self.player = player
        self.items = items  // Self.allItems(from: items)
        self.locations = Self.allLocations(from: locations)
        self.customActionHandlers = customActionHandlers
        self.combatSystems = combatSystems
        self.itemEventHandlers = itemEventHandlers
        self.locationEventHandlers = locationEventHandlers
        self.fuses = fuses
        self.daemons = daemons
        self.itemComputers = itemComputers
        self.locationComputers = locationComputers
        self.messenger = messenger ?? StandardMessenger(randomNumberGenerator: rng)
        self.randomNumberGenerator = rng
    }
}

// MARK: - Default Component Generation

extension MinimalGame {
    /// Ensures the game has essential items, adding defaults if necessary.
    //    private static func allItems(from items: [Item]) -> [Item] {
    //        var allItems = items
    //        if !allItems.contains(where: { $0.id == .startItem }) {
    //            allItems.append(
    //
    //            )
    //        }
    //        return allItems
    //    }

    /// Ensures the game has essential locations, adding defaults if necessary.
    private static func allLocations(from locations: [Location]) -> [Location] {
        var allLocations = locations
        if !allLocations.contains(where: { $0.id == .startRoom }) {
            allLocations.append(Lab.laboratory)
        }
        return allLocations
    }
}
