import CustomDump
import Testing

@testable import GnustoEngine

/// Tests for the DanceActionHandler.
@Suite("DanceActionHandler Tests")
struct DanceActionHandlerTests {

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

    @Test("DANCE command")
    func testDance() async throws {
        let (engine, mockIO) = await createTestEngine()
        let command = Command(verb: .dance, rawInput: "dance")

        // Act
        await engine.execute(command: command)
        await engine.execute(command: command)
        await engine.execute(command: command)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            You cut a rug with style and panache.

            You boogie down with surprising grace.

            You break into spontaneous choreography.
            """)
    }
}
