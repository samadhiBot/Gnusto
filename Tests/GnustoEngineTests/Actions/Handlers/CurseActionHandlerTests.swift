import CustomDump
import Testing

@testable import GnustoEngine

/// Tests for the CurseActionHandler.
@Suite("CurseActionHandler Tests")
struct CurseActionHandlerTests {
    @Test("CURSE without object")
    func testCurseWithoutObject() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("curse", times: 3)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > curse
            You let loose a string of expletives that reveals an impressive
            technical proficiency.

            > curse
            You curse with the fluency of one comfortable with all
            registers of language.

            > curse
            You unleash expletives with the boldness of one who knows
            their craft.
            """)
    }

    @Test("CURSE with object")
    func testCurseWithObject() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("curse the pebble")

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > curse the pebble
            You direct profanity at the pebble with that kind of strategic
            thinking that gets results.
            """)
    }

    @Test("CURSE validation passes without object")
    func testCurseValidationWithoutObject() async throws {
        let (engine, _) = await GameEngine.test()
        let handler = CurseActionHandler()
        let command = Command(verb: .curse, rawInput: "curse")
        let context = ActionContext(command: command, engine: engine)

        // Should not throw
        try await handler.validate(context: context)
    }
}
