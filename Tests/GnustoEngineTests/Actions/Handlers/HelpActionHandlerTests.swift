import CustomDump
import Testing
@testable import GnustoEngine

@Suite("HelpActionHandler Tests")
struct HelpActionHandlerTests {
    let handler = HelpActionHandler()

    @Test("Help displays help text")
    func testHelpDisplaysHelpText() async throws {
        // Given
        let (engine, _) = await GameEngine.test()

        let command = Command(verb: .help, rawInput: "help")
        let context = ActionContext(command: command, engine: engine)

        // When
        try await handler.validate(context: context)
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message != nil)
        #expect(result.message!.contains("This is an interactive fiction game"))
        #expect(result.message!.contains("Common commands:"))
        #expect(result.message!.contains("LOOK"))
        #expect(result.message!.contains("TAKE"))
        #expect(result.message!.contains("INVENTORY"))
        #expect(result.changes.isEmpty)
        #expect(result.effects.isEmpty)
    }

    @Test("Help requires no validation")
    func testHelpRequiresNoValidation() async throws {
        // Given
        let (engine, _) = await GameEngine.test()

        let command = Command(verb: .help, rawInput: "help")
        let context = ActionContext(command: command, engine: engine)

        // When/Then - Should not throw
        try await handler.validate(context: context)
    }
}
