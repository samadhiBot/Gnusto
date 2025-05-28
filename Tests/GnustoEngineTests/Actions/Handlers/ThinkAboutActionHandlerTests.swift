import CustomDump
import Testing

@testable import GnustoEngine

@Suite("ThinkAboutActionHandler Tests")
struct ThinkAboutActionHandlerTests {
    let handler = ThinkAboutActionHandler()

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

    @Test("THINK ABOUT without object is rejected")
    func testThinkAboutWithoutObject() async throws {
        let engine = await createTestEngine()

        let command = Command(
            verb: .thinkAbout,
            rawInput: "think about"
        )
        let context = ActionContext(
            command: command,
            engine: engine,
            stateSnapshot: await engine.gameState
        )

        // Should throw validation error for missing direct object
        do {
            try await handler.validate(context: context)
            Issue.record("Expected validation to throw for missing direct object")
        } catch {
            // Expected - should require a direct object
        }
    }

    @Test("THINK ABOUT SELF produces specific message")
    func testThinkAboutSelf() async throws {
        let engine = await createTestEngine()
        let mockIO = engine.ioHandler as! MockIOHandler

        let command = Command(
            verb: .thinkAbout,
            directObject: .player,
            rawInput: "think about self"
        )

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Yes, yes, you’re very important.")
    }

    @Test("THINK ABOUT with reachable item produces specific message")
    func testThinkAboutWithReachableItem() async throws {
        let testItem = Item(
            id: "puzzle",
            .name("mysterious puzzle"),
            .description("A complex puzzle box."),
            .isTakable,
            .in(.player)
        )
        
        let game = MinimalGame(items: [testItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verb: .thinkAbout,
            directObject: .item("puzzle"),
            rawInput: "think about puzzle"
        )

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            You contemplate the mysterious puzzle for a bit, but nothing
            fruitful comes to mind.
            """)
    }

    @Test("THINK ABOUT with location is rejected")
    func testThinkAboutWithLocation() async throws {
        let engine = await createTestEngine()

        let command = Command(
            verb: .thinkAbout,
            directObject: .location(.startRoom),
            rawInput: "think about room"
        )
        let context = ActionContext(
            command: command,
            engine: engine,
            stateSnapshot: await engine.gameState
        )

        // Should throw validation error for location
        do {
            try await handler.validate(context: context)
            Issue.record("Expected validation to throw for location direct object")
        } catch {
            // Expected - should reject location objects
        }
    }

    @Test("THINK ABOUT validation succeeds for player")
    func testThinkAboutValidationSucceedsForPlayer() async throws {
        let engine = await createTestEngine()

        let command = Command(
            verb: .thinkAbout,
            directObject: .player,
            rawInput: "think about self"
        )
        let context = ActionContext(
            command: command,
            engine: engine,
            stateSnapshot: await engine.gameState
        )

        // Should not throw - thinking about self is valid
        try await handler.validate(context: context)
    }

    @Test("THINK ABOUT validation succeeds for reachable items")
    func testThinkAboutValidationSucceedsForReachableItems() async throws {
        let testItem = Item(
            id: "key",
            .name("golden key"),
            .description("A beautifully crafted golden key."),
            .isTakable,
            .in(.player)
        )
        
        let game = MinimalGame(items: [testItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verb: .thinkAbout,
            directObject: .item("key"),
            rawInput: "think about key"
        )
        let context = ActionContext(
            command: command,
            engine: engine,
            stateSnapshot: await engine.gameState
        )

        // Should not throw - reachable items are valid
        try await handler.validate(context: context)
    }

    @Test("THINK ABOUT produces correct ActionResult for player")
    func testThinkAboutPlayerActionResult() async throws {
        let engine = await createTestEngine()

        let command = Command(
            verb: .thinkAbout,
            directObject: .player,
            rawInput: "think about self"
        )
        let context = ActionContext(
            command: command,
            engine: engine,
            stateSnapshot: await engine.gameState
        )
        
        // Process the command directly
        let result = try await handler.process(context: context)
        
        // Verify result
        #expect(result.message == "Yes, yes, you're very important.")
        #expect(result.stateChanges.isEmpty) // THINK ABOUT SELF should not modify state
    }

    @Test("THINK ABOUT produces correct ActionResult for item")
    func testThinkAboutItemActionResult() async throws {
        let testItem = Item(
            id: "mirror",
            .name("ornate mirror"),
            .description("An ornate hand mirror with intricate carvings."),
            .isTakable,
            .in(.player)
        )
        
        let game = MinimalGame(items: [testItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verb: .thinkAbout,
            directObject: .item("mirror"),
            rawInput: "think about mirror"
        )
        let context = ActionContext(
            command: command,
            engine: engine,
            stateSnapshot: await engine.gameState
        )
        
        // Process the command directly
        let result = try await handler.process(context: context)
        
        // Verify result
        #expect(result.message == "You contemplate the ornate mirror for a bit, but nothing fruitful comes to mind.")
        #expect(!result.stateChanges.isEmpty) // THINK ABOUT item should set isTouched and update pronouns
    }

    @Test("THINK ABOUT SELF does not modify game state")
    func testThinkAboutSelfDoesNotModifyGameState() async throws {
        let engine = await createTestEngine()
        
        // Capture initial state
        let initialState = await engine.gameState
        let initialScore = initialState.player.score
        let initialMoves = initialState.player.moves
        let initialLocation = initialState.player.currentLocationID
        
        let command = Command(
            verb: .thinkAbout,
            directObject: .player,
            rawInput: "think about self"
        )

        // Execute THINK ABOUT SELF
        await engine.execute(command: command)

        // Verify core state hasn't changed
        let finalState = await engine.gameState
        #expect(finalState.player.score == initialScore)
        #expect(finalState.player.moves == initialMoves)
        #expect(finalState.player.currentLocationID == initialLocation)
    }

    @Test("THINK ABOUT item sets isTouched flag")
    func testThinkAboutItemSetsTouchedFlag() async throws {
        let testItem = Item(
            id: "book",
            .name("leather book"),
            .description("An old leather-bound book."),
            .isTakable,
            .in(.player)
        )
        
        let game = MinimalGame(items: [testItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        // Verify item is not initially touched
        let initialItem = try await engine.item("book")
        #expect(!initialItem.hasFlag(.isTouched))

        let command = Command(
            verb: .thinkAbout,
            directObject: .item("book"),
            rawInput: "think about book"
        )

        // Execute THINK ABOUT
        await engine.execute(command: command)

        // Verify item is now touched
        let finalItem = try await engine.item("book")
        #expect(finalItem.hasFlag(.isTouched))
    }

    @Test("THINK ABOUT works with items in different locations")
    func testThinkAboutWorksWithItemsInDifferentLocations() async throws {
        let testItem = Item(
            id: "painting",
            .name("beautiful painting"),
            .description("A stunning oil painting."),
            .isTakable,
            .in(.location(.startRoom))
        )
        
        let game = MinimalGame(items: [testItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verb: .thinkAbout,
            directObject: .item("painting"),
            rawInput: "think about painting"
        )

        // Test thinking about item in room
        await engine.execute(command: command)
        let output = await mockIO.flush()
        expectNoDifference(output, """
            You contemplate the beautiful painting for a bit, but nothing
            fruitful comes to mind.
            """)
    }

    @Test("THINK ABOUT message is consistent across multiple calls")
    func testThinkAboutConsistency() async throws {
        let engine = await createTestEngine()
        let mockIO = engine.ioHandler as! MockIOHandler

        let command = Command(
            verb: .thinkAbout,
            directObject: .player,
            rawInput: "think about self"
        )

        // Execute THINK ABOUT multiple times
        await engine.execute(command: command)
        let firstOutput = await mockIO.flush()
        
        await engine.execute(command: command)
        let secondOutput = await mockIO.flush()
        
        await engine.execute(command: command)
        let thirdOutput = await mockIO.flush()

        // All outputs should be identical
        expectNoDifference(firstOutput, "Yes, yes, you’re very important.")
        expectNoDifference(secondOutput, "Yes, yes, you’re very important.")
        expectNoDifference(thirdOutput, "Yes, yes, you’re very important.")
    }

    @Test("THINK ABOUT works in dark room")
    func testThinkAboutWorksInDarkRoom() async throws {
        let darkLocation = Location(
            id: "dark_chamber",
            .name("Dark Chamber"),
            .description("A completely dark chamber.")
            // No .inherentlyLit, so it should be dark
        )
        
        let testItem = Item(
            id: "coin",
            .name("silver coin"),
            .description("A shiny silver coin."),
            .isTakable,
            .in(.player)
        )
        
        let player = Player(in: "dark_chamber")
        let game = MinimalGame(
            player: player,
            locations: [darkLocation],
            items: [testItem]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verb: .thinkAbout,
            directObject: .item("coin"),
            rawInput: "think about coin"
        )

        // Act: THINK ABOUT should work even in dark rooms (thinking doesn't require sight)
        await engine.execute(command: command)

        // Assert Output - should still work
        let output = await mockIO.flush()
        expectNoDifference(output, """
            You contemplate the silver coin for a bit, but nothing fruitful
            comes to mind.
            """)
    }

    @Test("THINK ABOUT full workflow integration test")
    func testThinkAboutFullWorkflow() async throws {
        let testItem = Item(
            id: "crystal",
            .name("magic crystal"),
            .description("A glowing crystal with mysterious properties."),
            .isTakable,
            .in(.player)
        )
        
        let game = MinimalGame(items: [testItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verb: .thinkAbout,
            directObject: .item("crystal"),
            rawInput: "think about crystal"
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
        #expect(result.message == "You contemplate the magic crystal for a bit, but nothing fruitful comes to mind.")
        #expect(!result.stateChanges.isEmpty) // Should set touched flag and pronouns
    }

    @Test("THINK ABOUT rejects unreachable items")
    func testThinkAboutRejectsUnreachableItems() async throws {
        let unreachableItem = Item(
            id: "distant_star",
            .name("distant star"),
            .description("A star far away in the sky."),
            .in(.nowhere)
        )
        
        let game = MinimalGame(items: [unreachableItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verb: .thinkAbout,
            directObject: .item("distant_star"),
            rawInput: "think about star"
        )
        let context = ActionContext(
            command: command,
            engine: engine,
            stateSnapshot: await engine.gameState
        )

        // Should throw validation error for unreachable item
        do {
            try await handler.validate(context: context)
            Issue.record("Expected validation to throw for unreachable item")
        } catch {
            // Expected - should reject unreachable items
        }
    }

    @Test("THINK ABOUT with already touched item still works")
    func testThinkAboutWithAlreadyTouchedItem() async throws {
        let testItem = Item(
            id: "sword",
            .name("magic sword"),
            .description("A sword that glows with inner light."),
            .isTakable,
            .isTouched,
            .in(.player)
        )
        
        let game = MinimalGame(items: [testItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verb: .thinkAbout,
            directObject: .item("sword"),
            rawInput: "think about sword"
        )

        // Act: Should work even if item was already touched
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            You contemplate the magic sword for a bit, but nothing fruitful
            comes to mind.
            """)
    }
} 
