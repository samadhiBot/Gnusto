import CustomDump
import Testing

@testable import GnustoEngine

@Suite("XyzzyActionHandler Tests")
struct XyzzyActionHandlerTests {
    let handler = XyzzyActionHandler()

    // Expected message constants to avoid repetition and ensure consistency
    private let expectedMarkdown = "A hollow voice says \"Fool.\""
    private let expectedMessage = "A hollow voice says “Fool.”"

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

    @Test("XYZZY command produces the expected message")
    func testXyzzyBasicFunctionality() async throws {
        let engine = await createTestEngine()
        let mockIO = engine.ioHandler as! MockIOHandler

        let command = Command(
            verb: .xyzzy,
            rawInput: "xyzzy"
        )

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, expectedMessage)
    }

    @Test("XYZZY produces correct ActionResult")
    func testXyzzyActionResult() async throws {
        let engine = await createTestEngine()

        let command = Command(
            verb: .xyzzy,
            rawInput: "xyzzy"
        )
        let context = ActionContext(
            command: command,
            engine: engine,
            stateSnapshot: await engine.gameState
        )
        
        // Process the command directly
        let result = try await handler.process(context: context)
        
        // Verify result
        #expect(result.message == expectedMarkdown)
        #expect(result.stateChanges.isEmpty) // XYZZY should not modify state
        #expect(result.sideEffects.isEmpty) // XYZZY should not have side effects
    }

    @Test("XYZZY validation always succeeds")
    func testXyzzyValidationSucceeds() async throws {
        let engine = await createTestEngine()

        let command = Command(
            verb: .xyzzy,
            rawInput: "xyzzy"
        )
        let context = ActionContext(
            command: command,
            engine: engine,
            stateSnapshot: await engine.gameState
        )

        // Should not throw - XYZZY has no validation requirements
        try await handler.validate(context: context)
    }

    @Test("XYZZY with extra text still works")
    func testXyzzyWithExtraText() async throws {
        let engine = await createTestEngine()
        let mockIO = engine.ioHandler as! MockIOHandler

        let command = Command(
            verb: .xyzzy,
            rawInput: "xyzzy please work"
        )

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Output - should still work the same way
        let output = await mockIO.flush()
        expectNoDifference(output, expectedMessage)
    }

    @Test("XYZZY full workflow integration test")
    func testXyzzyFullWorkflow() async throws {
        let engine = await createTestEngine()

        let command = Command(
            verb: .xyzzy,
            rawInput: "xyzzy"
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
        #expect(result.message == expectedMarkdown)
        #expect(result.stateChanges.isEmpty)
        #expect(result.sideEffects.isEmpty)
    }

    @Test("XYZZY does not affect game state")
    func testXyzzyDoesNotAffectGameState() async throws {
        let engine = await createTestEngine()
        
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
            verb: .xyzzy,
            rawInput: "xyzzy"
        )

        // Act: XYZZY should work the same regardless of game state
        await engine.execute(command: command)

        // Assert Output is unchanged
        let output = await mockIO.flush()
        expectNoDifference(output, expectedMessage)
    }

    @Test("XYZZY message is consistent across multiple calls")
    func testXyzzyConsistency() async throws {
        let engine = await createTestEngine()
        let mockIO = engine.ioHandler as! MockIOHandler

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
        expectNoDifference(firstOutput, expectedMessage)
        expectNoDifference(secondOutput, expectedMessage)
        expectNoDifference(thirdOutput, expectedMessage)
    }
} 
