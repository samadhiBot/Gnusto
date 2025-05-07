import CustomDump
import Testing

@testable import GnustoEngine

@MainActor
@Suite("ScoreActionHandler Tests")
struct ScoreActionHandlerTests {
    let handler = ScoreActionHandler()

    @Test("Score performs successfully")
    func testScorePerformsSuccessfully() async throws {
        // Arrange
        // Set up initial player state
        let initialPlayer = Player(in: "startRoom", moves: 10, score: 42)
        let game = MinimalGame(player: initialPlayer)
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "score", rawInput: "score")

        // Act
        // Call perform(), which uses the default implementation
        // calling validate(), process(), and postProcess().
        await engine.execute(command: command)

        // Assert
        // Check the output message printed by the default postProcess
        let output = await mockIO.flush()
        let expectedMessage = "Your score is 42 in 10 moves."
        expectNoDifference(output, expectedMessage)

        // Verify no state changes were recorded
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }
}
