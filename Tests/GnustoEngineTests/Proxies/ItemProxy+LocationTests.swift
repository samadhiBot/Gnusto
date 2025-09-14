import Testing

@testable import GnustoEngine
@testable import GnustoTestSupport

@Suite("ItemProxy Location Computation Tests")
struct ItemProxyLocationTests {

    @Test("Item directly in location returns that location")
    func itemDirectlyInLocation() async throws {
        // Given: Item directly placed in a location
        let testRoom = Location(
            id: .testRoom,
            .name("Test Room"),
            .inherentlyLit
        )

        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .in(.testRoom)
        )

        let game = MinimalGame(
            player: Player(in: .testRoom),
            locations: testRoom,
            items: testItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When: Getting the item's location
        let item = try await engine.item("testItem")
        let location = try await item.location

        // Then: Location should be the test room
        #expect(location?.id == .testRoom)
    }

    @Test("Item in container in location returns the location")
    func itemInContainerInLocation() async throws {
        // Given: Item in a container in a location
        let testRoom = Location(
            id: .testRoom,
            .name("Test Room"),
            .inherentlyLit
        )

        let container = Item(
            id: "container",
            .name("container"),
            .isContainer,
            .in(.testRoom)
        )

        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .in(.item("container"))
        )

        let game = MinimalGame(
            player: Player(in: .testRoom),
            locations: testRoom,
            items: container, testItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When: Getting the nested item's location
        let item = try await engine.item("testItem")
        let location = try await item.location

        // Then: Location should be the test room (not the container)
        #expect(location?.id == .testRoom)
    }

    @Test("Item in deeply nested containers returns ultimate location")
    func itemInDeeplyNestedContainers() async throws {
        // Given: Item in container in container in location (sandwich in bag in kitchen scenario)
        let kitchen = Location(
            id: .kitchen,
            .name("Kitchen"),
            .inherentlyLit
        )

        let bag = Item(
            id: "bag",
            .name("bag"),
            .isContainer,
            .in(.kitchen)
        )

        let lunchbox = Item(
            id: "lunchbox",
            .name("lunchbox"),
            .isContainer,
            .in(.item("bag"))
        )

        let sandwich = Item(
            id: "sandwich",
            .name("sandwich"),
            .in(.item("lunchbox"))
        )

        let game = MinimalGame(
            player: Player(in: .kitchen),
            locations: kitchen,
            items: bag, lunchbox, sandwich
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When: Getting the deeply nested item's location
        let item = try await engine.item("sandwich")
        let location = try await item.location

        // Then: Location should be the kitchen (ultimate location)
        #expect(location?.id == .kitchen)
    }

    @Test("Item held by player returns player's location")
    func itemHeldByPlayerReturnsPlayersLocation() async throws {
        // Given: Item held by player in a location
        let testRoom = Location(
            id: .testRoom,
            .name("Test Room"),
            .inherentlyLit
        )

        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: .testRoom),
            locations: testRoom,
            items: testItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When: Getting the held item's location
        let item = try await engine.item("testItem")
        let location = try await item.location

        // Then: Location should be the test room (where player is)
        #expect(location?.id == .testRoom)
    }

    @Test("Item in container held by player returns player's location")
    func itemInContainerHeldByPlayerReturnsPlayersLocation() async throws {
        // Given: Item in container held by player
        let testRoom = Location(
            id: .testRoom,
            .name("Test Room"),
            .inherentlyLit
        )

        let container = Item(
            id: "container",
            .name("container"),
            .isContainer,
            .isTakable,
            .in(.player)
        )

        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .in(.item("container"))
        )

        let game = MinimalGame(
            player: Player(in: .testRoom),
            locations: testRoom,
            items: container, testItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When: Getting the nested item's location
        let item = try await engine.item("testItem")
        let location = try await item.location

        // Then: Location should be the test room (where player is)
        #expect(location?.id == .testRoom)
    }

    @Test("Item with nowhere parent returns nil")
    func itemWithNowhereParentReturnsNil() async throws {
        // Given: Item with no parent (nowhere)
        let testRoom = Location(
            id: .testRoom,
            .name("Test Room"),
            .inherentlyLit
        )

        let testItem = Item(
            id: "testItem",
            .name("test item")
            // No .in() specified, defaults to nowhere
        )

        let game = MinimalGame(
            player: Player(in: .testRoom),
            locations: testRoom,
            items: testItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When: Getting the nowhere item's location
        let item = try await engine.item("testItem")
        let location = try await item.location

        // Then: Location should be nil
        #expect(location == nil)
    }

    @Test("Location computation handles mixed containment scenarios")
    func locationComputationHandlesMixedContainmentScenarios() async throws {
        // Given: Complex scenario with multiple items in different containment states
        let livingRoom = Location(
            id: .livingRoom,
            .name("Living Room"),
            .inherentlyLit
        )

        let kitchen = Location(
            id: .kitchen,
            .name("Kitchen"),
            .inherentlyLit
        )

        // Item directly in living room
        let lamp = Item(
            id: "lamp",
            .name("lamp"),
            .in(.livingRoom)
        )

        // Container in kitchen
        let refrigerator = Item(
            id: "refrigerator",
            .name("refrigerator"),
            .isContainer,
            .in(.kitchen)
        )

        // Item in container in kitchen
        let milk = Item(
            id: "milk",
            .name("milk"),
            .in(.item("refrigerator"))
        )

        // Portable container held by player
        let backpack = Item(
            id: "backpack",
            .name("backpack"),
            .isContainer,
            .isTakable,
            .in(.player)
        )

        // Item in portable container held by player
        let keys = Item(
            id: "keys",
            .name("keys"),
            .in(.item("backpack"))
        )

        let game = MinimalGame(
            player: Player(in: .livingRoom),
            locations: livingRoom, kitchen,
            items: lamp, refrigerator, milk, backpack, keys
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When/Then: Test each item's location computation
        let lampProxy = try await engine.item("lamp")
        let lampLocation = try await lampProxy.location
        #expect(lampLocation?.id == .livingRoom)

        let milkProxy = try await engine.item("milk")
        let milkLocation = try await milkProxy.location
        #expect(milkLocation?.id == .kitchen)

        let keysProxy = try await engine.item("keys")
        let keysLocation = try await keysProxy.location
        #expect(keysLocation?.id == .livingRoom)  // Where player is
    }

    @Test("Location computation is consistent across state changes")
    func locationComputationIsConsistentAcrossStateChanges() async throws {
        // Given: Item that will be moved between different containment states
        let testRoom = Location(
            id: .testRoom,
            .name("Test Room"),
            .inherentlyLit
        )

        let container = Item(
            id: "container",
            .name("container"),
            .isContainer,
            .isTakable,
            .in(.testRoom)
        )

        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .isTakable,
            .in(.testRoom)
        )

        let game = MinimalGame(
            player: Player(in: .testRoom),
            locations: testRoom,
            items: container, testItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // Initial state: item directly in room
        let item = try await engine.item("testItem")
        var location = try await item.location
        #expect(location?.id == .testRoom)

        // Move item to container
        try await engine.execute("put test item in container")
        location = try await item.location
        #expect(location?.id == .testRoom)  // Still in room, but via container

        // Take container (with item inside)
        try await engine.execute("take container")
        location = try await item.location
        #expect(location?.id == .testRoom)  // Still in room, but now via player

        // Take item out of container
        try await engine.execute("take test item")
        location = try await item.location
        #expect(location?.id == .testRoom)  // Still in room, now directly held by player
    }
}

// MARK: - Test Extensions

extension LocationID {
    fileprivate static let testRoom = LocationID("testRoom")
    fileprivate static let kitchen = LocationID("kitchen")
    fileprivate static let livingRoom = LocationID("livingRoom")
}
