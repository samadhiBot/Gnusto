import CustomDump
import Testing

@testable import GnustoEngine

@Suite("KnockActionHandler Tests")
struct KnockActionHandlerTests {
    let handler = KnockActionHandler()

    @Test("Knock validates missing direct object")
    func testKnockValidatesMissingDirectObject() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .knock, rawInput: "knock")
        let context = ActionContext(command: command, engine: engine)

        // When / Then
        await #expect(throws: ActionResponse.prerequisiteNotMet("Knock on what?")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Knock door shows appropriate message")
    func testKnockDoorShowsAppropriateMessage() async throws {
        // Given
        let door = Item(
            id: "door",
            .name("wooden door"),
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: [door])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .knock, directObject: .item("door"), rawInput: "knock door")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You knock on the wooden door. It makes a hollow wooden sound."))
    }

    @Test("Knock wall shows sound message")
    func testKnockWallShowsSoundMessage() async throws {
        // Given
        let wall = Item(
            id: "wall",
            .name("stone wall"),
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: [wall])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .knock, directObject: .item("wall"), rawInput: "knock wall")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You knock on the stone wall. It sounds solid."))
    }

    @Test("Knock container shows hollow sound")
    func testKnockContainerShowsHollowSound() async throws {
        // Given
        let chest = Item(
            id: "chest",
            .name("wooden chest"),
            .in(.location(.startRoom)),
            .isContainer
        )

        let game = MinimalGame(items: [chest])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .knock, directObject: .item("chest"), rawInput: "knock chest")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You knock on the wooden chest. It makes a hollow wooden sound."))
    }

    @Test("Knock small object shows inappropriate message")
    func testKnockSmallObjectShowsInappropriateMessage() async throws {
        // Given
        let pebble = Item(
            id: "pebble",
            .name("small pebble"),
            .in(.location(.startRoom)),
            .isTakable
        )

        let game = MinimalGame(items: [pebble])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .knock, directObject: .item("pebble"), rawInput: "knock pebble")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You knock on the small pebble, but it's too small to produce much of a sound."))
    }

    @Test("Knock integration test")
    func testKnockIntegrationTest() async throws {
        // Given
        let door = Item(
            id: "door",
            .name("door"),
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: [door])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .knock, directObject: .item("door"), rawInput: "knock door")

        // When
        await engine.execute(command: command)

        // Then
        let output = await mockIO.flush()
        #expect(output.contains("You knock on the door."))
    }
}
