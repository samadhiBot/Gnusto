import CustomDump
import Testing

@testable import GnustoEngine

/// Tests for the DanceActionHandler.
@Suite("DanceActionHandler Tests")
struct DanceActionHandlerTests {

    // MARK: - Test Setup

    func createTestEngine() async -> (GameEngine, MockIOHandler) {
        let mockParser = MockParser()
        let (engine, mockIO) = await GameEngine.test(
            blueprint: game,
            parser: mockParser
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
            You dance an adorable little jig.

            You dance with wild abandon. Bravo!

            You perform a modern interpretive dance.
            """)
    }
}
