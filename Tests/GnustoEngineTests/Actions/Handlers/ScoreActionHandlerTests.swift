import Testing
import CustomDump
@testable import GnustoEngine

@Suite("ScoreActionHandler Tests")
struct ScoreActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("SCORE syntax works")
    func testScoreSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("score")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > score
            Your score is 0 (total of 0 points), in 1 turn.
            """)
    }

    // MARK: - Processing Testing

    @Test("Score works in dark room")
    func testScoreInDarkRoom() async throws {
        // Given: Dark room
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("score")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > score
            Your score is 0 (total of 0 points), in 1 turn.
            """)
    }

    @Test("Score after several turns")
    func testScoreAfterSeveralTurns() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When - perform some actions to advance turn count
        try await engine.execute("wait")
        try await engine.execute("wait")
        try await engine.execute("score")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > wait
            Time passes.
            > wait
            Time passes.
            > score
            Your score is 0 (total of 0 points), in 3 turns.
            """)
    }

    @Test("Score reflects game state")
    func testScoreReflectsGameState() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("score")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > score
            Your score is 0 (total of 0 points), in 1 turn.
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testCorrectActionIDs() async throws {
        // Given
        let handler = ScoreActionHandler()

        // When & Then
        // ScoreActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testCorrectVerbIDs() async throws {
        // Given
        let handler = ScoreActionHandler()

        // When
        let verbIDs = handler.verbs

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
