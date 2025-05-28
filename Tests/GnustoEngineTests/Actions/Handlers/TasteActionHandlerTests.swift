import CustomDump
import Testing

@testable import GnustoEngine

@Suite("TasteActionHandler Tests")
struct TasteActionHandlerTests {
    let handler = TasteActionHandler()

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

    @Test("TASTE with item produces expected message")
    func testTasteWithItem() async throws {
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
            verb: .taste,
            directObject: .item("apple"),
            rawInput: "taste apple"
        )

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "That tastes about average.")
    }

    @Test("TASTE without object is rejected")
    func testTasteWithoutObject() async throws {
        let engine = await createTestEngine()

        let command = Command(
            verb: .taste,
            rawInput: "taste"
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

    @Test("TASTE validation rejects non-item objects")
    func testTasteValidationRejectsNonItems() async throws {
        let engine = await createTestEngine()

        let command = Command(
            verb: .taste,
            directObject: .location(.startRoom),
            rawInput: "taste room"
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

    @Test("TASTE validation succeeds for items")
    func testTasteValidationSucceedsForItems() async throws {
        let testItem = Item(
            id: "berry",
            .name("wild berry"),
            .description("A small wild berry."),
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
            verb: .taste,
            directObject: .item("berry"),
            rawInput: "taste berry"
        )
        let context = ActionContext(
            command: command,
            engine: engine,
            stateSnapshot: await engine.gameState
        )

        // Should not throw - items are valid for tasting
        try await handler.validate(context: context)
    }

    @Test("TASTE produces correct ActionResult")
    func testTasteActionResult() async throws {
        let testItem = Item(
            id: "bread",
            .name("loaf of bread"),
            .description("A fresh loaf of bread."),
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
            verb: .taste,
            directObject: .item("bread"),
            rawInput: "taste bread"
        )
        let context = ActionContext(
            command: command,
            engine: engine,
            stateSnapshot: await engine.gameState
        )
        
        // Process the command directly
        let result = try await handler.process(context: context)
        
        // Verify result
        #expect(result.message == "That tastes about average.")
        #expect(result.stateChanges.isEmpty) // TASTE should not modify state
        #expect(result.sideEffects.isEmpty) // TASTE should not have side effects
    }

    @Test("TASTE does not affect game state")
    func testTasteDoesNotAffectGameState() async throws {
        let testItem = Item(
            id: "cookie",
            .name("chocolate cookie"),
            .description("A delicious chocolate cookie."),
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
        
        // Capture initial state
        let initialState = await engine.gameState
        let initialScore = initialState.player.score
        let initialMoves = initialState.player.moves
        let initialLocation = initialState.player.currentLocationID
        
        let command = Command(
            verb: .taste,
            directObject: .item("cookie"),
            rawInput: "taste cookie"
        )

        // Execute TASTE
        await engine.execute(command: command)

        // Verify state hasn't changed
        let finalState = await engine.gameState
        #expect(finalState.player.score == initialScore)
        #expect(finalState.player.moves == initialMoves)
        #expect(finalState.player.currentLocationID == initialLocation)
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("TASTE works with items in different locations")
    func testTasteWorksWithItemsInDifferentLocations() async throws {
        let testItem = Item(
            id: "fruit",
            .name("exotic fruit"),
            .description("An unusual exotic fruit."),
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
            verb: .taste,
            directObject: .item("fruit"),
            rawInput: "taste fruit"
        )

        // Test tasting item in room
        await engine.execute(command: command)
        let output = await mockIO.flush()
        expectNoDifference(output, "That tastes about average.")
    }

    @Test("TASTE message is consistent across multiple calls")
    func testTasteConsistency() async throws {
        let testItem = Item(
            id: "candy",
            .name("piece of candy"),
            .description("A sweet piece of candy."),
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
            verb: .taste,
            directObject: .item("candy"),
            rawInput: "taste candy"
        )

        // Execute TASTE multiple times
        await engine.execute(command: command)
        let firstOutput = await mockIO.flush()
        
        await engine.execute(command: command)
        let secondOutput = await mockIO.flush()
        
        await engine.execute(command: command)
        let thirdOutput = await mockIO.flush()

        // All outputs should be identical
        expectNoDifference(firstOutput, "That tastes about average.")
        expectNoDifference(secondOutput, "That tastes about average.")
        expectNoDifference(thirdOutput, "That tastes about average.")
    }

    @Test("TASTE with carried item works")
    func testTasteWithCarriedItem() async throws {
        let testItem = Item(
            id: "medicine",
            .name("bottle of medicine"),
            .description("A small bottle of bitter medicine."),
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
            verb: .taste,
            directObject: .item("medicine"),
            rawInput: "taste medicine"
        )

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "That tastes about average.")
    }

    @Test("TASTE works in dark room")
    func testTasteWorksInDarkRoom() async throws {
        let darkLocation = Location(
            id: "dark_pantry",
            .name("Dark Pantry"),
            .description("A completely dark pantry.")
            // No .inherentlyLit, so it should be dark
        )
        
        let testItem = Item(
            id: "spice",
            .name("mysterious spice"),
            .description("A jar of mysterious spice."),
            .isTakable,
            .in(.player)
        )
        
        let player = Player(in: "dark_pantry")
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
            verb: .taste,
            directObject: .item("spice"),
            rawInput: "taste spice"
        )

        // Act: TASTE should work even in dark rooms (taste doesn't require sight)
        await engine.execute(command: command)

        // Assert Output - should still work
        let output = await mockIO.flush()
        expectNoDifference(output, "That tastes about average.")
    }

    @Test("TASTE full workflow integration test")
    func testTasteFullWorkflow() async throws {
        let testItem = Item(
            id: "honey",
            .name("jar of honey"),
            .description("A jar of golden honey."),
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
            verb: .taste,
            directObject: .item("honey"),
            rawInput: "taste honey"
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
        #expect(result.message == "That tastes about average.")
        #expect(result.stateChanges.isEmpty)
        #expect(result.sideEffects.isEmpty)
    }

    @Test("TASTE works with different item types")
    func testTasteWorksWithDifferentItemTypes() async throws {
        let liquidItem = Item(
            id: "water",
            .name("glass of water"),
            .description("A clear glass of water."),
            .isTakable,
            .in(.player)
        )
        
        let solidItem = Item(
            id: "rock",
            .name("smooth rock"),
            .description("A smooth stone rock."),
            .isTakable,
            .in(.player)
        )
        
        let game = MinimalGame(items: [liquidItem, solidItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        // Test tasting liquid
        let waterCommand = Command(
            verb: .taste,
            directObject: .item("water"),
            rawInput: "taste water"
        )
        await engine.execute(command: waterCommand)
        let waterOutput = await mockIO.flush()
        expectNoDifference(waterOutput, "That tastes about average.")

        // Test tasting solid
        let rockCommand = Command(
            verb: .taste,
            directObject: .item("rock"),
            rawInput: "taste rock"
        )
        await engine.execute(command: rockCommand)
        let rockOutput = await mockIO.flush()
        expectNoDifference(rockOutput, "That tastes about average.")
    }
} 