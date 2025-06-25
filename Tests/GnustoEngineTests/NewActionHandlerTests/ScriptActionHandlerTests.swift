import CustomDump
import Testing

@testable import GnustoEngine

@Suite
struct ScriptActionHandlerTests {
    @Test("Syntax rule accepts 'script on' and 'script off'",
          .tags(.handler(.script)))
    func testSyntaxRule() async throws {
        let handler = ScriptActionHandler()
        let onSyntax = try handler.syntax.primary.parse("script on")
        #expect(onSyntax.verb == .script)
        #expect(onSyntax.subject == .literal("on"))

        let offSyntax = try handler.syntax.primary.parse("script off")
        #expect(offSyntax.verb == .script)
        #expect(offSyntax.subject == .literal("off"))

        let transcriptOnSyntax = try handler.syntax.synonyms.first?.parse("transcript on")
        #expect(transcriptOnSyntax?.verb == .script)
        #expect(transcriptOnSyntax?.subject == .literal("on"))

        let transcriptOffSyntax = try handler.syntax.synonyms.first?.parse("transcript off")
        #expect(transcriptOffSyntax?.verb == .script)
        #expect(transcriptOffSyntax?.subject == .literal("off"))
    }

    @Test("Processing 'script on' enables scripting",
          .tags(.handler(.script)))
    func testProcessScriptOn() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())
        var scriptingState = try await engine.scriptingState()
        #expect(scriptingState.isScripting == false)

        // When
        try await engine.execute("script on")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
         > script on
         Scripting is now on.
         """)

        scriptingState = try await engine.scriptingState()
        #expect(scriptingState.isScripting == true)
    }

    @Test("Processing 'script off' disables scripting",
          .tags(.handler(.script)))
    func testProcessScriptOff() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())
        try await engine.updateScriptingState { $0.isScripting = true }
        var scriptingState = try await engine.scriptingState()
        #expect(scriptingState.isScripting == true)

        // When
        try await engine.execute("script off")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
         > script off
         Scripting is now off.
         """)

        scriptingState = try await engine.scriptingState()
        #expect(scriptingState.isScripting == false)
    }

    @Test("Processing 'transcript on' enables scripting",
          .tags(.handler(.script)))
    func testProcessTranscriptOn() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())
        var scriptingState = try await engine.scriptingState()
        #expect(scriptingState.isScripting == false)

        // When
        try await engine.execute("transcript on")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
         > transcript on
         Scripting is now on.
         """)

        scriptingState = try await engine.scriptingState()
        #expect(scriptingState.isScripting == true)
    }

    @Test("Unknown subject returns message",
          .tags(.handler(.script)))
    func testUnknownSubject() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())

        // When
        try await engine.execute("script foobar")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
         > script foobar
         I don’t know how to “script foobar”.
         """)
    }

    @Test("Handler has correct action ID",
          .tags(.handler(.script)))
    func testActionID() {
        #expect(ScriptActionHandler().actionID == .script)
    }
}
