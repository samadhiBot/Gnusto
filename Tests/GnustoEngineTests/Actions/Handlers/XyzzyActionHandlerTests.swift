import CustomDump
import Testing

@testable import GnustoEngine

@Suite("XyzzyActionHandler Tests")
struct XyzzyActionHandlerTests {
    let handler = XyzzyActionHandler()

    // MARK: - Basic Functionality Tests

    @Test("XYZZY command produces the expected message")
    func testXyzzyBasicFunctionality() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act: Use engine.execute for full pipeline
        try await engine.execute("xyzzy")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > xyzzy
            A hollow voice says “Fool.”
            """)
    }

    @Test("XYZZY with extra text fails")
    func testXyzzyWithExtraText() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act: Use engine.execute for full pipeline
        try await engine.execute("xyzzy please work")

        // Assert Output - should still work the same way
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > xyzzy please work
            I don’t understand that sentence.
            """)
    }

    @Test("XYZZY full workflow integration test")
    func testXyzzyFullWorkflow() async throws {
        let (engine, _) = await GameEngine.test()

        let command = Command(
            verb: .xyzzy,
            rawInput: "xyzzy"
        )
        let context = ActionContext(
            command: command,
            engine: engine
        )

        // Validate
        try await handler.validate(context: context)

        // Process
        let result = try await handler.process(context: context)

        // Verify complete workflow
        #expect(result.message == "A hollow voice says \"Fool.\"")
        #expect(result.changes.isEmpty)
        #expect(result.effects.isEmpty)
    }

    @Test("XYZZY does not affect game state")
    func testXyzzyDoesNotAffectGameState() async throws {
        let (engine, _) = await GameEngine.test()

        // Capture initial state
        let initialState = await engine.gameState
        let initialScore = initialState.player.score
        let initialMoves = initialState.player.moves
        let initialLocation = initialState.player.currentLocationID

        // Execute XYZZY
        try await engine.execute("xyzzy")

        // Verify state hasn’t changed
        let finalState = await engine.gameState
        #expect(finalState.player.score == initialScore)
        #expect(finalState.player.moves == initialMoves)
        #expect(finalState.player.currentLocationID == initialLocation)
        #expect(await engine.gameState.changeHistory.isEmpty)
    }
}
