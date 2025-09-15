import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("PlayerProxy Tests")
struct PlayerProxyTests {

    // MARK: - Core Functionality Tests

    @Test("PlayerProxy basic creation and properties")
    func testPlayerProxyBasics() async throws {
        // Given
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let proxy = await engine.player

        // Then
        #expect(proxy.health == 50)
        #expect(proxy.score == 0)
        #expect(proxy.moves == 0)
        #expect(proxy.carryingCapacity == 100)
    }

    @Test("PlayerProxy location access")
    func testPlayerLocationAccess() async throws {
        // Given
        let otherRoom = Location(
            id: "otherRoom",
            .name("Other Room"),
            .inherentlyLit
        )

        let game = MinimalGame(locations: otherRoom)

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let proxy = await engine.player
        let location = try await proxy.location

        // Then
        #expect(location.id == .startRoom)
        #expect(await location.name == "Laboratory")
    }

    @Test("PlayerProxy equality and hashing")
    func testPlayerProxyEquality() async throws {
        // Given
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let proxy1 = await engine.player
        let proxy2 = await engine.player

        // Then
        #expect(proxy1 == proxy2)
        #expect(proxy1.hashValue == proxy2.hashValue)
    }

    // MARK: - Inventory Tests

    @Test("PlayerProxy empty inventory")
    func testEmptyInventory() async throws {
        // Given
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let proxy = await engine.player
        let inventory = try await proxy.inventory
        let completeInventory = try await proxy.completeInventory

        // Then
        #expect(inventory.isEmpty)
        #expect(completeInventory.isEmpty)
    }

    @Test("PlayerProxy inventory with items")
    func testInventoryWithItems() async throws {
        // Given
        let book = Item(
            id: "book",
            .name("leather book"),
            .size(2),
            .isTakable,
            .in(.player)
        )

        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .size(1),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: book, coin
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let proxy = await engine.player
        let inventory = try await proxy.inventory
        let completeInventory = try await proxy.completeInventory

        // Then
        #expect(inventory.count == 2)
        #expect(completeInventory.count == 2)

        let inventoryIds = Set(inventory.map { $0.id.rawValue })
        #expect(inventoryIds.contains("book"))
        #expect(inventoryIds.contains("coin"))
    }

    @Test("PlayerProxy inventory with containers")
    func testInventoryWithContainers() async throws {
        // Given
        let bag = Item(
            id: "bag",
            .name("leather bag"),
            .isContainer,
            .isOpen,
            .size(1),
            .isTakable,
            .in(.player)
        )

        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .size(1),
            .isTakable,
            .in(.item("bag"))
        )

        let gem = Item(
            id: "gem",
            .name("ruby gem"),
            .size(1),
            .isTakable,
            .in(.item("bag"))
        )

        let sword = Item(
            id: "sword",
            .name("steel sword"),
            .size(3),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: bag, coin, gem, sword
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let proxy = await engine.player
        let inventory = try await proxy.inventory
        let completeInventory = try await proxy.completeInventory

        // Then
        #expect(inventory.count == 2)  // bag and sword directly held
        #expect(completeInventory.count == 4)  // bag, sword, coin, gem

        let directIds = Set(inventory.map { $0.id.rawValue })
        #expect(directIds.contains("bag"))
        #expect(directIds.contains("sword"))
        #expect(!directIds.contains("coin"))  // coin is inside bag
        #expect(!directIds.contains("gem"))  // gem is inside bag

        let completeIds = Set(completeInventory.map { $0.id.rawValue })
        #expect(completeIds.contains("bag"))
        #expect(completeIds.contains("sword"))
        #expect(completeIds.contains("coin"))
        #expect(completeIds.contains("gem"))
    }

    // MARK: - Carrying Capacity Tests

    @Test("PlayerProxy carrying capacity basic check")
    func testCarryingCapacityBasicCheck() async throws {
        // Given
        let lightItem = Item(
            id: "feather",
            .name("light feather"),
            .size(1),
            .isTakable,
            .in(.startRoom)
        )

        let heavyItem = Item(
            id: "boulder",
            .name("heavy boulder"),
            .size(101),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: lightItem, heavyItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let proxy = await engine.player
        let featherProxy = try await engine.item("feather")
        let boulderProxy = try await engine.item("boulder")

        // Then
        #expect(try await proxy.canCarry(featherProxy.id) == true)
        #expect(try await proxy.canCarry(boulderProxy.id) == false)
    }

    @Test("PlayerProxy carrying capacity with existing inventory")
    func testCarryingCapacityWithExistingInventory() async throws {
        // Given
        let existingItem = Item(
            id: "existing",
            .name("existing item"),
            .size(90),
            .isTakable,
            .in(.player)
        )

        let newLightItem = Item(
            id: "light",
            .name("light item"),
            .size(9),
            .isTakable,
            .in(.startRoom)
        )

        let newHeavyItem = Item(
            id: "heavy",
            .name("heavy item"),
            .size(11),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: existingItem, newLightItem, newHeavyItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let player = await engine.player
        let lightProxy = try await engine.item("light")
        let heavyProxy = try await engine.item("heavy")

        #expect(player.carryingCapacity == 100)

        // Then
        // Player has 90/100 capacity used, so can carry size 1 but not size 5
        #expect(try await player.canCarry(lightProxy.id) == true)
        #expect(try await player.canCarry(heavyProxy.id) == false)
    }

    @Test("PlayerProxy carrying capacity with nested containers")
    func testCarryingCapacityWithNestedContainers() async throws {
        // Given
        let bag = Item(
            id: "bag",
            .name("leather bag"),
            .isContainer,
            .isOpen,
            .size(1),
            .isTakable,
            .in(.player)
        )

        let box = Item(
            id: "box",
            .name("small box"),
            .isContainer,
            .isOpen,
            .size(2),
            .isTakable,
            .in(.item("bag"))
        )

        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .size(1),
            .isTakable,
            .in(.item("box"))
        )

        let newItem = Item(
            id: "newItem",
            .name("new item"),
            .size(3),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: bag, box, coin, newItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let proxy = await engine.player
        let newItemProxy = try await engine.item("newItem")

        // Then
        // Player currently carries: bag(1) + box(2) + coin(1) = 4
        // Adding newItem(3) would make total 7, which is <= 10
        #expect(try await proxy.canCarry(newItemProxy.id) == true)
    }

    @Test("PlayerProxy carrying capacity edge cases")
    func testCarryingCapacityEdgeCases() async throws {
        // Given
        let exactFitItem = Item(
            id: "exactFit",
            .name("exact fit item"),
            .size(100),
            .isTakable,
            .in(.startRoom)
        )

        let oneOverItem = Item(
            id: "oneOver",
            .name("one over item"),
            .size(101),
            .isTakable,
            .in(.startRoom)
        )

        let zeroSizeItem = Item(
            id: "zeroSize",
            .name("zero size item"),
            .size(0),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: exactFitItem, oneOverItem, zeroSizeItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let proxy = await engine.player
        let exactFitProxy = try await engine.item("exactFit")
        let oneOverProxy = try await engine.item("oneOver")
        let zeroSizeProxy = try await engine.item("zeroSize")

        // Then
        #expect(try await proxy.canCarry(exactFitProxy.id) == true)  // exactly at capacity
        #expect(try await proxy.canCarry(oneOverProxy.id) == false)  // one over capacity
        #expect(try await proxy.canCarry(zeroSizeProxy.id) == true)  // zero size always fits
    }

    // MARK: - Integration Tests

    @Test("PlayerProxy through game actions")
    func testPlayerProxyThroughGameActions() async throws {
        // Given
        let book = Item(
            id: "book",
            .name("leather book"),
            .size(2),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When - Take the book
        try await engine.execute("take book")

        // Then - Verify through proxy
        let proxy = await engine.player
        let inventory = try await proxy.inventory
        let bookProxy = try await engine.item("book")

        #expect(inventory.count == 1)
        #expect(inventory[0].id == "book")
        #expect(try await bookProxy.playerIsHolding == true)

        // Verify game output
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take book
            Taken.
            """
        )
    }

    @Test("PlayerProxy moves counter")
    func testPlayerMovesCounter() async throws {
        // Given
        let room1 = Location(
            id: "room1",
            .name("First Room"),
            .inherentlyLit,
            .exits(
                .north("room2")
            )
        )

        let room2 = Location(
            id: "room2",
            .name("Second Room"),
            .inherentlyLit,
            .exits(
                .south("room1")
            )
        )

        let game = MinimalGame(
            player: Player(in: "room1"),
            locations: room1, room2
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let initialProxy = await engine.player
        let initialMoves = initialProxy.moves

        try await engine.execute("north")
        let afterMoveProxy = await engine.player
        let afterMoves = afterMoveProxy.moves

        // Then
        #expect(afterMoves == initialMoves + 1)
    }

    @Test("PlayerProxy with different starting stats")
    func testPlayerProxyWithDifferentStartingStats() async throws {
        // Given
        let game = MinimalGame(
            player: Player(in: .startRoom, characterSheet: .agile)
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let proxy = await engine.player

        // Then
        #expect(proxy.health == 60)
        #expect(proxy.score == 0)
        #expect(proxy.moves == 0)
        #expect(proxy.carryingCapacity == 100)
    }

    @Test("PlayerProxy location changes")
    func testPlayerLocationChanges() async throws {
        // Given
        let room1 = Location(
            id: "room1",
            .name("First Room"),
            .inherentlyLit,
            .exits(
                .east("room2")
            )
        )

        let room2 = Location(
            id: "room2",
            .name("Second Room"),
            .inherentlyLit,
            .exits(
                .west("room1")
            )
        )

        let game = MinimalGame(
            player: Player(in: "room1"),
            locations: room1, room2
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let initialProxy = await engine.player
        let initialLocation = try await initialProxy.location
        #expect(initialLocation.id == "room1")

        try await engine.execute("east")

        let afterMoveProxy = await engine.player
        let afterMoveLocation = try await afterMoveProxy.location
        #expect(afterMoveLocation.id == "room2")
    }
}
