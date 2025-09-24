import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("Core Proxy Integration Tests")
struct CoreProxyIntegrationTests {

    // MARK: - Basic ItemProxy Tests

    @Test("ItemProxy basic functionality works correctly")
    func testItemProxyBasicFunctionality() async throws {
        // Given
        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .description("A simple test item."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(items: testItem)

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Basic item operations
        try await engine.execute("take test item")
        try await engine.execute("examine test item")

        // Then: ItemProxy should reflect changes
        let itemProxy = await engine.item("testItem")
        #expect(await itemProxy.parent == .player)
        #expect(await itemProxy.hasFlag(ItemPropertyID.isTouched) == true)
        #expect(await itemProxy.name == "test item")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take test item
            Acquired.

            > examine test item
            A simple test item.
            """
        )
    }

    @Test("ItemProxy state changes work through engine")
    func testItemProxyStateChanges() async throws {
        // Given
        let lamp = Item(
            id: "lamp",
            .name("brass lamp"),
            .description("A shiny brass lamp."),
            .isLightSource,
            .isDevice,
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: lamp
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When: Device operations
        try await engine.execute("take lamp")
        try await engine.execute("turn on lamp")

        // Then: ItemProxy should show correct state
        let lampProxy = await engine.item("lamp")
        #expect(await lampProxy.parent == .player)
        #expect(await lampProxy.hasFlag(ItemPropertyID.isOn) == true)
        #expect(await lampProxy.hasFlag(ItemPropertyID.isTouched) == true)
        #expect(await lampProxy.hasFlag(ItemPropertyID.isLightSource) == true)
    }

    // MARK: - Basic LocationProxy Tests

    @Test("LocationProxy basic functionality works correctly")
    func testLocationProxyBasicFunctionality() async throws {
        // Given
        let brightRoom = Location(
            id: "brightRoom",
            .name("Bright Room"),
            .description("A well-lit room."),
            .inherentlyLit
        )

        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A dark room.")
            // No inherent lighting
        )

        let game = MinimalGame(
            player: Player(in: "brightRoom"),
            locations: brightRoom, darkRoom
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When: Accessing location proxies
        let brightProxy = await engine.location("brightRoom")
        let darkProxy = await engine.location("darkRoom")

        // Then: LocationProxy should show correct properties
        #expect(await brightProxy.name == "Bright Room")
        #expect(await darkProxy.name == "Dark Room")
        #expect(await brightProxy.isLit == true)
        #expect(await darkProxy.isLit == false)
    }

    @Test("LocationProxy shows correct items")
    func testLocationProxyItems() async throws {
        // Given
        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .description("A shiny gold coin."),
            .isTakable,
            .in(.startRoom)
        )

        let statue = Item(
            id: "statue",
            .name("stone statue"),
            .description("A heavy stone statue."),
            .in(.startRoom)
            // Not takable
        )

        let game = MinimalGame(
            items: coin, statue
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When: Accessing location items
        let roomProxy = await engine.location(.startRoom)
        let roomItems = await roomProxy.items

        // Then: Should show correct items
        #expect(roomItems.count == 2)
        #expect(roomItems.contains { $0.id == ItemID("coin") })
        #expect(roomItems.contains { $0.id == ItemID("statue") })
    }

    // MARK: - Basic PlayerProxy Tests

    @Test("PlayerProxy basic functionality works correctly")
    func testPlayerProxyBasicFunctionality() async throws {
        // Given
        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .description("A test item."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)

        // When: Player takes an item
        try await engine.execute("take test item")

        // Then: PlayerProxy should reflect changes
        let playerProxy = await engine.player
        let currentLocation = await playerProxy.location
        #expect(currentLocation.id == .startRoom)

        let inventory = await playerProxy.inventory
        #expect(inventory.count == 1)
        #expect(inventory.first?.id == ItemID("testItem"))
    }

    @Test("PlayerProxy inventory management works correctly")
    func testPlayerProxyInventoryManagement() async throws {
        // Given
        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .isTakable,
            .in(.startRoom)
        )

        let key = Item(
            id: "key",
            .name("silver key"),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: coin, key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Player takes multiple items
        try await engine.execute("take coin")
        try await engine.execute("take key")
        try await engine.execute("inventory")

        // Then: PlayerProxy should show all items
        let playerProxy = await engine.player
        let inventory = await playerProxy.inventory
        #expect(inventory.count == 2)
        #expect(inventory.contains { $0.id == ItemID("coin") })
        #expect(inventory.contains { $0.id == ItemID("key") })

        let output = await mockIO.flush()
        #expect(output.contains("gold coin"))
        #expect(output.contains("silver key"))
    }

    // MARK: - Proxy Consistency Tests

    @Test("Proxy system maintains consistency across operations")
    func testProxyConsistency() async throws {
        // Given
        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .description("A test item."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)

        // When: Series of operations
        try await engine.execute("take test item")
        try await engine.execute("drop test item")

        // Then: All proxies should be consistent
        let itemProxy = await engine.item("testItem")
        let roomProxy = await engine.location(.startRoom)
        let playerProxy = await engine.player

        // Item should be back in room
        let itemParent = await itemProxy.parent
        if case .location(let parentLocation) = itemParent {
            #expect(parentLocation.id == .startRoom)
        }

        // Room should contain the item
        let roomItems = await roomProxy.items
        #expect(roomItems.contains { $0.id == ItemID("testItem") })

        // Player should not have the item
        let playerInventory = await playerProxy.inventory
        #expect(playerInventory.isEmpty)
    }

    // MARK: - Container Integration Tests

    @Test("Container proxies work correctly")
    func testContainerProxyIntegration() async throws {
        // Given
        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A sturdy wooden box."),
            .isContainer,
            .isOpenable,
            .isOpen,
            .isTakable,
            .in(.startRoom)
        )

        let gem = Item(
            id: "gem",
            .name("ruby gem"),
            .description("A precious ruby gem."),
            .isTakable,
            .in(.item("box"))
        )

        let game = MinimalGame(
            items: box, gem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Container operations
        try await engine.execute("look in box")
        try await engine.execute("take gem")
        try await engine.execute("take box")

        // Then: Container proxy should show correct state
        let boxProxy = await engine.item("box")
        let gemProxy = await engine.item("gem")

        #expect(await boxProxy.parent == .player)
        #expect(await boxProxy.hasFlag(ItemPropertyID.isOpen) == true)
        #expect(await gemProxy.parent == .player)

        let boxContents = await boxProxy.contents
        #expect(boxContents.isEmpty)  // Gem was taken out

        let output = await mockIO.flush()
        #expect(output.contains("ruby gem"))
    }

    // MARK: - State Change Validation Tests

    @Test("State changes through proxies are properly validated")
    func testStateChangeValidation() async throws {
        // Given
        let heavyItem = Item(
            id: "heavyItem",
            .name("heavy rock"),
            .description("An immovable boulder."),
            .in(.startRoom)
            // Not takable
        )

        let game = MinimalGame(
            items: heavyItem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Attempting invalid operation
        try await engine.execute("take heavy rock")

        // Then: State should remain unchanged
        let itemProxy = await engine.item("heavyItem")
        let itemParent = await itemProxy.parent

        if case .location(let parentLocation) = itemParent {
            #expect(parentLocation.id == .startRoom)
        }

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take heavy rock
            The universe denies your request to take the heavy rock.
            """
        )
    }
}
