import CustomDump
import GnustoEngine
import Testing

/// Tests for the GiggleActionHandler.
@Suite("GiggleActionHandler Tests")
struct GiggleActionHandlerTests {

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

    @Test("GIGGLE command")
    func testGiggle() async throws {
        let (engine, mockIO) = await createTestEngine()
        let command = Command(verb: .giggle, rawInput: "giggle")

        // Act
        await engine.execute(command: command)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, "You chortle with delight.")
    }

    @Test("GIGGLE returns varied responses")
    func testGiggleVariedResponses() async throws {
        let (engine, mockIO) = await createTestEngine()
        let command = Command(verb: .giggle, rawInput: "giggle")

        // Act
        await engine.execute(command: command)
        await engine.execute(command: command)
        await engine.execute(command: command)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            You chortle with delight.

            You giggle uncontrollably. How embarrassing!

            You snicker quietly. How mischievous!
            """)
    }
}
