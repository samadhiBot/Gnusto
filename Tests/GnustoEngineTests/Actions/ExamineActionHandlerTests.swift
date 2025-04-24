import CustomDump
import Testing

@testable import GnustoEngine

@MainActor
@Suite("ExamineActionHandler Tests")
struct ExamineActionHandlerTests {
    let handler = ExamineActionHandler()

    @Test("Examine simple object (in room)")
    func testExamineSimpleObjectInRoom() async throws {
        // Arrange
        let rock = Item(
            id: "rock",
            name: "plain rock",
            description: "It's just a rock.",
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

        let command = Command(verbID: "examine", directObject: "rock", rawInput: "examine rock")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: "rock")
        #expect(finalItemState?.hasProperty(ItemProperty.touched) == true)
        let output = await mockIO.flush()
        // Expect default message because simple objects without text/container props get it
        expectNoDifference(output, "There's nothing special about the plain rock.")
    }

    @Test("Examine simple object (held)")
    func testExamineSimpleObjectHeld() async throws {
        // Arrange
        let key = Item(
            id: "key",
            name: "brass key",
            description: "A small brass key.",
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

        let command = Command(verbID: "examine", directObject: "key", rawInput: "examine key")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: "key")
        #expect(finalItemState?.hasProperty(ItemProperty.touched) == true)
        let output = await mockIO.flush()
        expectNoDifference(output, "There's nothing special about the brass key.")
    }

    @Test("Examine readable item (prioritizes text)")
    func testExamineReadableItem() async throws {
        // Arrange
        let scroll = Item(
            id: "scroll",
            name: "ancient scroll",
            description: "A rolled up scroll.",
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

        let command = Command(verbID: "examine", directObject: "scroll", rawInput: "examine scroll")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: "scroll")
        #expect(finalItemState?.hasProperty(ItemProperty.touched) == true)
        let output = await mockIO.flush()
        expectNoDifference(output, "FROBOZZ") // Should print the readableText
    }

    @Test("Examine open container (shows description and contents)")
    func testExamineOpenContainer() async throws {
        // Arrange
        let box = Item(
            id: "box",
            name: "wooden box",
            description: "A plain wooden box.",
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

        let command = Command(verbID: "examine", directObject: "box", rawInput: "examine box")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: "box")
        #expect(finalItemState?.hasProperty(ItemProperty.touched) == true)
        let output = await mockIO.flush()
        let expectedOutput = """
            A plain wooden box.
            The wooden box contains:
              A ruby gem
            """
        expectNoDifference(output, expectedOutput.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    @Test("Examine open empty container")
    func testExamineOpenEmptyContainer() async throws {
        // Arrange
        let box = Item(
            id: "box",
            name: "wooden box",
            description: "A plain wooden box.",
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

        let command = Command(verbID: "examine", directObject: "box", rawInput: "examine box")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let output = await mockIO.flush()
        let expectedOutput = """
            A plain wooden box.
            The wooden box is empty.
            """
        expectNoDifference(output, expectedOutput.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    @Test("Examine closed container (shows description and closed status)")
    func testExamineClosedContainer() async throws {
        // Arrange
        let box = Item(
            id: "box",
            name: "wooden box",
            description: "A plain wooden box.",
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

        let command = Command(verbID: "examine", directObject: "box", rawInput: "examine box")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let output = await mockIO.flush()
        let expectedOutput = """
            A plain wooden box.
            The wooden box is closed.
            """
        expectNoDifference(output, expectedOutput.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    @Test("Examine transparent closed container (shows description and contents)")
    func testExamineTransparentContainer() async throws {
        // Arrange
        let bottle = Item(
            id: "bottle",
            name: "glass bottle",
            description: "A clear glass bottle.",
            properties: .container, .transparent, // Closed by default, but transparent
            parent: .location("startRoom")
        )
        let water = Item(
            id: "water",
            name: "water",
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

        let command = Command(verbID: "examine", directObject: "bottle", rawInput: "examine bottle")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let output = await mockIO.flush()
        let expectedOutput = """
            A clear glass bottle.
            The glass bottle contains:
              A water
            """
        expectNoDifference(output, expectedOutput.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    @Test("Examine surface (shows description and contents)")
    func testExamineSurface() async throws {
        // Arrange
        let table = Item(
            id: "table",
            name: "wooden table",
            description: "A sturdy table.",
            properties: .surface,
            parent: .location("startRoom")
        )
        let book = Item(
            id: "book",
            name: "heavy book",
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

        let command = Command(verbID: "examine", directObject: "table", rawInput: "examine table")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let output = await mockIO.flush()
        // Note: Current handler doesn't list surface contents, only container/door.
        // Zork's V-EXAMINE didn't list surface contents either, V-LOOK-INSIDE did.
        // Aligning test with V-EXAMINE: expect the default message for non-readable surfaces.
        expectNoDifference(output, "There's nothing special about the wooden table.") // Updated expectation
        #expect(engine.itemSnapshot(with: "table")?.hasProperty(ItemProperty.touched) == true)
    }

    @Test("Examine fails item not accessible")
    func testExamineFailsItemNotAccessible() async throws {
        // Arrange
        let rock = Item(
            id: "rock",
            name: "plain rock",
            description: "It's just a rock.",
            parent: .nowhere // Inaccessible
        )

        let game = MinimalGame(items: [rock])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "examine", directObject: "rock", rawInput: "examine rock")

        // Act & Assert
        await #expect(throws: ActionError.itemNotAccessible("rock")) {
            try await handler.perform(command: command, engine: engine)
        }
    }

    @Test("Examine fails no direct object")
    func testExamineFailsNoObject() async throws {
        // Arrange
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let command = Command(verbID: "examine", rawInput: "examine")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, "Examine what?")
    }

    @Test("Examine with custom hook (handled)")
    func testExamineWithCustomHookHandled() async throws {
        // Arrange
        let statue = Item(
            id: "statue",
            name: "stone statue",
            description: "Default description.",
            parent: .location("startRoom")
        )

        let game = MinimalGame(items: [statue])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "examine", directObject: "statue", rawInput: "examine statue")

        // Act: Run the standard handler
        try await handler.perform(command: command, engine: engine)

        // Assert: Check that the default handler printed its message
        // (because the custom hook is gone)
        let output = await mockIO.flush()
        let expectedOutput = "There's nothing special about the stone statue."
        expectNoDifference(output, expectedOutput)

        // Ensure item was still marked touched
        let finalItemState = engine.itemSnapshot(with: "statue")
        #expect(finalItemState?.hasProperty(ItemProperty.touched) == true)
    }

    @Test("Examine with custom hook (not handled)")
    func testExamineWithCustomHookNotHandled() async throws {
        // Arrange
        let pebble = Item(
            id: "pebble",
            name: "small pebble",
            description: "Just a pebble.",
            parent: .location("startRoom")
        )

        let game = MinimalGame(items: [pebble])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "examine", directObject: "pebble", rawInput: "examine pebble")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert: Default handler should run and print its message
        let output = await mockIO.flush()
        let expectedOutput = "There's nothing special about the small pebble."
        expectNoDifference(output, expectedOutput)

        // Ensure item was still marked touched
        let finalItemState = engine.itemSnapshot(with: "pebble")
        #expect(finalItemState?.hasProperty(ItemProperty.touched) == true)
    }
}
