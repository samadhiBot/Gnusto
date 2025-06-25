import CustomDump
import Testing

@testable import GnustoEngine

@Suite
struct YellActionHandlerTests {
    // MARK: - Syntax Rule Testing

    @Test("Syntax for 'yell'")
    func testSyntaxYell() async throws {
        let handler = YellActionHandler()
        let syntax = try handler.syntax.first(where: { $0.pattern == [.verb] })!
            .parse("yell")
        #expect(syntax.verb == .yell)
    }

    @Test("Syntax for 'scream at <item>'")
    func testSyntaxScreamAt() async throws {
        let handler = YellActionHandler()
        let syntax = try handler.syntax.first(where: {
            $0.pattern == [.verb, .preposition(.at), .directObject]
        })!
        .parse("scream at rock")
        #expect(syntax.verb == .yell)
        #expect(syntax.directObject == .item(id: "rock"))
    }

    // MARK: - Validation Testing

    @Test("Validation is not required")
    func testValidation() async throws {
        // YellActionHandler has no validation
        let handler = YellActionHandler()
        let (engine, _) = await GameEngine.test(blueprint: MinimalGame.lit())
        let context = ActionContext(command: Command(verb: .yell, rawInput: "yell"), engine: engine)
        try await handler.validate(context: context)
    }

    // MARK: - Processing Testing

    @Test("Yell command returns a response")
    func testYellReturnsResponse() async throws {
        let game = MinimalGame.lit()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("yell")

        let output = await mockIO.flush()
        #expect(!output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    // MARK: - ActionID Testing

    @Test("Handler has correct action ID")
    func testActionID() {
        #expect(YellActionHandler().actionID == .yell)
    }
}
