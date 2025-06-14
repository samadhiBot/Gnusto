import CustomDump
import Testing

@testable import GnustoEngine

@Suite("CryActionHandler Tests")
struct CryActionHandlerTests {

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

    @Test("CRY command")
    func testCry() async throws {
        let (engine, mockIO) = await createTestEngine()
        let command = Command(verb: .cry, rawInput: "cry")

        // Act
        await engine.execute(command: command)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, "You sob dramatically, and feel a little better.")
    }

    @Test("CRY returns varied responses")
    func testCryVariedResponses() async throws {
        let (engine, mockIO) = await createTestEngine()
        let command = Command(verb: .cry, rawInput: "cry")

        // Act
        await engine.execute(command: command)
        await engine.execute(command: command)
        await engine.execute(command: command)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            You sob dramatically, and feel a little better.

            You shed crocodile tears. Very convincing.

            You break down and cry. After a bit the world seems a little
            brighter.
            """)
    }
}
