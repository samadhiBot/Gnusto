import CustomDump
import Testing

@testable import GnustoEngine

@Suite("SmellActionHandler Tests")
struct SmellActionHandlerTests {
    let handler = SmellActionHandler()

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

    @Test("SMELL without object produces expected message")
    func testSmellWithoutObject() async throws {
        let engine = await createTestEngine()
        let mockIO = engine.ioHandler as! MockIOHandler

        let command = Command(
            verb: .smell,
            rawInput: "smell"
        )

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You smell nothing unusual.")
    }

    @Test("SMELL with item produces expected message")
    func testSmellWithItem() async throws {
        let testItem = Item(
            id: "apple",
            .name("red apple"),
            .description("A juicy red apple."),
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
            verb: .smell,
            directObject: .item("apple"),
            rawInput: "smell apple"
        )

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "That smells about average.")
    }

    @Test("SMELL validation rejects non-item objects")
    func testSmellValidationRejectsNonItems() async throws {
        let engine = await createTestEngine()

        let command = Command(
            verb: .smell,
            directObject: .location(.startRoom),
            rawInput: "smell room"
        )
        let context = ActionContext(
            command: command,
            engine: engine,
            stateSnapshot: await engine.gameState
        )

        // Should throw validation error for non-item
        do {
            try await handler.validate(context: context)
            Issue.record("Expected validation to throw for non-item direct object")
        } catch {
            // Expected - should reject non-item objects
        }
    }

    @Test("SMELL validation succeeds for items")
    func testSmellValidationSucceedsForItems() async throws {
        let testItem = Item(
            id: "flower",
            .name("rose"),
            .description("A beautiful red rose."),
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
            verb: .smell,
            directObject: .item("flower"),
            rawInput: "smell flower"
        )
        let context = ActionContext(
            command: command,
            engine: engine,
            stateSnapshot: await engine.gameState
        )

        // Should not throw - items are valid for smelling
        try await handler.validate(context: context)
    }

    @Test("SMELL validation succeeds with no direct object")
    func testSmellValidationSucceedsWithoutObject() async throws {
        let engine = await createTestEngine()

        let command = Command(
            verb: .smell,
            rawInput: "smell"
        )
        let context = ActionContext(
            command: command,
            engine: engine,
            stateSnapshot: await engine.gameState
        )

        // Should not throw - smelling the environment is valid
        try await handler.validate(context: context)
    }

    @Test("SMELL produces correct ActionResult for environment")
    func testSmellEnvironmentActionResult() async throws {
        let engine = await createTestEngine()

        let command = Command(
            verb: .smell,
            rawInput: "smell"
        )
        let context = ActionContext(
            command: command,
            engine: engine,
            stateSnapshot: await engine.gameState
        )
        
        // Process the command directly
        let result = try await handler.process(context: context)
        
        // Verify result
        #expect(result.message == "You smell nothing unusual.")
        #expect(result.stateChanges.isEmpty) // SMELL should not modify state
        #expect(result.sideEffects.isEmpty) // SMELL should not have side effects
    }

    @Test("SMELL produces correct ActionResult for item")
    func testSmellItemActionResult() async throws {
        let testItem = Item(
            id: "cheese",
            .name("old cheese"),
            .description("A piece of very old cheese."),
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
            verb: .smell,
            directObject: .item("cheese"),
            rawInput: "smell cheese"
        )
        let context = ActionContext(
            command: command,
            engine: engine,
            stateSnapshot: await engine.gameState
        )
        
        // Process the command directly
        let result = try await handler.process(context: context)
        
        // Verify result
        #expect(result.message == "That smells about average.")
        #expect(result.stateChanges.isEmpty) // SMELL should not modify state
        #expect(result.sideEffects.isEmpty) // SMELL should not have side effects
    }

    @Test("SMELL does not affect game state")
    func testSmellDoesNotAffectGameState() async throws {
        let engine = await createTestEngine()
        
        // Capture initial state
        let initialState = await engine.gameState
        let initialScore = initialState.player.score
        let initialMoves = initialState.player.moves
        let initialLocation = initialState.player.currentLocationID
        
        let command = Command(
            verb: .smell,
            rawInput: "smell"
        )

        // Execute SMELL
        await engine.execute(command: command)

        // Verify state hasn't changed
        let finalState = await engine.gameState
        #expect(finalState.player.score == initialScore)
        #expect(finalState.player.moves == initialMoves)
        #expect(finalState.player.currentLocationID == initialLocation)
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("SMELL works in different locations")
    func testSmellWorksInDifferentLocations() async throws {
        let location1 = Location(
            id: "garden",
            .name("Rose Garden"),
            .description("A beautiful garden filled with roses.")
        )
        let location2 = Location(
            id: "kitchen", 
            .name("Kitchen"),
            .description("A kitchen with various cooking smells.")
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
            verb: .smell,
            rawInput: "smell"
        )

        // Test in first location
        await engine.execute(command: command)
        let output1 = await mockIO.flush()
        expectNoDifference(output1, "You smell nothing unusual.")

        // Move to second location
        let moveChange = StateChange(
            entityID: .player,
            attribute: .playerLocation,
            newValue: .locationID("kitchen")
        )
        try await engine.apply(moveChange)

        // Test in second location - should give same generic response
        await engine.execute(command: command)
        let output2 = await mockIO.flush()
        expectNoDifference(output2, "You smell nothing unusual.")
    }

    @Test("SMELL works with items in different locations")
    func testSmellWorksWithItemsInDifferentLocations() async throws {
        let testItem = Item(
            id: "perfume",
            .name("bottle of perfume"),
            .description("An expensive bottle of perfume."),
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
            verb: .smell,
            directObject: .item("perfume"),
            rawInput: "smell perfume"
        )

        // Test smelling item in room
        await engine.execute(command: command)
        let output = await mockIO.flush()
        expectNoDifference(output, "That smells about average.")
    }

    @Test("SMELL message is consistent across multiple calls")
    func testSmellConsistency() async throws {
        let engine = await createTestEngine()
        let mockIO = engine.ioHandler as! MockIOHandler

        let command = Command(
            verb: .smell,
            rawInput: "smell"
        )

        // Execute SMELL multiple times
        await engine.execute(command: command)
        let firstOutput = await mockIO.flush()
        
        await engine.execute(command: command)
        let secondOutput = await mockIO.flush()
        
        await engine.execute(command: command)
        let thirdOutput = await mockIO.flush()

        // All outputs should be identical
        expectNoDifference(firstOutput, "You smell nothing unusual.")
        expectNoDifference(secondOutput, "You smell nothing unusual.")
        expectNoDifference(thirdOutput, "You smell nothing unusual.")
    }

    @Test("SMELL with carried item works")
    func testSmellWithCarriedItem() async throws {
        let testItem = Item(
            id: "soap",
            .name("bar of soap"),
            .description("A fragrant bar of soap."),
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
            verb: .smell,
            directObject: .item("soap"),
            rawInput: "smell soap"
        )

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "That smells about average.")
    }

    @Test("SMELL works in dark room")
    func testSmellWorksInDarkRoom() async throws {
        let darkLocation = Location(
            id: "dark_cave",
            .name("Dark Cave"),
            .description("A pitch black cave.")
            // No .inherentlyLit, so it should be dark
        )
        
        let player = Player(in: "dark_cave")
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
            verb: .smell,
            rawInput: "smell"
        )

        // Act: SMELL should work even in dark rooms (smell doesn't require sight)
        await engine.execute(command: command)

        // Assert Output - should still work
        let output = await mockIO.flush()
        expectNoDifference(output, "You smell nothing unusual.")
    }
} 
