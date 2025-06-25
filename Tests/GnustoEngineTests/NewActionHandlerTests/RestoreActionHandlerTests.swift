import CustomDump
import Testing

@testable import GnustoEngine

@Suite("RestoreActionHandler Tests")
struct RestoreActionHandlerTests {
    let handler = RestoreActionHandler()
    var engine: GameEngine!
    var mockIO: MockIOHandler!

    @Before
    func setup() {
        (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())
    }

    // MARK: - Syntax Rule Testing

    @Test("RESTORE syntax works")
    func testRestoreSyntax() async throws {
        try await engine.execute("restore")
        let output = await mockIO.flush()
        #expect(output.contains("Restore failed: Restore functionality not yet implemented."))
    }

    @Test("LOAD synonym works")
    func testLoadSyntax() async throws {
        let loadVerb = Verb(id: .restore, synonyms: ["restore", "load"])
        let customVocabulary = Vocabulary(verbs: [loadVerb] + standardVerbs)
        let parser = StandardParser(vocabulary: customVocabulary)
        (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame(), parser: parser)

        try await engine.execute("load")
        let output = await mockIO.flush()
        #expect(output.contains("Restore failed: Restore functionality not yet implemented."))
    }

    // MARK: - Validation Testing

    @Test("Validation always succeeds")
    func testValidationSucceeds() async throws {
        let context = ActionContext(
            command: Command(verb: .restore, rawInput: "restore"), engine: engine)
        try await handler.validate(context: context)
    }

    // MARK: - Processing Testing

    @Test("Processing returns failure message for now")
    func testProcess() async throws {
        let context = ActionContext(
            command: Command(verb: .restore, rawInput: "restore"), engine: engine)
        let result = try await handler.process(context: context)

        #expect(result.message?.contains("Restore failed") == true)
    }

    // MARK: - ActionID Testing

    @Test("RESTORE action resolves to RestoreActionHandler")
    func testRestoreActionID() async throws {
        let parser = StandardParser()
        let command = try parser.parse("restore")
        let resolvedAction = await engine.resolveAction(for: command)
        #expect(isNotNil(resolvedAction))
        #expect(resolvedAction?.handler is RestoreActionHandler)
    }
}
