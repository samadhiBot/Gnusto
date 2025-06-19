import CustomDump
import Testing

import GnustoEngine

/// Tests for the LaughActionHandler.
@Suite("LaughActionHandler Tests")
struct LaughActionHandlerTests {

    // MARK: - Test Setup

    func createTestEngine() async -> (GameEngine, MockIOHandler) {
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine.test(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        return (engine, mockIO)
    }

    // MARK: - Tests

    @Test("LAUGH returns varied responses")
    func testLaughVariedResponses() async throws {
        let (engine, mockIO) = await createTestEngine()
        let command = Command(verb: .laugh, rawInput: "laugh")

        // When
        await engine.execute(command: command)
        await engine.execute(command: command)
        await engine.execute(command: command)

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            You chuckle at the meaninglessness of it all.

            You snort with amusement.

            You laugh brazenly at your predicament.
            """)
    }

    @Test("LAUGH at an object")
    func testLaugh() async throws {
        let (engine, mockIO) = await createTestEngine()
        let command = Command(
            verb: .laugh,
            directObject: .item("pebble"),
            rawInput: "laugh at the pebble"
        )

        // When
        await engine.execute(command: command)

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, "You chuckle at the meaninglessness of it all.")
    }
}
