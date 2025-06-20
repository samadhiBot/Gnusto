import CustomDump
import Testing

@testable import GnustoEngine

@Suite("TasteActionHandler Tests")
struct TasteActionHandlerTests {
    let handler = TasteActionHandler()

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

        let game = MinimalGame(items: testItem)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act: Use engine.execute for full pipeline
        try await engine.execute("taste apple")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > taste apple
            That tastes about average.
            """)
    }

    @Test("TASTE without object is rejected")
    func testTasteWithoutObject() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("taste")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > taste
            Taste what?
            """)
    }

    @Test("TASTE validation rejects non-item objects")
    func testTasteValidationRejectsNonItems() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("taste room")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > taste room
            You can only taste specific items.
            """)
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

        let game = MinimalGame(items: testItem)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("taste berry")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > taste berry
            That tastes about average.
            """)
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

        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)

        let command = Command(
            verb: .taste,
            directObject: .item("bread"),
            rawInput: "taste bread"
        )
        let context = ActionContext(
            command: command,
            engine: engine
        )

        // Process the command directly
        let result = try await handler.process(context: context)

        // Verify result
        #expect(result.message == "That tastes about average.")
        #expect(result.changes.isEmpty)  // TASTE should not modify state
        #expect(result.effects.isEmpty)  // TASTE should not have side effects
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

        let game = MinimalGame(items: testItem)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Capture initial state
        let initialState = await engine.gameState
        let initialScore = initialState.player.score
        let initialLocation = initialState.player.currentLocationID

        // Execute TASTE
        try await engine.execute("taste cookie")

        // Verify state hasn't changed significantly (moves will increment)
        let finalState = await engine.gameState
        #expect(finalState.player.score == initialScore)
        #expect(finalState.player.currentLocationID == initialLocation)

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > taste cookie
            That tastes about average.
            """)
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

        let game = MinimalGame(items: testItem)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Test tasting item in room
        try await engine.execute("taste fruit")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > taste fruit
            That tastes about average.
            """)
    }

    @Test("TASTE with unreachable item")
    func testTasteWithUnreachableItem() async throws {
        let testItem = Item(
            id: "fruit",
            .name("distant fruit"),
            .description("A fruit far away."),
            .isTakable,
            .in(.nowhere)
        )

        let game = MinimalGame(items: testItem)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("taste fruit")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > taste fruit
            You can't see any distant fruit here.
            """)
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

        let game = MinimalGame(items: testItem)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Execute TASTE multiple times
        try await engine.execute("taste candy")
        let firstOutput = await mockIO.flush()

        try await engine.execute("taste candy")
        let secondOutput = await mockIO.flush()

        try await engine.execute("taste candy")
        let thirdOutput = await mockIO.flush()

        // All outputs should be identical
        expectNoDifference(firstOutput, "> taste candy\n\nThat tastes about average.")
        expectNoDifference(secondOutput, "> taste candy\n\nThat tastes about average.")
        expectNoDifference(thirdOutput, "> taste candy\n\nThat tastes about average.")
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

        let game = MinimalGame(items: testItem)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act: Use engine.execute for full pipeline
        try await engine.execute("taste medicine")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > taste medicine
            That tastes about average.
            """)
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
            locations: darkLocation,
            items: testItem
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act: TASTE should work even in dark rooms (taste doesn't require sight)
        try await engine.execute("taste spice")

        // Assert Output - should still work
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > taste spice
            That tastes about average.
            """)
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

        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)

        let command = Command(
            verb: .taste,
            directObject: .item("honey"),
            rawInput: "taste honey"
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
        #expect(result.message == "That tastes about average.")
        #expect(result.changes.isEmpty)
        #expect(result.effects.isEmpty)
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

        let game = MinimalGame(items: liquidItem, solidItem)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Test tasting liquid
        try await engine.execute("taste water")
        let waterOutput = await mockIO.flush()
        expectNoDifference(waterOutput, "> taste water\n\nThat tastes about average.")

        // Test tasting solid
        try await engine.execute("taste rock")
        let rockOutput = await mockIO.flush()
        expectNoDifference(rockOutput, "> taste rock\n\nThat tastes about average.")
    }
}
