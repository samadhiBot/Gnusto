import CustomDump
import Testing

@testable import GnustoEngine

@Suite("ALL Command Tests")
struct AllCommandTests {
    
    @Test("TAKE ALL with multiple takable items")
    func testTakeAllMultipleItems() async throws {
        // Arrange: Multiple takable items in the room
        let key = Item(
            id: "key",
            .name("brass key"),
            .in(.location(.startRoom)),
            .isTakable,
            .size(2)
        )
        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .in(.location(.startRoom)),
            .isTakable,
            .size(1)
        )
        let lamp = Item(
            id: "lamp",
            .name("brass lamp"),
            .in(.location(.startRoom)),
            .isTakable,
            .size(3)
        )
        
        let player = Player(in: .startRoom, carryingCapacity: 20)
        let game = MinimalGame(player: player, items: [key, coin, lamp])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(
            verb: .take,
            directObjects: [.item("coin"), .item("key"), .item("lamp")], // Sorted by name
            isAllCommand: true,
            rawInput: "take all"
        )

        // Act
        await engine.execute(command: command)

        // Assert: All items should be taken
        let finalKeyState = try await engine.item("key")
        let finalCoinState = try await engine.item("coin")
        let finalLampState = try await engine.item("lamp")
        
        #expect(finalKeyState.parent == .player)
        #expect(finalCoinState.parent == .player)
        #expect(finalLampState.parent == .player)

        // Assert: Appropriate message
        let output = await mockIO.flush()
        expectNoDifference(output, "You take the gold coin, the brass key, and the brass lamp.")

        // Assert: Pronouns updated to last item
        #expect(await engine.getPronounReference(pronoun: "it") == [.item("lamp")])
    }

    @Test("TAKE ALL with no takable items")
    func testTakeAllNoItems() async throws {
        // Arrange: No takable items in the room
        let scenery = Item(
            id: "wall",
            .name("stone wall"),
            .in(.location(.startRoom))
            // No .isTakable flag
        )
        
        let game = MinimalGame(items: [scenery])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(
            verb: .take,
            directObjects: [], // Empty because no valid objects found
            isAllCommand: true,
            rawInput: "take all"
        )

        // Act
        await engine.execute(command: command)

        // Assert: Appropriate message
        let output = await mockIO.flush()
        #expect(output == "There is nothing here to take.")

        // Assert: No state changes
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("TAKE ALL with mixed takable and non-takable items")
    func testTakeAllMixedItems() async throws {
        // Arrange: Mix of takable and non-takable items
        let key = Item(
            id: "key",
            .name("brass key"),
            .in(.location(.startRoom)),
            .isTakable,
            .size(2)
        )
        let wall = Item(
            id: "wall",
            .name("stone wall"),
            .in(.location(.startRoom))
            // No .isTakable flag
        )
        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .in(.location(.startRoom)),
            .isTakable,
            .size(1)
        )
        
        let player = Player(in: .startRoom, carryingCapacity: 20)
        let game = MinimalGame(player: player, items: [key, wall, coin])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(
            verb: .take,
            directObjects: [.item("coin"), .item("key")], // Only takable items
            isAllCommand: true,
            rawInput: "take all"
        )

        // Act
        await engine.execute(command: command)

        // Assert: Only takable items are taken
        let finalKeyState = try await engine.item("key")
        let finalCoinState = try await engine.item("coin")
        let finalWallState = try await engine.item("wall")
        
        #expect(finalKeyState.parent == .player)
        #expect(finalCoinState.parent == .player)
        #expect(finalWallState.parent == .location(.startRoom)) // Wall stays

        // Assert: Appropriate message
        let output = await mockIO.flush()
        expectNoDifference(output, "You take the gold coin and the brass key.")
    }

    @Test("TAKE ALL with capacity limit")
    func testTakeAllCapacityLimit() async throws {
        // Arrange: Items that exceed player capacity
        let key = Item(
            id: "key",
            .name("brass key"),
            .in(.location(.startRoom)),
            .isTakable,
            .size(3)
        )
        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .in(.location(.startRoom)),
            .isTakable,
            .size(2)
        )
        let boulder = Item(
            id: "boulder",
            .name("heavy boulder"),
            .in(.location(.startRoom)),
            .isTakable,
            .size(10) // Too heavy
        )
        
        let player = Player(in: .startRoom, carryingCapacity: 6) // Can only carry key + coin
        let game = MinimalGame(player: player, items: [key, coin, boulder])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(
            verb: .take,
            directObjects: [.item("coin"), .item("key")], // Boulder filtered out by capacity
            isAllCommand: true,
            rawInput: "take all"
        )

        // Act
        await engine.execute(command: command)

        // Assert: Only items within capacity are taken
        let finalKeyState = try await engine.item("key")
        let finalCoinState = try await engine.item("coin")
        let finalBoulderState = try await engine.item("boulder")
        
        #expect(finalKeyState.parent == .player)
        #expect(finalCoinState.parent == .player)
        #expect(finalBoulderState.parent == .location(.startRoom)) // Boulder stays

        // Assert: Appropriate message
        let output = await mockIO.flush()
        expectNoDifference(output, "You take the gold coin and the brass key.")
    }

    @Test("DROP ALL with multiple held items")
    func testDropAllMultipleItems() async throws {
        // Arrange: Multiple items held by player
        let key = Item(
            id: "key",
            .name("brass key"),
            .in(.player),
            .isTakable,
            .size(2)
        )
        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .in(.player),
            .isTakable,
            .size(1)
        )
        let lamp = Item(
            id: "lamp",
            .name("brass lamp"),
            .in(.player),
            .isTakable,
            .size(3)
        )
        
        let game = MinimalGame(items: [key, coin, lamp])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(
            verb: .drop,
            directObjects: [.item("coin"), .item("key"), .item("lamp")], // Sorted by name
            isAllCommand: true,
            rawInput: "drop all"
        )

        // Act
        await engine.execute(command: command)

        // Assert: All items should be dropped
        let finalKeyState = try await engine.item("key")
        let finalCoinState = try await engine.item("coin")
        let finalLampState = try await engine.item("lamp")
        
        #expect(finalKeyState.parent == .location(.startRoom))
        #expect(finalCoinState.parent == .location(.startRoom))
        #expect(finalLampState.parent == .location(.startRoom))

        // Assert: Appropriate message
        let output = await mockIO.flush()
        expectNoDifference(output, "You drop the gold coin, the brass key, and the brass lamp.")

        // Assert: Pronouns updated to last item
        #expect(await engine.getPronounReference(pronoun: "it") == [.item("lamp")])
        #expect(await engine.getPronounReference(pronoun: "them") == [
            .item("lamp"),
            .item("key"),
            .item("coin"),
        ])
    }

    @Test("DROP ALL with no held items")
    func testDropAllNoItems() async throws {
        // Arrange: Player holding nothing
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(
            verb: .drop,
            directObjects: [], // Empty because player holds nothing
            isAllCommand: true,
            rawInput: "drop all"
        )

        // Act
        await engine.execute(command: command)

        // Assert: Appropriate message
        let output = await mockIO.flush()
        #expect(output == "You aren’t carrying anything.")

        // Assert: No state changes
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("TAKE ALL single item uses singular message")
    func testTakeAllSingleItem() async throws {
        // Arrange: Only one takable item
        let key = Item(
            id: "key",
            .name("brass key"),
            .in(.location(.startRoom)),
            .isTakable,
            .size(2)
        )
        
        let player = Player(in: .startRoom, carryingCapacity: 20)
        let game = MinimalGame(player: player, items: [key])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(
            verb: .take,
            directObjects: [.item("key")],
            isAllCommand: true,
            rawInput: "take all"
        )

        // Act
        await engine.execute(command: command)

        // Assert: Singular message format
        let output = await mockIO.flush()
        #expect(output == "You take the brass key.")

        // Assert: Item is taken
        let finalKeyState = try await engine.item("key")
        #expect(finalKeyState.parent == .player)
    }

    @Test("DROP ALL single item uses singular message")
    func testDropAllSingleItem() async throws {
        // Arrange: Player holding one item
        let key = Item(
            id: "key",
            .name("brass key"),
            .in(.player),
            .isTakable,
            .size(2)
        )
        
        let game = MinimalGame(items: [key])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(
            verb: .drop,
            directObjects: [.item("key")],
            isAllCommand: true,
            rawInput: "drop all"
        )

        // Act
        await engine.execute(command: command)

        // Assert: Singular message format
        let output = await mockIO.flush()
        #expect(output == "You drop the brass key.")

        // Assert: Item is dropped
        let finalKeyState = try await engine.item("key")
        #expect(finalKeyState.parent == .location(.startRoom))
    }

    @Test("TAKE ALL skips items already held")
    func testTakeAllSkipsHeldItems() async throws {
        // Arrange: Mix of held and unheld items
        let heldKey = Item(
            id: "heldKey",
            .name("silver key"),
            .in(.player),
            .isTakable,
            .size(2)
        )
        let roomKey = Item(
            id: "roomKey",
            .name("brass key"),
            .in(.location(.startRoom)),
            .isTakable,
            .size(2)
        )
        
        let player = Player(in: .startRoom, carryingCapacity: 20)
        let game = MinimalGame(player: player, items: [heldKey, roomKey])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(
            verb: .take,
            directObjects: [.item("roomKey")], // Only room key should be in the list
            isAllCommand: true,
            rawInput: "take all"
        )

        // Act
        await engine.execute(command: command)

        // Assert: Only room key is taken (held key skipped)
        let finalHeldKeyState = try await engine.item("heldKey")
        let finalRoomKeyState = try await engine.item("roomKey")
        
        #expect(finalHeldKeyState.parent == .player) // Still held
        #expect(finalRoomKeyState.parent == .player) // Now taken

        // Assert: Message only mentions newly taken item
        let output = await mockIO.flush()
        #expect(output == "You take the brass key.")
    }
} 
