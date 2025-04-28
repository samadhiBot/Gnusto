import Testing
import CustomDump

@testable import GnustoEngine

@MainActor
@Suite("LookActionHandler Tests")
struct LookActionHandlerTests {
    // No handler instance needed for engine.execute tests

    // Helper to create the expected StateChange array for examining an item
    private func expectedLookChanges(itemID: ItemID, oldProperties: Set<ItemProperty>) -> [StateChange] {
        // Only expect a change if .touched wasn't already present
        guard !oldProperties.contains(.touched) else { return [] }

        var finalProperties = oldProperties
        finalProperties.insert(.touched)

        return [
            StateChange(
                entityId: .item(itemID),
                propertyKey: .itemProperties,
                oldValue: .itemProperties(oldProperties),
                newValue: .itemProperties(finalProperties)
            )
        ]
        // No pronoun changes expected for look/examine
    }

    @Test("LOOK in lit room describes room and lists items")
    func testLookInLitRoom() async throws {
        // Arrange
        let litRoom = Location(
            id: "litRoom",
            name: "Test Room",
            longDescription: "A basic room.",
            properties: .inherentlyLit
        )
        let item1 = Item(
            id: "widget",
            name: "shiny widget",
            parent: .location("litRoom")
        )
        let item2 = Item(
            id: "gizmo",
            name: "blue gizmo",
            parent: .location("litRoom")
        )

        let game = MinimalGame(
            player: Player(in: "litRoom"),
            locations: [litRoom],
            items: [item1, item2]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "look", rawInput: "look")

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output (primary check for LOOK)
        let output = await mockIO.flush()
        expectNoDifference(output, """
            --- Test Room ---
            A basic room.
            You can see:
              A blue gizmo
              A shiny widget
            """
        )
        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("LOOK in dark room prints darkness message")
    func testLookInDarkRoom() async throws {
        // Arrange
        let darkRoom = Location(
            id: "darkRoom",
            name: "Test Room",
            longDescription: "A basic room."
        )
        let item1 = Item(
            id: "widget",
            name: "shiny widget",
            parent: .location("darkRoom")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: [darkRoom],
            items: [item1]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "look", rawInput: "look")

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "It is pitch black. You are likely to be eaten by a grue.")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("LOOK in lit room (via player light) describes room and lists items")
    func testLookInRoomLitByPlayer() async throws {
        // Arrange
        let darkRoom = Location(
            id: "darkRoom",
            name: "Test Room",
            longDescription: "A basic room."
        )
        let activeLamp = Item(
            id: "lamp",
            name: "lamp",
            properties: .lightSource, .on, .takable,
            parent: .player
        )
        let item1 = Item(
            id: "widget",
            name: "shiny widget",
            parent: .location(darkRoom.id)
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: [darkRoom],
            items: [activeLamp, item1]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "look", rawInput: "look")

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            --- Test Room ---
            A basic room.
            You can see:
              A shiny widget
            """
        )
        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    // --- LOOK AT / EXAMINE Tests ---

    @Test("LOOK AT item shows description and marks touched")
    func testLookAtItem() async throws {
        // Arrange
        let item = Item(
            id: "rock",
            name: "plain rock",
            longDescription: "It looks like a rock.",
            parent: .location("startRoom")
        )
        let initialProperties = item.properties

        let game = MinimalGame(items: [item])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.itemSnapshot(with: "rock")?.hasProperty(.touched) == false)
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "examine", directObject: "rock", rawInput: "x rock")

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "It looks like a rock.")

        // Assert Final State
        let finalItemState = engine.itemSnapshot(with: "rock")
        #expect(finalItemState?.hasProperty(.touched) == true, "Item should be marked touched")

        // Assert Change History
        let expectedChanges = expectedLookChanges(itemID: "rock", oldProperties: initialProperties)
        expectNoDifference(engine.gameState.changeHistory, expectedChanges)
    }

    @Test("LOOK AT item with no description shows default message and marks touched")
    func testLookAtItemNoDescription() async throws {
        // Arrange
        let item = Item(
            id: "pebble",
            name: "small pebble",
            parent: .location("startRoom")
        )
        let initialProperties = item.properties

        let game = MinimalGame(items: [item])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.itemSnapshot(with: "pebble")?.hasProperty(.touched) == false)
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "look", directObject: "pebble", rawInput: "l pebble")

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You see nothing special about the small pebble.")

        // Assert Final State
        let finalItemState = engine.itemSnapshot(with: "pebble")
        #expect(finalItemState?.hasProperty(.touched) == true, "Item should be marked touched")

        // Assert Change History
        let expectedChanges = expectedLookChanges(itemID: "pebble", oldProperties: initialProperties)
        expectNoDifference(engine.gameState.changeHistory, expectedChanges)
    }

    @Test("LOOK AT already touched item shows description, no state change")
    func testLookAtAlreadyTouchedItem() async throws {
        // Arrange
        let item = Item(
            id: "stone",
            name: "smooth stone",
            longDescription: "A familiar smooth stone.",
            properties: .touched,
            parent: .location("startRoom")
        )
        let initialProperties = item.properties

        let game = MinimalGame(items: [item])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.itemSnapshot(with: "stone")?.hasProperty(.touched) == true)
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "examine", directObject: "stone", rawInput: "x stone")

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "A familiar smooth stone.")

        // Assert Final State (remains touched)
        let finalItemState = engine.itemSnapshot(with: "stone")
        #expect(finalItemState?.hasProperty(.touched) == true, "Item should still be marked touched")

        // Assert Change History (Should be empty)
        let expectedChanges = expectedLookChanges(itemID: "stone", oldProperties: initialProperties)
        #expect(expectedChanges.isEmpty == true)
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    // TODO: Add tests for LOOK AT container (open/closed/transparent) and surface

    @Test("LOOK AT open container shows description, contents, and marks touched")
    func testLookAtOpenContainer() async throws {
        // Arrange
        let box = Item(
            id: "box",
            name: "wooden box",
            longDescription: "A sturdy wooden box.",
            properties: .container, .openable, .open,
            parent: .location("startRoom")
        )
        let coin = Item(
            id: "coin",
            name: "gold coin",
            parent: .item("box") // Inside the box
        )
        let initialProperties = box.properties

        let game = MinimalGame(items: [box, coin])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.itemSnapshot(with: "box")?.hasProperty(.touched) == false)
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "examine", directObject: "box", rawInput: "x box")

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output (Description + Contents)
        let output = await mockIO.flush()
        let expectedOutput = """
            A sturdy wooden box.
            The wooden box contains:
              A gold coin
            """
        expectNoDifference(output, expectedOutput)

        // Assert Final State (Container marked touched)
        let finalItemState = engine.itemSnapshot(with: "box")
        #expect(finalItemState?.hasProperty(.touched) == true, "Container should be marked touched")

        // Assert Change History
        let expectedChanges = expectedLookChanges(itemID: "box", oldProperties: initialProperties)
        expectNoDifference(engine.gameState.changeHistory, expectedChanges)
    }

    @Test("LOOK AT closed container shows description, closed message, and marks touched")
    func testLookAtClosedContainer() async throws {
        // Arrange
        let box = Item(
            id: "box",
            name: "wooden box",
            longDescription: "A sturdy wooden box.",
            properties: .container, .openable,
            parent: .location("startRoom")
        )
        let coin = Item(
            id: "coin",
            name: "gold coin",
            parent: .item("box") // Inside the box
        )
        let initialProperties = box.properties

        let game = MinimalGame(items: [box, coin])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.itemSnapshot(with: "box")?.hasProperty(.touched) == false)
        #expect(engine.itemSnapshot(with: "box")?.hasProperty(.open) == false)
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "examine", directObject: "box", rawInput: "x box")

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output (Description + Closed Message)
        let output = await mockIO.flush()
        let expectedOutput = """
            A sturdy wooden box.
            The wooden box is closed.
            """
        expectNoDifference(output, expectedOutput)

        // Assert Final State (Container marked touched)
        let finalItemState = engine.itemSnapshot(with: "box")
        #expect(finalItemState?.hasProperty(.touched) == true, "Container should be marked touched")

        // Assert Change History
        let expectedChanges = expectedLookChanges(itemID: "box", oldProperties: initialProperties)
        expectNoDifference(engine.gameState.changeHistory, expectedChanges)
    }

    @Test("LOOK AT closed transparent container shows description, contents, and marks touched")
    func testLookAtTransparentContainer() async throws {
        // Arrange
        let jar = Item(
            id: "jar",
            name: "glass jar",
            longDescription: "A clear glass jar.",
            properties: .container, .openable, .transparent,
            parent: .location("startRoom")
        )
        let fly = Item(
            id: "fly",
            name: "dead fly",
            parent: .item("jar") // Inside the jar
        )
        let initialProperties = jar.properties

        let game = MinimalGame(items: [jar, fly])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.itemSnapshot(with: "jar")?.hasProperty(.touched) == false)
        #expect(engine.itemSnapshot(with: "jar")?.hasProperty(.open) == false)
        #expect(engine.itemSnapshot(with: "jar")?.hasProperty(.transparent) == true)
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "examine", directObject: "jar", rawInput: "x jar")

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output (Description + Contents because transparent)
        let output = await mockIO.flush()
        let expectedOutput = """
            A clear glass jar.
            The glass jar contains:
              A dead fly
            """
        expectNoDifference(output, expectedOutput)

        // Assert Final State (Container marked touched)
        let finalItemState = engine.itemSnapshot(with: "jar")
        #expect(finalItemState?.hasProperty(.touched) == true, "Container should be marked touched")

        // Assert Change History
        let expectedChanges = expectedLookChanges(itemID: "jar", oldProperties: initialProperties)
        expectNoDifference(engine.gameState.changeHistory, expectedChanges)
    }

    @Test("LOOK AT surface shows description, contents, and marks touched")
    func testLookAtSurface() async throws {
        // Arrange
        let table = Item(
            id: "table",
            name: "wooden table",
            longDescription: "A simple wooden table.",
            properties: .surface,
            parent: .location("startRoom")
        )
        let book = Item(
            id: "book",
            name: "red book",
            parent: .item("table") // On the table
        )
        let candle = Item(
            id: "candle",
            name: "white candle",
            parent: .item("table") // On the table
        )
        let initialProperties = table.properties

        let game = MinimalGame(items: [table, book, candle])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.itemSnapshot(with: "table")?.hasProperty(.touched) == false)
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "examine", directObject: "table", rawInput: "x table")

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output (Description + Surface Contents)
        let output = await mockIO.flush()
        // Note: Order depends on internal dictionary iteration, map { $0.name } and sort?
        // Let's assume alphabetical for now.
        let expectedOutput = """
            A simple wooden table.
            On the wooden table is:
              A red book
              A white candle
            """
        expectNoDifference(output, expectedOutput)

        // Assert Final State (Surface marked touched)
        let finalItemState = engine.itemSnapshot(with: "table")
        #expect(finalItemState?.hasProperty(.touched) == true, "Surface should be marked touched")

        // Assert Change History
        let expectedChanges = expectedLookChanges(itemID: "table", oldProperties: initialProperties)
        expectNoDifference(engine.gameState.changeHistory, expectedChanges)
    }

    @Test("LOOK AT item not reachable fails")
    func testLookAtItemNotReachable() async throws {
        // Arrange: Item exists but is in another room
        let item = Item(
            id: "artifact",
            name: "glowing artifact",
            parent: .location("otherRoom")
        )
        let room1 = Location(id: "startRoom", name: "Start Room", properties: .inherentlyLit)
        let room2 = Location(id: "otherRoom", name: "Other Room")

        let game = MinimalGame(
            player: Player(in: "startRoom"),
            locations: [room1, room2],
            items: [item]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.itemSnapshot(with: "artifact") != nil) // Item exists
        #expect(engine.scopeResolver.itemsReachableByPlayer().contains("artifact") == false) // Not reachable
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "examine", directObject: "artifact", rawInput: "x artifact")

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output (Error message)
        let output = await mockIO.flush()
        expectNoDifference(output, "You don't see the glowing artifact here.")

        // Assert Final State (Item remains untouched and where it was)
        let finalItemState = engine.itemSnapshot(with: "artifact")
        #expect(finalItemState?.hasProperty(.touched) == false)
        #expect(finalItemState?.parent == .location("otherRoom"))

        // Assert Change History (Should be empty)
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }
}
