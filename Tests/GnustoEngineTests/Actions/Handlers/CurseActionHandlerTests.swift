import CustomDump
import Testing

@testable import GnustoEngine

/// Tests for the CurseActionHandler.
@Suite("CurseActionHandler Tests")
struct CurseActionHandlerTests {
    @Test("CURSE without object")
    func testCurseWithoutObject() async throws {
        let (engine, mockIO) = await GameEngine.test()
        let command = Command(verb: .curse, rawInput: "curse")

        // Act
        await engine.execute(command: command)
        await engine.execute(command: command)
        await engine.execute(command: command)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            You curse under your breath.

            You swear with the passion of a thousand frustrated
            adventurers.

            You swear like a sailor. Very cathartic.
            """)
    }

    @Test("CURSE with object")
    func testCurseWithObject() async throws {
        let (engine, mockIO) = await GameEngine.test()
        let command = Command(
            verb: .curse,
            directObject: .item(.startItem),
            rawInput: "curse the pebble"
        )

        // Act
        await engine.execute(command: command)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, "You curse the pebble roundly. You feel a bit better.")
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
