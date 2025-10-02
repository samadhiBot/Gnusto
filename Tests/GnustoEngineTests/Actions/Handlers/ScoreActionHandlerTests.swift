import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("ScoreActionHandler Tests")
struct ScoreActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("SCORE syntax works")
    func testScoreSyntax() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("score")

        // Then
        await mockIO.expectOutput(
            """
            > score
            Your score is 0 (total of 10 points), in 0 moves.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Score works in dark room")
    func testScoreInDarkRoom() async throws {
        // Given: Dark room
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("score")

        // Then
        await mockIO.expectOutput(
            """
            > score
            Your score is 0 (total of 10 points), in 0 moves.
            """
        )
    }

    @Test("Score after several moves")
    func testScoreAfterSeveralTurns() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When - perform some actions to advance move count
        try await engine.execute(
            "wait",
            "wait",
            "score"
        )

        // Then
        await mockIO.expectOutput(
            """
            > wait
            Time flows onward, indifferent to your concerns.

            > wait
            The universe's clock ticks inexorably forward.

            > score
            Your score is 0 (total of 10 points), in 2 moves.
            """
        )
    }

    @Test("Score reflects game state")
    func testScoreReflectsGameState() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("score")

        // Then
        await mockIO.expectOutput(
            """
            > score
            Your score is 0 (total of 10 points), in 0 moves.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testCorrectVerbs() async throws {
        // Given
        let handler = ScoreActionHandler()

        // When
        let verbIDs = handler.synonyms

        // Then
        #expect(verbIDs.contains(.score))
    }

    @Test("Handler does not require light")
    func testHandlerDoesNotRequireLight() async throws {
        // Given
        let handler = ScoreActionHandler()

        // When & Then
        #expect(handler.requiresLight == false)
    }
}
