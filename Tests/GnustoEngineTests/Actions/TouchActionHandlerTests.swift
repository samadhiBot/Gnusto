import CustomDump
import Testing

@testable import GnustoEngine

@MainActor
@Suite("TouchActionHandler Tests")
struct TouchActionHandlerTests {
    let handler = TouchActionHandler()

    @Test("Touch item successfully in location")
    func testTouchItemSuccessfullyInLocation() async throws {
        // Arrange
        let rock = Item(
            id: "rock",
            name: "smooth rock",
            parent: .player
        ) // Not necessarily takable
        let game = MinimalGame(items: [rock])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "touch", directObject: "rock", rawInput: "touch rock")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: "rock")
        #expect(finalItemState?.hasProperty(.touched) == true, "Item should gain .touched property")
        let output = await mockIO.flush()
        expectNoDifference(output, "You feel nothing special.")
    }

    @Test("Touch item successfully held")
    func testTouchItemSuccessfullyHeld() async throws {
        // Arrange
        let key = Item(
            id: "key",
            name: "brass key",
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

        let command = Command(verbID: "touch", directObject: "key", rawInput: "touch key")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: "key")
        #expect(finalItemState?.hasProperty(.touched) == true)
        let output = await mockIO.flush()
        expectNoDifference(output, "You feel nothing special.")
    }

    @Test("Touch fails with no direct object")
    func testTouchFailsWithNoObject() async throws {
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "touch", rawInput: "touch")

        // Act & Assert
        await #expect(throws: ActionError.customResponse("Touch what?")) {
            try await handler.validate(command: command, engine: engine)
        }
        let output = await mockIO.flush()
        #expect(output.isEmpty)
    }

    @Test("Touch fails item not accessible")
    func testTouchFailsItemNotAccessible() async throws {
        let ghost = Item(
            id: "ghost",
            name: "ghostly form",
            parent: .nowhere
        )
        let game = MinimalGame(items: [ghost])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "touch", directObject: "ghost", rawInput: "touch ghost")

        // Act & Assert
        await #expect(throws: ActionError.itemNotAccessible("ghost")) {
            try await handler.validate(command: command, engine: engine)
        }
    }

    @Test("Touch item successfully in open container")
    func testTouchItemInOpenContainer() async throws {
        // Arrange
        let box = Item(
            id: "box",
            name: "wooden box",
            properties: .container, .open,
            parent: .location("startRoom")
        )
        let gem = Item(
            id: "gem",
            name: "ruby gem",
            parent: .item(box.id)
        )
        let game = MinimalGame(items: [box, gem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "touch", directObject: "gem", rawInput: "touch gem")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: "gem")
        #expect(finalItemState?.hasProperty(.touched) == true)
        let output = await mockIO.flush()
        expectNoDifference(output, "You feel nothing special.")
    }

    @Test("Touch item successfully on surface")
    func testTouchItemOnSurface() async throws {
        // Arrange
        let table = Item(
            id: "table",
            name: "wooden table",
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

        let command = Command(verbID: "touch", directObject: "book", rawInput: "touch book")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: "book")
        #expect(finalItemState?.hasProperty(.touched) == true)
        let output = await mockIO.flush()
        expectNoDifference(output, "You feel nothing special.")
    }

    @Test("Touch fails item in closed container")
    func testTouchFailsItemInClosedContainer() async throws {
        // Arrange
        let chest = Item(
            id: "chest",
            name: "locked chest",
            properties: .container, // Closed by default
            parent: .location("startRoom")
        )
        let coin = Item(
            id: "coin",
            name: "gold coin",
            parent: .item(chest.id)
        )
        let game = MinimalGame(items: [chest, coin])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        #expect(chest.hasProperty(.open) == false) // Verify closed

        let command = Command(verbID: "touch", directObject: "coin", rawInput: "touch coin")

        // Act & Assert
        await #expect(throws: ActionError.prerequisiteNotMet("The locked chest is closed.")) {
            try await handler.validate(command: command, engine: engine)
        }
    }
}
