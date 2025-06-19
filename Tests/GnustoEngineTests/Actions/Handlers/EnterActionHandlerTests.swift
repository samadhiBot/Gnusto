import CustomDump
import Testing

@testable import GnustoEngine

@Suite("EnterActionHandler Tests")
struct EnterActionHandlerTests {
    let handler = EnterActionHandler()

    @Test("Enter validates missing direct object with no enterable items")
    func testEnterValidatesMissingDirectObjectWithNoEnterableItems() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine.test(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verb: .enter,
            rawInput: "enter"
        )
        let context = ActionContext(command: command, engine: engine)

        // When/Then
        await #expect(throws: ActionResponse.prerequisiteNotMet("There's nothing here to enter.")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Enter validates non-item direct object")
    func testEnterValidatesNonItemDirectObject() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine.test(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verb: .enter,
            directObject: .player,
            rawInput: "enter self"
        )
        let context = ActionContext(command: command, engine: engine)

        // When/Then
        await #expect(throws: ActionResponse.prerequisiteNotMet("You can't enter that.")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Enter validates item not accessible")
    func testEnterValidatesItemNotAccessible() async throws {
        // Given
        let booth = Item(
            id: "booth",
            .name("phone booth"),
            .isEnterable,
            .in(.nowhere) // Not accessible
        )

        let game = MinimalGame(items: [booth])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine.test(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verb: .enter,
            directObject: .item("booth"),
            rawInput: "enter booth"
        )
        let context = ActionContext(command: command, engine: engine)

        // When/Then
        await #expect(throws: ActionResponse.itemNotAccessible("booth")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Enter validates item not enterable")
    func testEnterValidatesItemNotEnterable() async throws {
        // Given
        let rock = Item(
            id: "rock",
            .name("large rock"),
            .in(.location(.startRoom)) // Accessible but not enterable
        )

        let game = MinimalGame(items: [rock])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine.test(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verb: .enter,
            directObject: .item("rock"),
            rawInput: "enter rock"
        )
        let context = ActionContext(command: command, engine: engine)

        // When/Then
        await #expect(throws: ActionResponse.prerequisiteNotMet("You can't enter the large rock.")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Enter processes enterable object")
    func testEnterProcessesEnterableObject() async throws {
        // Given
        let booth = Item(
            id: "booth",
            .name("phone booth"),
            .isEnterable,
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: [booth])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine.test(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verb: .enter,
            directObject: .item("booth"),
            rawInput: "enter booth"
        )
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message == "You enter the phone booth.")
        #expect(result.changes.count >= 1) // Should have touch/pronoun updates
    }
}
