import CustomDump
import Testing

@testable import GnustoEngine

@Suite
struct XyzzyActionHandlerTests {
    // MARK: - Syntax Rule Testing

    @Test("Syntax for 'xyzzy'")
    func testSyntaxXyzzy() async throws {
        let handler = XyzzyActionHandler()
        let syntax = try handler.syntax.primary.parse("xyzzy")
        #expect(syntax.verb == .xyzzy)
    }

    // MARK: - Validation Testing

    @Test("Validation is not required")
    func testValidation() async throws {
        // XyzzyActionHandler has no validation
        let handler = XyzzyActionHandler()
        let (engine, _) = await GameEngine.test(blueprint: MinimalGame.lit())
        let context = ActionContext(
            command: Command(verb: .xyzzy, rawInput: "xyzzy"), engine: engine)
        try await handler.validate(context: context)
    }

    // MARK: - Processing Testing

    @Test("Xyzzy command returns classic message")
    func testXyzzyReturnsClassicMessage() async throws {
        let game = MinimalGame.lit()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("xyzzy")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > xyzzy
            A hollow voice says “Fool.”
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler has correct action ID")
    func testActionID() {
        #expect(XyzzyActionHandler().actionID == .xyzzy)
    }
}
