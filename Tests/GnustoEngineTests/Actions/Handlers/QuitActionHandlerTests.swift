import CustomDump
import Testing

@testable import GnustoEngine

@Suite("QuitActionHandler Tests")
struct QuitActionHandlerTests {
    let handler = QuitActionHandler()

    // MARK: - Setup Helper
    
    private func createTestEngine() async -> GameEngine {
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        
        return await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )
    }

    // MARK: - Basic Functionality Tests

    @Test("QUIT command produces the expected message")
    func testQuitBasicFunctionality() async throws {
        let engine = await createTestEngine()
        let mockIO = engine.ioHandler as! MockIOHandler

        let command = Command(
            verb: .quit,
            rawInput: "quit"
        )

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Goodbye!")
    }

    @Test("QUIT produces correct ActionResult")
    func testQuitActionResult() async throws {
        let engine = await createTestEngine()

        let command = Command(
            verb: .quit,
            rawInput: "quit"
        )
        let context = ActionContext(
            command: command,
            engine: engine,
            stateSnapshot: await engine.gameState
        )
        
        // Process the command directly
        let result = try await handler.process(context: context)
        
        // Verify result
        #expect(result.message == "Goodbye!")
        #expect(result.stateChanges.isEmpty) // QUIT should not modify state directly
        #expect(result.sideEffects.isEmpty) // QUIT should not have side effects
    }

    @Test("QUIT validation always succeeds")
    func testQuitValidationSucceeds() async throws {
        let engine = await createTestEngine()

        let command = Command(
            verb: .quit,
            rawInput: "quit"
        )
        let context = ActionContext(
            command: command,
            engine: engine,
            stateSnapshot: await engine.gameState
        )

        // Should not throw - QUIT has no validation requirements
        try await handler.validate(context: context)
    }

    @Test("QUIT requests engine to quit")
    func testQuitRequestsEngineQuit() async throws {
        let engine = await createTestEngine()

        let command = Command(
            verb: .quit,
            rawInput: "quit"
        )
        let context = ActionContext(
            command: command,
            engine: engine,
            stateSnapshot: await engine.gameState
        )
        
        // Initially should not be quitting
        #expect(await !engine.shouldQuit)
        
        // Process QUIT command
        let _ = try await handler.process(context: context)
        
        // Engine should now be marked to quit
        #expect(await engine.shouldQuit)
    }

    @Test("Q alias works the same as QUIT")
    func testQAliasWorks() async throws {
        let engine = await createTestEngine()
        let mockIO = engine.ioHandler as! MockIOHandler

        let command = Command(
            verb: .quit, // Q is mapped to .quit verb
            rawInput: "q"
        )

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Output - should be the same as QUIT
        let output = await mockIO.flush()
        expectNoDifference(output, "Goodbye!")
        
        // Should also request quit
        #expect(await engine.shouldQuit)
    }

    @Test("QUIT full workflow integration test")
    func testQuitFullWorkflow() async throws {
        let engine = await createTestEngine()

        let command = Command(
            verb: .quit,
            rawInput: "quit"
        )
        let context = ActionContext(
            command: command,
            engine: engine,
            stateSnapshot: await engine.gameState
        )
        
        // Validate
        try await handler.validate(context: context)
        
        // Process
        let result = try await handler.process(context: context)
        
        // Verify complete workflow
        #expect(result.message == "Goodbye!")
        #expect(result.stateChanges.isEmpty)
        #expect(result.sideEffects.isEmpty)
        #expect(await engine.shouldQuit)
    }

    @Test("QUIT works regardless of game state")
    func testQuitWorksInDifferentStates() async throws {
        let engine = await createTestEngine()
        let mockIO = engine.ioHandler as! MockIOHandler

        // Modify game state
        let scoreChange = StateChange(
            entityID: .player,
            attribute: .playerScore,
            newValue: 100
        )
        try await engine.apply(scoreChange)
        
        let command = Command(
            verb: .quit,
            rawInput: "quit"
        )

        // Act: QUIT should work the same regardless of game state
        await engine.execute(command: command)

        // Assert Output is unchanged
        let output = await mockIO.flush()
        expectNoDifference(output, "Goodbye!")
        
        // Should still request quit
        #expect(await engine.shouldQuit)
    }

    @Test("QUIT does not modify game state")
    func testQuitDoesNotModifyGameState() async throws {
        let engine = await createTestEngine()
        
        // Capture initial state
        let initialState = await engine.gameState
        let initialScore = initialState.player.score
        let initialMoves = initialState.player.moves
        let initialLocation = initialState.player.currentLocationID
        
        let command = Command(
            verb: .quit,
            rawInput: "quit"
        )

        // Execute QUIT
        await engine.execute(command: command)

        // Verify game state hasn't changed (except for quit flag)
        let finalState = await engine.gameState
        #expect(finalState.player.score == initialScore)
        #expect(finalState.player.moves == initialMoves)
        #expect(finalState.player.currentLocationID == initialLocation)
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("QUIT with extra parameters still works")
    func testQuitWithExtraParameters() async throws {
        let engine = await createTestEngine()
        let mockIO = engine.ioHandler as! MockIOHandler

        let command = Command(
            verb: .quit,
            rawInput: "quit game now"
        )

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Output - should work the same way
        let output = await mockIO.flush()
        expectNoDifference(output, "Goodbye!")
        
        // Should request quit
        #expect(await engine.shouldQuit)
    }

    @Test("Multiple QUIT commands maintain quit state")
    func testMultipleQuitCommands() async throws {
        let engine = await createTestEngine()
        let mockIO = engine.ioHandler as! MockIOHandler

        let command = Command(
            verb: .quit,
            rawInput: "quit"
        )

        // Execute QUIT multiple times
        await engine.execute(command: command)
        #expect(await engine.shouldQuit)
        let firstOutput = await mockIO.flush()
        
        await engine.execute(command: command)
        #expect(await engine.shouldQuit) // Should still be quitting
        let secondOutput = await mockIO.flush()

        // Both outputs should be identical
        expectNoDifference(firstOutput, "Goodbye!")
        expectNoDifference(secondOutput, "Goodbye!")
    }
} 
