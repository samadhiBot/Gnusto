import CustomDump
import Testing

@testable import GnustoEngine

@Suite
struct VerboseActionHandlerTests {
    // MARK: - Syntax Rule Testing

    @Test("Syntax for 'verbose'")
    func testSyntaxVerbose() async throws {
        let handler = VerboseActionHandler()
        let syntax = try handler.syntax.primary.parse("verbose")
        #expect(syntax.verb == .verbose)
    }

    // MARK: - Validation Testing

    @Test("Validation is not required")
    func testValidation() async throws {
        // VerboseActionHandler has no validation
        let handler = VerboseActionHandler()
        let (engine, _) = await GameEngine.test(blueprint: MinimalGame.lit())
        let context = ActionContext(command: Command(verb: .verbose, rawInput: "verbose"), engine: engine)
        try await handler.validate(context: context)
    }

    // MARK: - Processing Testing

    @Test("Verbose command enables verbose mode and disables brief mode")
    func testVerboseEnablesVerboseMode() async throws {
        let game = MinimalGame.lit()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        try await engine.setGlobal(.isBriefMode) // Start with brief mode on

        try await engine.execute("verbose")

        let output = await mockIO.flush()
        expectNoDifference(output, """
         > verbose
         Maximum verbosity.
         """)

        let isVerbose = await engine.hasGlobal(.isVerboseMode)
        let isBrief = await engine.hasGlobal(.isBriefMode)
        #expect(isVerbose)
        #expect(!isBrief)
    }

    // MARK: - ActionID Testing

    @Test("Handler has correct action ID")
    func testActionID() {
        #expect(VerboseActionHandler().actionID == .verbose)
    }
}
