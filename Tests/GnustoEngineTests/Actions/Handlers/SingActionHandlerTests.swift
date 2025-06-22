import CustomDump
import GnustoEngine
import Testing

/// Tests for the SingActionHandler.
@Suite("SingActionHandler Tests")
struct SingActionHandlerTests {

    // MARK: - Test Setup

    func createTestEngine() async -> (GameEngine, MockIOHandler) {
        let (engine, mockIO) = await GameEngine.test()
        return (engine, mockIO)
    }

    // MARK: - Tests

    @Test("SING returns varied responses")
    func testSingVariedResponses() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("sing", times: 3)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > sing
            You sing the song of your people.

            > sing
            You hum a little theme from an old adventure game.

            > sing
            You warble charmingly, redefining several musical concepts in
            the process.
            """)
    }
}
