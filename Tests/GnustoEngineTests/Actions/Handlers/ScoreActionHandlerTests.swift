import CustomDump
import Testing

@testable import GnustoEngine

@Suite("ScoreActionHandler Tests")
struct ScoreActionHandlerTests {

    @Test("Score performs successfully")
    func testScorePerformsSuccessfully() async throws {
        // Arrange
        // Set up initial player state
        let initialPlayer = Player(in: .startRoom, moves: 10, score: 42)
        let game = MinimalGame(player: initialPlayer)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("score")

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > score
            Your score is 42 in 10 moves.
            """)
    }
}
