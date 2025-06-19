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

    @Test("SING command")
    func testSing() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("sing")

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > sing
            You hum a tune under your breath.
            """)
    }

    @Test("SING returns varied responses")
    func testSingVariedResponses() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("sing", times: 3)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > sing
            You hum a tune under your breath.

            > sing
            You sing so beautifully that birds gather to listen.

            > sing
            You warble melodiously. Very soothing.
            """)
    }
}
