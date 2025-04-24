import CustomDump
import Testing

@testable import GnustoEngine

@MainActor
@Suite("OpenActionHandler Tests")
struct OpenActionHandlerTests {
    let handler = OpenActionHandler()

    @Test("Open item successfully")
    func testOpenItemSuccessfully() async throws {
        // Arrange
        let closedBox = Item(
            id: "box",
            name: "wooden box",
            properties: .container, .openable, // Starts closed
            parent: .location("startRoom")
        )

        let game = MinimalGame(items: [closedBox])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        #expect(engine.itemSnapshot(with: "box")?.hasProperty(.open) == false)

        let command = Command(verbID: "open", directObject: "box", rawInput: "open box")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: "box")
        #expect(finalItemState?.hasProperty(.open) == true, "Item should gain .open property")
        #expect(finalItemState?.hasProperty(.touched) == true, "Item should gain .touched property")
        let output = await mockIO.flush()
        expectNoDifference(output, "You open the wooden box.")
    }

    @Test("Open fails with no direct object")
    func testOpenFailsWithNoObject() async throws {
        // Arrange
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "open", rawInput: "open")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, "Open what?")
    }

    @Test("Open fails item not accessible")
    func testOpenFailsItemNotAccessible() async throws {
        // Arrange
        let closedBox = Item(
            id: "box",
            name: "wooden box",
            properties: .container, .openable,
            parent: .nowhere
        )

        let game = MinimalGame(items: [closedBox])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "open", directObject: "box", rawInput: "open box")

        // Act & Assert
        await #expect(throws: ActionError.itemNotAccessible("box")) {
            try await handler.perform(command: command, engine: engine)
        }
    }

    @Test("Open fails item not openable")
    func testOpenFailsItemNotOpenable() async throws {
        // Arrange
        let rock = Item(
            id: "rock",
            name: "heavy rock",
            parent: .location("startRoom")
        ) // No .openable

        let game = MinimalGame(items: [rock])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "open", directObject: "rock", rawInput: "open rock")

        // Act & Assert
        await #expect(throws: ActionError.itemNotOpenable("rock")) {
            try await handler.perform(command: command, engine: engine)
        }
    }

    @Test("Open fails item already open")
    func testOpenFailsItemAlreadyOpen() async throws {
        // Arrange
        let openBox = Item(
            id: "box",
            name: "wooden box",
            properties: .container, .openable, .open, // Starts open
            parent: .location("startRoom")
        )

        let game = MinimalGame(items: [openBox])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "open", directObject: "box", rawInput: "open box")

        // Act & Assert
        await #expect(throws: ActionError.itemAlreadyOpen("box")) {
            try await handler.perform(command: command, engine: engine)
        }
    }

    @Test("Open fails item is locked")
    func testOpenFailsItemIsLocked() async throws {
        // Arrange
        let lockedChest = Item(
            id: "chest",
            name: "iron chest",
            properties: .container, .openable, .locked,
            parent: .location("startRoom")
        ) // Locked

        let game = MinimalGame(items: [lockedChest])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "open", directObject: "chest", rawInput: "open chest")

        // Act & Assert
        await #expect(throws: ActionError.itemIsLocked("chest")) {
            try await handler.perform(command: command, engine: engine)
        }
    }
}
