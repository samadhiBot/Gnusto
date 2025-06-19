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
        let (engine, mockIO) = await createTestEngine()
        let command = Command(verb: .sing, rawInput: "sing")

        // Act
        await engine.execute(command: command)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, "You hum a tune under your breath.")
    }

    @Test("SING returns varied responses")
    func testSingVariedResponses() async throws {
        let (engine, mockIO) = await createTestEngine()
        let command = Command(verb: .sing, rawInput: "sing")

        // Act
        await engine.execute(command: command)
        await engine.execute(command: command)
        await engine.execute(command: command)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            You hum a tune under your breath.

            You sing so beautifully that birds gather to listen.

            You warble melodiously. Very soothing.
            """)
    }
}
