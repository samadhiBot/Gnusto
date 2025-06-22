import CustomDump
import Testing

@testable import GnustoEngine

@Suite("BreatheActionHandler Tests")
struct BreatheActionHandlerTests {
    let handler = BreatheActionHandler()

    @Test("Breathe validates no direct object allowed")
    func testBreatheValidatesNoDirectObjectAllowed() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test()

        // When / Then
        try await engine.execute("breathe something")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > breathe something
            You can’t breathe that.
            """)
    }

    @Test("Breathe validates no indirect object allowed")
    func testBreatheValidatesNoIndirectObjectAllowed() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test()

        // When / Then
        try await engine.execute("breathe with something")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > breathe with something
            You can’t breathe that.
            """)
    }

    @Test("Breathe succeeds with basic command")
    func testBreatheSucceedsWithBasicCommand() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test()

        // When
        try await engine.execute("breathe")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > breathe
            You inhale slowly, appreciating the universe’s decision to
            include breathable air.
            """)
    }

    @Test("Breathe integration test")
    func testBreatheIntegrationTest() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test()

        // When
        try await engine.execute("breathe", times: 3)

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > breathe
            You inhale slowly, appreciating the universe’s decision to
            include breathable air.

            > breathe
            You breathe with great purpose, although breathing tends to
            happen anyway.

            > breathe
            You take a breath, tasting hints of adventure and
            poor ventilation.
            """)
    }

    @Test("Breathe validation passes with no objects")
    func testBreatheValidationPassesWithNoObjects() async throws {
        // Given
        let (engine, _) = await GameEngine.test()

        let command = Command(
            verb: .breathe,
            rawInput: "breathe"
        )
        let context = ActionContext(command: command, engine: engine)

        // When / Then - Should not throw
        try await handler.validate(context: context)
    }
}
