import CustomDump
import Testing

@testable import GnustoEngine

@Suite("TurnActionHandler Tests")
struct TurnActionHandlerTests {
    let handler = TurnActionHandler()

    @Test("Turn validates missing direct object")
    func testTurnValidatesMissingDirectObject() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .turn, rawInput: "turn")
        let context = ActionContext(command: command, engine: engine)

        // When / Then
        await #expect(throws: ActionResponse.prerequisiteNotMet("Turn what?")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Turn dial shows clicking message")
    func testTurnDialShowsClickingMessage() async throws {
        // Given
        let dial = Item(
            id: "dial",
            .name("metal dial"),
            .in(.location(.startRoom)),
            .isDial
        )

        let game = MinimalGame(items: [dial])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .turn, directObject: .item("dial"), rawInput: "turn dial")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You turn the metal dial. It clicks into a new position."))
    }

    @Test("Turn knob shows clicking message")
    func testTurnKnobShowsClickingMessage() async throws {
        // Given
        let knob = Item(
            id: "knob",
            .name("brass knob"),
            .in(.location(.startRoom)),
            .isKnob
        )

        let game = MinimalGame(items: [knob])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .turn, directObject: .item("knob"), rawInput: "turn knob")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You turn the brass knob. It clicks into a new position."))
    }

    @Test("Turn wheel shows grinding message")
    func testTurnWheelShowsGrindingMessage() async throws {
        // Given
        let wheel = Item(
            id: "wheel",
            .name("large wheel"),
            .in(.location(.startRoom)),
            .isWheel
        )

        let game = MinimalGame(items: [wheel])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .turn, directObject: .item("wheel"), rawInput: "turn wheel")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You turn the large wheel. It rotates with some effort."))
    }

    @Test("Turn handle shows appropriate message")
    func testTurnHandleShowsAppropriateMessage() async throws {
        // Given
        let handle = Item(
            id: "handle",
            .name("door handle"),
            .in(.location(.startRoom)),
            .isHandle
        )

        let game = MinimalGame(items: [handle])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .turn, directObject: .item("handle"), rawInput: "turn handle")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You turn the door handle. It moves with a grinding sound."))
    }

    @Test("Turn key shows guidance message")
    func testTurnKeyShowsGuidanceMessage() async throws {
        // Given
        let key = Item(
            id: "key",
            .name("brass key"),
            .in(.location(.startRoom)),
            .isTakable,
            .isKey
        )

        let game = MinimalGame(items: [key])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .turn, directObject: .item("key"), rawInput: "turn key")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You can't just turn the brass key by itself. You need to use it with something."))
    }

    @Test("Turn character shows prevention message")
    func testTurnCharacterShowsPreventionMessage() async throws {
        // Given
        let cat = Item(
            id: "cat",
            .name("fluffy cat"),
            .in(.location(.startRoom)),
            .isCharacter
        )

        let game = MinimalGame(items: [cat])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .turn, directObject: .item("cat"), rawInput: "turn cat")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You can't turn the fluffy cat around like an object."))
    }

    @Test("Turn regular object shows default message")
    func testTurnRegularObjectShowsDefaultMessage() async throws {
        // Given
        let book = Item(
            id: "book",
            .name("old book"),
            .in(.location(.startRoom)),
            .isTakable
        )

        let game = MinimalGame(items: [book])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .turn, directObject: .item("book"), rawInput: "turn book")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You turn the old book around in your hands, but nothing happens."))
    }

    @Test("Turn integration test")
    func testTurnIntegrationTest() async throws {
        // Given
        let dial = Item(
            id: "dial",
            .name("dial"),
            .in(.location(.startRoom)),
            .isDial
        )

        let game = MinimalGame(items: [dial])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .turn, directObject: .item("dial"), rawInput: "turn dial")

        // When
        await engine.execute(command: command)

        // Then
        let output = await mockIO.flush()
        #expect(output.contains("You turn the dial."))
    }
}
