import CustomDump
import Testing

@testable import GnustoEngine

@Suite("SaveActionHandler Tests")
struct SaveActionHandlerTests {
    let handler = SaveActionHandler()
    var engine: GameEngine!
    var mockIO: MockIOHandler!

    @Before
    func setup() {
        (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())
    }

    // MARK: - Syntax Rule Testing

    @Test("SAVE syntax works")
    func testSaveSyntax() async throws {
        try await engine.execute("save")
        let output = await mockIO.flush()
        #expect(output.contains("Save failed: Save functionality not yet implemented."))
    }

    // MARK: - Validation Testing

    @Test("Validation always succeeds")
    func testValidationSucceeds() async throws {
        let context = ActionContext(command: Command(verb: .save, rawInput: "save"), engine: engine)
        try await handler.validate(context: context)
    }

    // MARK: - Processing Testing

    @Test("Processing returns failure message for now")
    func testProcess() async throws {
        let context = ActionContext(command: Command(verb: .save, rawInput: "save"), engine: engine)
        let result = try await handler.process(context: context)

        #expect(result.message?.contains("Save failed") == true)
    }

    // MARK: - ActionID Testing

    @Test("SAVE action resolves to SaveActionHandler")
    func testSaveActionID() async throws {
        let parser = StandardParser()
        let command = try parser.parse("save")
        let resolvedAction = await engine.resolveAction(for: command)
        #expect(isNotNil(resolvedAction))
        #expect(resolvedAction?.handler is SaveActionHandler)
    }
}
