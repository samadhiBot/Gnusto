import CustomDump
import Testing

@testable import GnustoEngine

@Suite
struct UnscriptActionHandlerTests {
    // MARK: - Syntax Rule Testing

    @Test("Syntax for 'unscript'")
    func testSyntaxUnscript() async throws {
        let handler = UnscriptActionHandler()
        let syntax = try handler.syntax.primary.parse("unscript")
        #expect(syntax.verb == .unscript)
    }

    // MARK: - Validation Testing

    @Test("Validation fails if scripting is not active")
    func testValidationFailsIfNotScripting() async throws {
        let game = MinimalGame.lit()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        try await engine.execute("unscript")
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > unscript
            Scripting is not currently on.
            """)
    }

    // MARK: - Processing Testing

    @Test("Unscripting disables scripting")
    func testUnscriptDisablesScripting() async throws {
        let game = MinimalGame.lit()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        try await engine.setGlobal(.isScripting)

        try await engine.execute("unscript")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > unscript
            🤡 [Transcript recording ended]
            """)

        let isScripting = await engine.hasGlobal(.isScripting)
        #expect(!isScripting)
    }

    // MARK: - ActionID Testing

    @Test("Handler has correct action ID")
    func testActionID() {
        #expect(UnscriptActionHandler().actionID == .unscript)
    }
}
