import CustomDump
import Testing

@testable import GnustoEngine

/// Tests for the CurseActionHandler.
@Suite("CurseActionHandler Tests")
struct CurseActionHandlerTests {

    // MARK: - Test Setup

    func createTestEngine() async -> (GameEngine, MockIOHandler) {
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        return (engine, mockIO)
    }

    // MARK: - Tests

    @Test("CURSE without object")
    func testCurseWithoutObject() async throws {
        let (engine, mockIO) = await createTestEngine()
        let command = Command(verb: .curse, rawInput: "curse")

        // Act
        await engine.execute(command: command)
        await engine.execute(command: command)
        await engine.execute(command: command)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            You damn everything in sight. You feel better now.

            You swear like a sailor. Very cathartic.

            You curse fluently in several languages.
            """)
    }

    @Test("CURSE with object")
    func testCurseWithObject() async throws {
        let (engine, mockIO) = await createTestEngine()
        let command = Command(
            verb: .curse,
            directObject: .item(.startItem),
            rawInput: "curse the pebble"
        )

        // Act
        await engine.execute(command: command)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, "You damn the pebble to the seven hells.")
    }

    @Test("CURSE validation passes without object")
    func testCurseValidationWithoutObject() async throws {
        let (engine, _) = await createTestEngine()
        let handler = CurseActionHandler()
        let command = Command(verb: .curse, rawInput: "curse")
        let context = ActionContext(command: command, engine: engine)

        // Should not throw
        try await handler.validate(context: context)
    }
}
