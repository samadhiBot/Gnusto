import CustomDump
import Testing

@testable import GnustoEngine

@Suite("RestartActionHandler Tests")
struct RestartActionHandlerTests {
    let handler = RestartActionHandler()
    var engine: GameEngine!
    var mockIO: MockIOHandler!

    @Before
    func setup() {
        (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())
    }

    // MARK: - Syntax Rule Testing

    @Test("RESTART syntax works")
    func testRestartSyntax() async throws {
        try await engine.execute("restart")
        let output = await mockIO.flush()
        #expect(output.contains("Are you sure you want to restart?"))
        #expect(await engine.shouldQuit == true)
    }

    // MARK: - Validation Testing

    @Test("Validation always succeeds")
    func testValidationSucceeds() async throws {
        let context = ActionContext(
            command: Command(verb: .restart, rawInput: "restart"), engine: engine)
        try await handler.validate(context: context)
    }

    // MARK: - Processing Testing

    @Test("Processing requests a quit and returns the correct message")
    func testProcess() async throws {
        let context = ActionContext(
            command: Command(verb: .restart, rawInput: "restart"), engine: engine)
        let result = try await handler.process(context: context)

        #expect(await engine.shouldQuit == true)
        #expect(result.message?.contains("Are you sure you want to restart?") == true)
        #expect(result.message?.contains("[Game will restart...]") == true)
    }

    // MARK: - ActionID Testing

    @Test("RESTART action resolves to RestartActionHandler")
    func testRestartActionID() async throws {
        let parser = StandardParser()
        let command = try parser.parse("restart")
        let resolvedAction = await engine.resolveAction(for: command)
        #expect(isNotNil(resolvedAction))
        #expect(resolvedAction?.handler is RestartActionHandler)
    }
}
