import CustomDump
import Testing

@testable import GnustoEngine

@Suite
struct WaitActionHandlerTests {
    // MARK: - Syntax Rule Testing

    @Test("Syntax for 'wait'")
    func testSyntaxWait() async throws {
        let handler = WaitActionHandler()
        let syntax = try handler.syntax.primary.parse("wait")
        #expect(syntax.verb == .wait)
    }

    @Test("Syntax for 'z'")
    func testSyntaxZ() async throws {
        let handler = WaitActionHandler()
        let syntax = try handler.syntax.primary.parse("z")
        #expect(syntax.verb == .wait)
    }

    // MARK: - Validation Testing

    @Test("Validation is not required")
    func testValidation() async throws {
        // WaitActionHandler has no validation
        let handler = WaitActionHandler()
        let (engine, _) = await GameEngine.test(blueprint: MinimalGame.lit())
        let context = ActionContext(command: Command(verb: .wait, rawInput: "wait"), engine: engine)
        try await handler.validate(context: context)
    }

    // MARK: - Processing Testing

    @Test("Wait command passes time")
    func testWaitPassesTime() async throws {
        let game = MinimalGame.lit()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("wait")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wait
            Time passes.
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler has correct action ID")
    func testActionID() {
        #expect(WaitActionHandler().actionID == .wait)
    }
}
