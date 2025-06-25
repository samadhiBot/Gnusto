import CustomDump
import Testing

@testable import GnustoEngine

@Suite("HelpActionHandler Tests")
struct HelpActionHandlerTests {
    let handler = HelpActionHandler()
    var engine: GameEngine!
    var mockIO: MockIOHandler!

    @Before
    func setup() {
        (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())
    }

    // MARK: - Syntax Rule Testing

    @Test("HELP syntax works")
    func testHelpSyntax() async throws {
        try await engine.execute("help")
        let output = await mockIO.flush()
        #expect(output.contains("This is an interactive fiction game."))
        #expect(output.contains("Common commands:"))
    }

    // MARK: - Validation Testing

    @Test("Validation always passes")
    func testValidationAlwaysPasses() async throws {
        let context = ActionContext(
            command: Command(verb: .help),
            engine: engine
        )
        // This should not throw any error. If it does, the test fails.
        try await handler.validate(context: context)
    }

    // MARK: - Processing Testing

    @Test("Processing returns the correct help text")
    func testProcessReturnsHelpText() async throws {
        let context = ActionContext(
            command: Command(verb: .help),
            engine: engine
        )
        let result = try await handler.process(context: context)

        #expect(result.message != nil)
        #expect(result.message?.contains("LOOK or L") == true)
        #expect(result.message?.contains("SAVE") == true)
        #expect(result.changes.isEmpty)
        #expect(result.effects.isEmpty)
    }

    // MARK: - ActionID Testing

    @Test("HELP action resolves to HelpActionHandler")
    func testHelpActionID() async throws {
        let parser = StandardParser()
        let command = try parser.parse("help")
        let resolvedAction = await engine.resolveAction(for: command)
        #expect(isNotNil(resolvedAction))
        #expect(resolvedAction?.handler is HelpActionHandler)
    }
}
