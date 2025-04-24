import CustomDump
import Testing

@testable import GnustoEngine

@MainActor
@Suite("CloseActionHandler Tests")
struct CloseActionHandlerTests {
    @Test("Close item successfully")
    func testCloseItemSuccessfully() async throws {
        let box = Item(
            id: "box",
            name: "wooden box",
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

        #expect(engine.itemSnapshot(with: "box")?.hasProperty(.open) == true)

        let handler = CloseActionHandler()
        let command = Command(verbID: "close", directObject: "box", rawInput: "close box")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: "box")
        #expect(finalItemState?.hasProperty(.open) == false, "Item should lose .open property")
        #expect(finalItemState?.hasProperty(.touched) == true, "Item should gain .touched property")
        let output = await mockIO.flush()
        expectNoDifference(output, "You close the wooden box.")
    }

    @Test("Close fails with no direct object")
    func testCloseFailsWithNoObject() async throws {
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let handler = CloseActionHandler()
        let command = Command(verbID: "close", rawInput: "close")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, "Close what?")
    }

    @Test("Close fails item not accessible")
    func testCloseFailsItemNotAccessible() async throws {
        let game = MinimalGame(
            items: [
                Item(id: "box", name: "wooden box", properties: .container, .openable, .open),
            ]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let handler = CloseActionHandler()
        let command = Command(verbID: "close", directObject: "box", rawInput: "close box")

        // Act & Assert
        await #expect(throws: ActionError.itemNotAccessible("box")) {
            try await handler.perform(command: command, engine: engine)
        }
    }

    @Test("Close fails item not closeable")
    func testCloseFailsItemNotCloseable() async throws {
        let rock = Item(
            id: "rock",
            name: "heavy rock",
            parent: .location("startRoom")
        ) // Not .openable
        let game = MinimalGame(items: [rock])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let handler = CloseActionHandler()
        let command = Command(verbID: "close", directObject: "rock", rawInput: "close rock")

        // Act & Assert
        // Expecting .itemNotCloseable based on handler logic
        await #expect(throws: ActionError.itemNotCloseable("rock")) {
            try await handler.perform(command: command, engine: engine)
        }
    }

    @Test("Close fails item already closed")
    func testCloseFailsItemAlreadyClosed() async throws {
        let box = Item(
            id: "box",
            name: "wooden box",
            properties: .container, .openable, // Starts closed
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

        let handler = CloseActionHandler()
        let command = Command(verbID: "close", directObject: "box", rawInput: "close box")

        // Act & Assert
        await #expect(throws: ActionError.itemAlreadyClosed("box")) {
            try await handler.perform(command: command, engine: engine)
        }
    }
}
