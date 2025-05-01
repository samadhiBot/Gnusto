import CustomDump
import Testing

@testable import GnustoEngine

@MainActor
struct ExamineActionHandlerTests {
    let handler = ExamineActionHandler()

    @Test("Examine simple object (in room)")
    func testExamineSimpleObjectInRoom() async throws {
        // Arrange
        let rock = Item(
            id: "rock",
            name: "plain rock",
            longDescription: "It's just a rock.",
            parent: .location("startRoom")
        )

        let game = MinimalGame(items: [rock])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verbID: "examine",
            directObject: "rock",
            rawInput: "examine rock"
        )

        // Act
        await engine.execute(command: command)

        // Assert
        let finalItemState = engine.item(with: "rock")
        #expect(finalItemState?.hasProperty(.touched) == true)
        let output = await mockIO.flush()
        // Expect the actual description now
        expectNoDifference(output, "It’s just a rock.")
    }

    @Test("Examine simple object (held)")
    func testExamineSimpleObjectHeld() async throws {
        // Arrange
        let key = Item(
            id: "key",
            name: "brass key",
            longDescription: "A small brass key.",
            properties: .takable,
            parent: .player
        )

        let game = MinimalGame(items: [key])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verbID: "examine",
            directObject: "key",
            rawInput: "examine key"
        )

        // Act
        await engine.execute(command: command)

        // Assert
        let finalItemState = engine.item(with: "key")
        #expect(finalItemState?.hasProperty(.touched) == true)
        let output = await mockIO.flush()
        expectNoDifference(output, "A small brass key.")
    }

    @Test("Examine readable item (prioritizes text)")
    func testExamineReadableItem() async throws {
        // Arrange
        let scroll = Item(
            id: "scroll",
            name: "ancient scroll",
            longDescription: "A rolled up scroll.",
            properties: .readable,
            parent: .location("startRoom"),
            readableText: "FROBOZZ"
        )

        let game = MinimalGame(items: [scroll])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verbID: "examine",
            directObject: "scroll",
            rawInput: "examine scroll"
        )

        // Act
        await engine.execute(command: command)

        // Assert
        let finalItemState = engine.item(with: "scroll")
        #expect(finalItemState?.hasProperty(.touched) == true)
        let output = await mockIO.flush()
        expectNoDifference(output, "FROBOZZ") // Should print the readableText
    }

    @Test("Examine open container (shows description and contents)")
    func testExamineOpenContainer() async throws {
        // Arrange
        let box = Item(
            id: "box",
            name: "wooden box",
            longDescription: "A plain wooden box.",
            properties: .container, .openable, .open,
            parent: .location("startRoom")
        )
        let gem = Item(
            id: "gem",
            name: "ruby gem",
            parent: .item("box")
        )

        let game = MinimalGame(items: [box, gem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verbID: "examine",
            directObject: "box",
            rawInput: "examine box"
        )

        // Act
        await engine.execute(command: command)

        // Assert
        let finalItemState = engine.item(with: "box")
        #expect(finalItemState?.hasProperty(.touched) == true)
        let output = await mockIO.flush()
        expectNoDifference(output, "A plain wooden box. The wooden box contains a ruby gem.")
    }

    @Test("Examine open empty container")
    func testExamineOpenEmptyContainer() async throws {
        // Arrange
        let box = Item(
            id: "box",
            name: "wooden box",
            longDescription: "A plain wooden box.",
            properties: .container, .openable, .open,
            parent: .location("startRoom")
        )

        let game = MinimalGame(items: [box])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verbID: "examine",
            directObject: "box",
            rawInput: "examine box"
        )

        // Act
        await engine.execute(command: command)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, "A plain wooden box. The wooden box is empty.")
    }

    @Test("Examine closed container (shows description and closed status)")
    func testExamineClosedContainer() async throws {
        // Arrange
        let box = Item(
            id: "box",
            name: "wooden box",
            longDescription: "A plain wooden box.",
            properties: .container, .openable, // Closed by default
            parent: .location("startRoom")
        )

        let game = MinimalGame(items: [box])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verbID: "examine",
            directObject: "box",
            rawInput: "examine box"
        )

        // Act
        await engine.execute(command: command)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, "A plain wooden box. The wooden box is closed.")
    }

    @Test("Examine transparent closed container (shows description and contents)")
    func testExamineTransparentContainer() async throws {
        // Arrange
        let bottle = Item(
            id: "bottle",
            name: "glass bottle",
            longDescription: "A clear glass bottle.",
            properties: .container, .transparent, // Closed by default, but transparent
            parent: .location("startRoom")
        )
        let water = Item(
            id: "water",
            name: "water",
            properties: .narticle,
            parent: .item(bottle.id)
        )

        let game = MinimalGame(items: [bottle, water])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verbID: "examine",
            directObject: "bottle",
            rawInput: "examine bottle"
        )

        // Act
        await engine.execute(command: command)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, "A clear glass bottle. The glass bottle contains water.")
    }

    @Test("Examine surface (shows description and items on it)")
    func testExamineSurface() async throws {
        // Arrange
        let table = Item(
            id: "table",
            name: "sturdy table",
            longDescription: "A sturdy table.",
            properties: .surface,
            parent: .location("startRoom")
        )
        let book = Item(
            id: "book",
            name: "dusty book",
            parent: .item(table.id)
        )

        let game = MinimalGame(items: [table, book])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verbID: "examine",
            directObject: "table",
            rawInput: "examine table"
        )

        // Act
        await engine.execute(command: command)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, "A sturdy table. On the sturdy table is a dusty book.")
    }

    @Test("Examine fails item not accessible")
    func testExamineItemNotAccessible() async throws {
        // Arrange
        let rock = Item(
            id: "rock",
            name: "plain rock",
            longDescription: "It's just a rock.",
            parent: .nowhere
        )
        let game = MinimalGame(items: [rock])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let command = Command(
            verbID: "examine",
            directObject: "rock",
            rawInput: "examine rock"
        )

        // Act
        await engine.execute(command: command)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't see any such thing.")
    }

    @Test("Examine fails in dark room")
    func testExamineInDarkRoom() async throws {
        // Arrange
        let darkRoom = Location(id: "darkRoom", name: "Dark Room")
        let rock = Item(
            id: "rock",
            name: "plain rock",
            parent: .location(darkRoom.id)
        )
        let game = MinimalGame(player: Player(in: darkRoom.id), locations: [darkRoom], items: [rock])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let command = Command(
            verbID: "examine",
            directObject: "rock",
            rawInput: "examine rock"
        )

        // Act
        await engine.execute(command: command)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, "It's too dark to do that.")
    }

    @Test("Examine item with no description")
    func testExamineItemWithNoDescription() async throws {
        // Arrange
        let pebble = Item(
            id: "pebble",
            name: "small pebble",
            parent: .location("startRoom")
            // No description provided
        )
        let game = MinimalGame(items: [pebble])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verbID: "examine",
            directObject: "pebble",
            rawInput: "examine pebble"
        )

        // Act
        await engine.execute(command: command)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, "There's nothing special about the small pebble.")
    }

    @Test("Examine simple object with dynamic description (realistic state)")
    func testExamineSimpleObjectDynamicDescriptionRealistic() async throws {
        // Arrange
        let moodStone = Item(
            id: "stone",
            name: "mood stone",
            longDescription: .id("mood_stone_desc"),
            properties: .device,
            parent: .location("startRoom")
        )

        let game = MinimalGame(items: [moodStone])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        // Register the dynamic handler - reads item's state
        engine.descriptionHandlerRegistry.registerItemHandler(id: "mood_stone_desc") { item, _ in
            // Use hasProperty on the snapshot
            let color = item.hasProperty(.on) ? "red" : "blue"
            return "The mood stone glows a soft \(color)."
        }

        let command = Command(
            verbID: "examine",
            directObject: "stone",
            rawInput: "examine stone"
        )

        // Act 1: Examine when blue (isOn: false)
        await engine.execute(command: command)

        let output1 = await mockIO.flush()
        expectNoDifference(output1, "The mood stone glows a soft blue.")

        // Change the item's state directly via the engine by adding the .on property
        await engine.applyItemPropertyChange(itemID: "stone", adding: [ItemProperty.on])

        // Assert intermediate state change
        #expect(engine.item(with: "stone")?.hasProperty(.on) == true)

        // Act 2: Examine when red (isOn: true)
        await engine.execute(command: command)

        let output2 = await mockIO.flush()
        expectNoDifference(output2, "The mood stone glows a soft red.")
    }
}
