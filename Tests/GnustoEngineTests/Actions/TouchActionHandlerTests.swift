import CustomDump
import Testing

@testable import GnustoEngine

@Suite("TouchActionHandler Tests")
struct TouchActionHandlerTests {
    let handler = TouchActionHandler()

    @Test("Touch item successfully in location")
    func testTouchItemSuccessfullyInLocation() async throws {
        // Arrange
        let rock = Item(
            id: "rock",
            .name("smooth rock"),
            .in(.player)
        ) // Not necessarily takable
        let game = MinimalGame(items: [rock])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "touch", directObject: "rock", rawInput: "touch rock")

        // Act
        await engine.execute(command: command)

        // Assert
        let finalItemState = await engine.item("rock")
        #expect(finalItemState?.hasFlag(.isTouched) == true, "Item should gain .touched property")
        let output = await mockIO.flush()
        expectNoDifference(output, "You feel nothing special.")
    }

    @Test("Touch item successfully held")
    func testTouchItemSuccessfullyHeld() async throws {
        // Arrange
        let key = Item(
            id: "key",
            .name("brass key"),
            .in(.player),
            .isTakable
        )
        let game = MinimalGame(items: [key])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "touch", directObject: "key", rawInput: "touch key")

        // Act
        await engine.execute(command: command)

        // Assert
        let finalItemState = await engine.item("key")
        #expect(finalItemState?.hasFlag(.isTouched) == true)
        let output = await mockIO.flush()
        expectNoDifference(output, "You feel nothing special.")
    }

    @Test("Touch fails with no direct object")
    func testTouchFailsWithNoObject() async throws {
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "touch", rawInput: "touch")

        // Act & Assert
        await #expect(throws: ActionError.customResponse("Touch what?")) {
            try await handler.validate(
                context: ActionContext(
                    command: command,
                    engine: engine,
                    stateSnapshot: engine.gameState
                )
            )
        }
        let output = await mockIO.flush()
        #expect(output.isEmpty)
    }

    @Test("Touch fails item not accessible")
    func testTouchFailsItemNotAccessible() async throws {
        let figurine = Item(
            id: "figurine",
            .name("jade figurine"),
            .in(.nowhere)
        )
        let game = MinimalGame(items: [figurine])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "touch", directObject: "figurine", rawInput: "touch figurine")

        // Act & Assert
        await #expect(throws: ActionError.itemNotAccessible("figurine")) {
            try await handler.validate(
                context: ActionContext(
                    command: command,
                    engine: engine,
                    stateSnapshot: engine.gameState
                )
            )
        }
    }

    @Test("Touch item successfully in open container")
    func testTouchItemInOpenContainer() async throws {
        // Arrange
        let box = Item(
            id: "box",
            .name("wooden box"),
            .in(.location("startRoom")),
            .isContainer,
            .isOpen
        )
        let gem = Item(
            id: "gem",
            .name("ruby gem"),
            .in(.item("box"))
        )
        let game = MinimalGame(items: [box, gem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "touch", directObject: "gem", rawInput: "touch gem")

        // Act
        await engine.execute(command: command)

        // Assert
        let finalItemState = await engine.item("gem")
        #expect(finalItemState?.hasFlag(.isTouched) == true)
        let output = await mockIO.flush()
        expectNoDifference(output, "You feel nothing special.")
    }

    @Test("Touch item successfully on surface")
    func testTouchItemOnSurface() async throws {
        // Arrange
        let table = Item(
            id: "table",
            .name("wooden table"),
            .in(.location("startRoom")),
            .isSurface
        )
        let book = Item(
            id: "book",
            .name("dusty book"),
            .in(.item("table"))
        )
        let game = MinimalGame(items: [table, book])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verbID: "touch",
            directObject: "book",
            rawInput: "touch book"
        )

        // Act
        await engine.execute(command: command)

        // Assert
        let finalItemState = await engine.item("book")
        #expect(finalItemState?.hasFlag(.isTouched) == true)
        let output = await mockIO.flush()
        expectNoDifference(output, "You feel nothing special.")
    }

    @Test("Touch fails item in closed container")
    func testTouchFailsItemInClosedContainer() async throws {
        // Arrange
        let chest = Item(
            id: "chest",
            .name("locked chest"),
            .in(.location("startRoom")),
            .isContainer // Closed by default
        )
        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .in(.item("chest"))
        )
        let game = MinimalGame(items: [chest, coin])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        #expect(chest.attributes[.isOpen] == nil) // Verify closed

        let command = Command(
            verbID: "touch",
            directObject: "coin",
            rawInput: "touch coin"
        )

        // Act & Assert
        await #expect(throws: ActionError.itemNotAccessible("coin")) {
            try await handler.validate(
                context: ActionContext(
                    command: command,
                    engine: engine,
                    stateSnapshot: engine.gameState
                )
            )
        }
    }
}
