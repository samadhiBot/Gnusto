import CustomDump
import Testing

@testable import GnustoEngine

@Suite("BreatheActionHandler Tests")
struct BreatheActionHandlerTests {
    let handler = BreatheActionHandler()

    @Test("Breathe validates no direct object allowed")
    func testBreatheValidatesNoDirectObjectAllowed() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .breathe, directObject: .item("something"), rawInput: "breathe something")
        let context = ActionContext(command: command, engine: engine)

        // When / Then
        await #expect(throws: ActionResponse.prerequisiteNotMet("You can't breathe that.")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Breathe validates no indirect object allowed")
    func testBreatheValidatesNoIndirectObjectAllowed() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(
            verb: .breathe,
            indirectObject: .item("something"),
            rawInput: "breathe with something"
        )
        let context = ActionContext(command: command, engine: engine)

        // When / Then
        await #expect(throws: ActionResponse.prerequisiteNotMet("You can't breathe that.")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Breathe succeeds with basic command")
    func testBreatheSucceedsWithBasicCommand() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .breathe, rawInput: "breathe")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        expectNoDifference(
            result.message,
            "You inhale deeply, briefly grateful for the invention of oxygen."
        )
    }

    @Test("Breathe integration test")
    func testBreatheIntegrationTest() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .breathe, rawInput: "breathe")

        // When
        await engine.execute(command: command)
        await engine.execute(command: command)
        await engine.execute(command: command)

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            You inhale deeply, briefly grateful for the invention of
            oxygen.

            You were already doing that, but also you continue to breathe.

            You breathe in life’s very essence, which tastes faintly of
            confusion.
            """)
    }

    @Test("Breathe validation passes with no objects")
    func testBreatheValidationPassesWithNoObjects() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .breathe, rawInput: "breathe")
        let context = ActionContext(command: command, engine: engine)

        // When / Then - Should not throw
        try await handler.validate(context: context)
    }
}
