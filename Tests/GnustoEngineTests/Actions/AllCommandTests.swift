import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("ALL Command Tests")
struct AllCommandTests {

    @Test("TAKE ALL with multiple takable items")
    func testTakeAllMultipleItems() async throws {
        // Arrange: Multiple takable items in the room
        let key = Item(.startItem)
            .name("brass key")
            .in(.startRoom)
            .isTakable
            .size(2)

        let coin = Item("coin")
            .name("gold coin")
            .in(.startRoom)
            .isTakable
            .size(1)

        let lamp = Item("lamp")
            .name("brass lamp")
            .in(.startRoom)
            .isTakable
            .size(3)

        let player = Player(in: .startRoom, characterSheet: .weak)
        let game = MinimalGame(player: player, items: key, coin, lamp)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("take all")

        // Assert: All items should be taken
        let finalKeyState = await engine.item(.startItem)
        let finalCoinState = await engine.item("coin")
        let finalLampState = await engine.item("lamp")

        #expect(await finalKeyState.playerIsHolding)
        #expect(await finalCoinState.playerIsHolding)
        #expect(await finalLampState.playerIsHolding)

        // Assert: Appropriate message
        await mockIO.expect(
            """
            > take all
            You take the gold coin, the brass lamp, and the brass key.
            """
        )
    }

    @Test("TAKE ALL with no takable items")
    func testTakeAllNoItems() async throws {
        // Arrange: No takable items in the room
        let scenery = Item(.startItem)
            .name("stone wall")
            .in(.startRoom)
            // No .isTakable flag

        let game = MinimalGame(items: scenery)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("take all")

        // Assert: Appropriate message
        await mockIO.expect(
            """
            > take all
            Take what?
            """
        )
    }

    @Test("TAKE ALL with mixed takable and non-takable items")
    func testTakeAllMixedItems() async throws {
        // Arrange: Mix of takable and non-takable items
        let key = Item(.startItem)
            .name("brass key")
            .in(.startRoom)
            .isTakable
            .size(2)

        let wall = Item("wall")
            .name("stone wall")
            .in(.startRoom)
            // No .isTakable flag
        let coin = Item("coin")
            .name("gold coin")
            .in(.startRoom)
            .isTakable
            .size(1)

        let player = Player(in: .startRoom, characterSheet: .weak)
        let game = MinimalGame(player: player, items: key, wall, coin)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("take all")

        // Assert: Only takable items are taken
        let finalKeyState = await engine.item(.startItem)
        let finalCoinState = await engine.item("coin")
        let finalWallState = await engine.item("wall")

        #expect(await finalKeyState.playerIsHolding)
        #expect(await finalCoinState.playerIsHolding)
        #expect(await finalWallState.parent == .location(engine.location(.startRoom)))  // Wall stays

        // Assert: Appropriate message
        await mockIO.expect(
            """
            > take all
            You take the gold coin and the brass key.
            """
        )
    }

    @Test("TAKE ALL with capacity limit")
    func testTakeAllCapacityLimit() async throws {
        // Arrange: Items that exceed player capacity
        let key = Item(.startItem)
            .name("brass key")
            .in(.startRoom)
            .isTakable
            .size(3)

        let coin = Item("coin")
            .name("gold coin")
            .in(.startRoom)
            .isTakable
            .size(2)

        let boulder = Item("boulder")
            .name("heavy boulder")
            .in(.startRoom)
            .isTakable
            .size(100)  // Too heavy

        let player = Player(in: .startRoom, characterSheet: .weak)  // Can only carry key + coin
        let game = MinimalGame(player: player, items: key, coin, boulder)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("take all")

        // Assert: Only items within capacity are taken
        let finalKeyState = await engine.item(.startItem)
        let finalCoinState = await engine.item("coin")
        let finalBoulderState = await engine.item("boulder")

        #expect(await finalKeyState.playerIsHolding)
        #expect(await finalCoinState.playerIsHolding)
        #expect(await finalBoulderState.parent == .location(engine.location(.startRoom)))

        // Assert: Appropriate message
        await mockIO.expect(
            """
            > take all
            You take the gold coin and the brass key.
            """
        )
    }

    @Test("DROP ALL with multiple held items")
    func testDropAllMultipleItems() async throws {
        // Arrange: Multiple items held by player
        let key = Item(.startItem)
            .name("brass key")
            .in(.player)
            .isTakable
            .size(2)

        let coin = Item("coin")
            .name("gold coin")
            .in(.player)
            .isTakable
            .size(1)

        let lamp = Item("lamp")
            .name("brass lamp")
            .in(.player)
            .isTakable
            .size(3)

        let game = MinimalGame(items: key, coin, lamp)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("drop all")

        // Assert: All items should be dropped
        let finalCoinState = await engine.item("coin")
        let finalLampState = await engine.item("lamp")
        let finalKeyState = await engine.item(.startItem)

        #expect(await finalKeyState.parent == .location(engine.location(.startRoom)))
        #expect(await finalCoinState.parent == .location(engine.location(.startRoom)))
        #expect(await finalLampState.parent == .location(engine.location(.startRoom)))

        // Assert: Appropriate message
        await mockIO.expect(
            """
            > drop all
            You drop the gold coin, the brass lamp, and the brass key.
            """
        )

        // Assert: Pronouns updated to last item
        guard case .them(let itemRefs) = await engine.gameState.pronoun else {
            Issue.record("Expected pronoun to be .them")
            return
        }
        let pronounIDs = itemRefs.compactMap { entityReference -> ItemID? in
            guard case .item(let item) = entityReference else { return nil }
            return item.id
        }
        expectNoDifference(pronounIDs, [coin.id, lamp.id, key.id])
    }

    @Test("DROP ALL with no held items")
    func testDropAllNoItems() async throws {
        // Arrange: Player holding nothing
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("drop all")

        // Assert: Appropriate message
        await mockIO.expect(
            """
            > drop all
            Your hands are as empty as your pockets.
            """
        )
    }

    @Test("TAKE ALL single item uses singular message")
    func testTakeAllSingleItem() async throws {
        // Arrange: Only one takable item
        let key = Item(.startItem)
            .name("brass key")
            .in(.startRoom)
            .isTakable
            .size(2)

        let player = Player(in: .startRoom, characterSheet: .weak)
        let game = MinimalGame(player: player, items: key)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("take all")

        // Assert: Singular message format
        await mockIO.expect(
            """
            > take all
            You take the brass key.
            """
        )

        // Assert: Item is taken
        let finalKeyState = await engine.item(.startItem)
        #expect(await finalKeyState.playerIsHolding)
    }

    @Test("DROP ALL single item uses singular message")
    func testDropAllSingleItem() async throws {
        // Arrange: Player holding one item
        let key = Item(.startItem)
            .name("brass key")
            .in(.player)
            .isTakable
            .size(2)

        let game = MinimalGame(items: key)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("drop all")

        // Assert: Singular message format
        await mockIO.expect(
            """
            > drop all
            You drop the brass key.
            """
        )

        // Assert: Item is dropped
        let finalKeyState = await engine.item(.startItem)
        #expect(await finalKeyState.parent == .location(engine.location(.startRoom)))
    }

    @Test("TAKE ALL skips items already held")
    func testTakeAllSkipsHeldItems() async throws {
        // Arrange: Mix of held and unheld items
        let heldKey = Item(.startItem)
            .name("silver key")
            .in(.player)
            .isTakable
            .size(2)

        let roomKey = Item("roomKey")
            .name("brass key")
            .in(.startRoom)
            .isTakable
            .size(2)

        let player = Player(in: .startRoom, characterSheet: .weak)
        let game = MinimalGame(player: player, items: heldKey, roomKey)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("take all")

        // Assert: Only room key is taken (held key skipped)
        let finalHeldKeyState = await engine.item(.startItem)
        let finalRoomKeyState = await engine.item("roomKey")

        #expect(await finalHeldKeyState.playerIsHolding)  // Still held
        #expect(await finalRoomKeyState.playerIsHolding)  // Now taken

        // Assert: Message only mentions newly taken item
        await mockIO.expect(
            """
            > take all
            You take the brass key.
            """
        )
    }
}
