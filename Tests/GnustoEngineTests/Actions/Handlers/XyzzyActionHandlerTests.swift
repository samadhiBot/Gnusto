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

        let command = Command(
            verb: .xyzzy,
            rawInput: "xyzzy"
        )

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "A hollow voice says “Fool.”")
    }

    @Test("XYZZY produces correct ActionResult")
    func testXyzzyActionResult() async throws {
        let (engine, mockIO) = await GameEngine.test()

        let command = Command(
            verb: .xyzzy,
            rawInput: "xyzzy"
        )
        let context = ActionContext(
            command: command,
            engine: engine
        )
        
        // Process the command directly
        let result = try await handler.process(context: context)
        
        // Verify result
        #expect(result.message == "A hollow voice says \"Fool.\"")
        #expect(result.changes.isEmpty) // XYZZY should not modify state
        #expect(result.effects.isEmpty) // XYZZY should not have side effects
    }

    @Test("XYZZY validation always succeeds")
    func testXyzzyValidationSucceeds() async throws {
        let (engine, mockIO) = await GameEngine.test()

        let command = Command(
            verb: .xyzzy,
            rawInput: "xyzzy"
        )
        let context = ActionContext(
            command: command,
            engine: engine
        )

        // Should not throw - XYZZY has no validation requirements
        try await handler.validate(context: context)
    }

    @Test("XYZZY with extra text still works")
    func testXyzzyWithExtraText() async throws {
        let (engine, mockIO) = await GameEngine.test()

        let command = Command(
            verb: .xyzzy,
            rawInput: "xyzzy please work"
        )

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Output - should still work the same way
        let output = await mockIO.flush()
        expectNoDifference(output, "A hollow voice says “Fool.”")
    }

    @Test("XYZZY full workflow integration test")
    func testXyzzyFullWorkflow() async throws {
        let (engine, mockIO) = await GameEngine.test()

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
        let (engine, mockIO) = await GameEngine.test()
        
        // Capture initial state
        let initialState = await engine.gameState
        let initialScore = initialState.player.score
        let initialMoves = initialState.player.moves
        let initialLocation = initialState.player.currentLocationID
        
        let command = Command(
            verb: .xyzzy,
            rawInput: "xyzzy"
        )

        // Execute XYZZY
        await engine.execute(command: command)

        // Verify state hasn't changed
        let finalState = await engine.gameState
        #expect(finalState.player.score == initialScore)
        #expect(finalState.player.moves == initialMoves)
        #expect(finalState.player.currentLocationID == initialLocation)
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("XYZZY works regardless of game state")
    func testXyzzyWorksInDifferentStates() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Modify game state
        let scoreChange = StateChange(
            entityID: .player,
            attribute: .playerScore,
            newValue: 100
        )
        try await engine.apply(scoreChange)
        
        let command = Command(
            verb: .xyzzy,
            rawInput: "xyzzy"
        )

        // Act: XYZZY should work the same regardless of game state
        await engine.execute(command: command)

        // Assert Output is unchanged
        let output = await mockIO.flush()
        expectNoDifference(output, "A hollow voice says “Fool.”")
    }

    @Test("XYZZY message is consistent across multiple calls")
    func testXyzzyConsistency() async throws {
        let (engine, mockIO) = await GameEngine.test()

        let command = Command(
            verb: .xyzzy,
            rawInput: "xyzzy"
        )

        // Execute XYZZY multiple times
        await engine.execute(command: command)
        let firstOutput = await mockIO.flush()
        
        await engine.execute(command: command)
        let secondOutput = await mockIO.flush()
        
        await engine.execute(command: command)
        let thirdOutput = await mockIO.flush()

        // All outputs should be identical
        expectNoDifference(firstOutput, "A hollow voice says “Fool.”")
        expectNoDifference(secondOutput, "A hollow voice says “Fool.”")
        expectNoDifference(thirdOutput, "A hollow voice says “Fool.”")
    }
} 
