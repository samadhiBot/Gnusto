import CustomDump
import Testing

@testable import GnustoEngine

@Suite("BreatheActionHandler Tests")
struct BreatheActionHandlerTests {
    let handler = BreatheActionHandler()

    @Test("Breathe validates no direct object allowed")
    func testBreatheValidatesNoDirectObjectAllowed() async throws {
        // Given
        let mockParser = MockParser()
        let (engine, mockIO) = await GameEngine.test(
            blueprint: game,
            parser: mockParser
        )

        let command = Command(
            verb: .breathe,
            directObject: .item("something"),
            rawInput: "breathe something"
        )
        let context = ActionContext(command: command, engine: engine)

        // When / Then
        await #expect(throws: ActionResponse.prerequisiteNotMet("You can't breathe that.")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Breathe validates no indirect object allowed")
    func testBreatheValidatesNoIndirectObjectAllowed() async throws {
        // Given
        let mockParser = MockParser()
        let (engine, mockIO) = await GameEngine.test(
            blueprint: game,
            parser: mockParser
        )

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
        let (engine, mockIO) = await GameEngine.test(
            blueprint: game,
            parser: StandardParser()
        )

        // When
        try await engine.execute("breathe")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            You take a breath, noting that it’s roughly the same as the
            last one.
            """)
    }

    @Test("Breathe integration test")
    func testBreatheIntegrationTest() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test(
            blueprint: game,
            parser: StandardParser()
        )

        // When
        try await engine.execute("breathe")
        try await engine.execute("breathe")
        try await engine.execute("breathe")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            You take a breath, noting that it’s roughly the same as the
            last one.

            You take a breath, noting that it’s roughly the same as the
            last one.

            You take a tentative breath, unsure whether the atmosphere is
            still working.
            """)
    }

    @Test("Breathe validation passes with no objects")
    func testBreatheValidationPassesWithNoObjects() async throws {
        // Given
        let mockParser = MockParser()
        let (engine, mockIO) = await GameEngine.test(
            blueprint: game,
            parser: mockParser
        )

        let command = Command(
            verb: .breathe,
            rawInput: "breathe"
        )
        let context = ActionContext(command: command, engine: engine)

        // When / Then - Should not throw
        try await handler.validate(context: context)
    }
}
