import CustomDump
import Testing

@testable import GnustoEngine

@Suite("ListenActionHandler Tests")
struct ListenActionHandlerTests {
    let handler = ListenActionHandler()

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

    @Test("LISTEN command produces the expected message")
    func testListenBasicFunctionality() async throws {
        let engine = await createTestEngine()
        let mockIO = engine.ioHandler as! MockIOHandler

        let command = Command(
            verb: .listen,
            rawInput: "listen"
        )

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You hear nothing unusual.")
    }

    @Test("LISTEN produces correct ActionResult")
    func testListenActionResult() async throws {
        let engine = await createTestEngine()

        let command = Command(
            verb: .listen,
            rawInput: "listen"
        )
        let context = ActionContext(
            command: command,
            engine: engine,
            stateSnapshot: await engine.gameState
        )
        
        // Process the command directly
        let result = try await handler.process(context: context)
        
        // Verify result
        #expect(result.message == "You hear nothing unusual.")
        #expect(result.stateChanges.isEmpty) // LISTEN should not modify state
        #expect(result.sideEffects.isEmpty) // LISTEN should not have side effects
    }

    @Test("LISTEN validation always succeeds")
    func testListenValidationSucceeds() async throws {
        let engine = await createTestEngine()

        let command = Command(
            verb: .listen,
            rawInput: "listen"
        )
        let context = ActionContext(
            command: command,
            engine: engine,
            stateSnapshot: await engine.gameState
        )

        // Should not throw - LISTEN has no validation requirements
        try await handler.validate(context: context)
    }

    @Test("LISTEN full workflow integration test")
    func testListenFullWorkflow() async throws {
        let engine = await createTestEngine()

        let command = Command(
            verb: .listen,
            rawInput: "listen"
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
        #expect(result.message == "You hear nothing unusual.")
        #expect(result.stateChanges.isEmpty)
        #expect(result.sideEffects.isEmpty)
    }

    @Test("LISTEN does not affect game state")
    func testListenDoesNotAffectGameState() async throws {
        let engine = await createTestEngine()
        
        // Capture initial state
        let initialState = await engine.gameState
        let initialScore = initialState.player.score
        let initialMoves = initialState.player.moves
        let initialLocation = initialState.player.currentLocationID
        
        let command = Command(
            verb: .listen,
            rawInput: "listen"
        )

        // Execute LISTEN
        await engine.execute(command: command)

        // Verify state hasn't changed
        let finalState = await engine.gameState
        #expect(finalState.player.score == initialScore)
        #expect(finalState.player.moves == initialMoves)
        #expect(finalState.player.currentLocationID == initialLocation)
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("LISTEN works regardless of game state")
    func testListenWorksInDifferentStates() async throws {
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
            verb: .listen,
            rawInput: "listen"
        )

        // Act: LISTEN should work the same regardless of game state
        await engine.execute(command: command)

        // Assert Output is unchanged
        let output = await mockIO.flush()
        expectNoDifference(output, "You hear nothing unusual.")
    }

    @Test("LISTEN works in different locations")
    func testListenWorksInDifferentLocations() async throws {
        let location1 = Location(
            id: "location1",
            .name("Quiet Room"),
            .description("A very quiet room.")
        )
        let location2 = Location(
            id: "location2", 
            .name("Noisy Room"),
            .description("A potentially noisy room.")
        )
        
        let game = MinimalGame(locations: [location1, location2])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verb: .listen,
            rawInput: "listen"
        )

        // Test in first location
        await engine.execute(command: command)
        let output1 = await mockIO.flush()
        expectNoDifference(output1, "You hear nothing unusual.")

        // Move to second location
        let moveChange = StateChange(
            entityID: .player,
            attribute: .playerLocation,
            newValue: .locationID("location2")
        )
        try await engine.apply(moveChange)

        // Test in second location - should give same generic response
        await engine.execute(command: command)
        let output2 = await mockIO.flush()
        expectNoDifference(output2, "You hear nothing unusual.")
    }

    @Test("LISTEN with extra text still works")
    func testListenWithExtraText() async throws {
        let engine = await createTestEngine()
        let mockIO = engine.ioHandler as! MockIOHandler

        let command = Command(
            verb: .listen,
            rawInput: "listen carefully"
        )

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Output - should still work the same way
        let output = await mockIO.flush()
        expectNoDifference(output, "You hear nothing unusual.")
    }

    @Test("LISTEN message is consistent across multiple calls")
    func testListenConsistency() async throws {
        let engine = await createTestEngine()
        let mockIO = engine.ioHandler as! MockIOHandler

        let command = Command(
            verb: .listen,
            rawInput: "listen"
        )

        // Execute LISTEN multiple times
        await engine.execute(command: command)
        let firstOutput = await mockIO.flush()
        
        await engine.execute(command: command)
        let secondOutput = await mockIO.flush()
        
        await engine.execute(command: command)
        let thirdOutput = await mockIO.flush()

        // All outputs should be identical
        expectNoDifference(firstOutput, "You hear nothing unusual.")
        expectNoDifference(secondOutput, "You hear nothing unusual.")
        expectNoDifference(thirdOutput, "You hear nothing unusual.")
    }

    @Test("LISTEN works in dark room")
    func testListenWorksInDarkRoom() async throws {
        let darkLocation = Location(
            id: "dark_room",
            .name("Dark Room"),
            .description("A completely dark room.")
            // No .inherentlyLit, so it should be dark
        )
        
        let player = Player(in: "dark_room")
        let game = MinimalGame(
            player: player,
            locations: [darkLocation]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verb: .listen,
            rawInput: "listen"
        )

        // Act: LISTEN should work even in dark rooms
        await engine.execute(command: command)

        // Assert Output - should still work
        let output = await mockIO.flush()
        expectNoDifference(output, "You hear nothing unusual.")
    }

    @Test("LISTEN works with items present")
    func testListenWorksWithItemsPresent() async throws {
        let noisyItem = Item(
            id: "clock",
            .name("ticking clock"),
            .description("A loudly ticking clock."),
            .in(.location(.startRoom))
        )
        
        let game = MinimalGame(items: [noisyItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verb: .listen,
            rawInput: "listen"
        )

        // Act: Default LISTEN should still give generic response even with noisy items
        await engine.execute(command: command)

        // Assert Output - generic response (custom item sounds would need custom handlers)
        let output = await mockIO.flush()
        expectNoDifference(output, "You hear nothing unusual.")
    }
} 
