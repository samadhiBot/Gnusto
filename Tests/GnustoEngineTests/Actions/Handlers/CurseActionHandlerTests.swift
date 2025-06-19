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
            You curse the fates that brought you here.

            > curse
            You swear like a sailor. Very cathartic.

            > curse
            You curse fluently in several languages.
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
            You damn the pebble to the seven hells.
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
