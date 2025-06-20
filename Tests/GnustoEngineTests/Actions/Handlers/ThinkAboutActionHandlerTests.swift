import CustomDump
import Testing

@testable import GnustoEngine

@Suite("ThinkAboutActionHandler Tests")
struct ThinkAboutActionHandlerTests {
    @Test("THINK ABOUT without object is rejected")
    func testThinkAboutWithoutObject() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("think about")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > think about
            Think about what?
            """)
    }

    @Test("THINK ABOUT SELF produces specific message")
    func testThinkAboutSelf() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act: Use engine.execute for full pipeline
        try await engine.execute("think about self")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > think about self
            Yes, yes, you're very important.
            """)
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

        let game = MinimalGame(items: testItem)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act: Use engine.execute for full pipeline
        try await engine.execute("think about puzzle")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > think about puzzle
            You contemplate the mysterious puzzle for a bit, but nothing fruitful comes to mind.
            """)
    }

    @Test("THINK ABOUT with location is rejected")
    func testThinkAboutWithLocation() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("think about room")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > think about room
            You can only think about yourself or specific items.
            """)
    }

    @Test("THINK ABOUT with unreachable item")
    func testThinkAboutWithUnreachableItem() async throws {
        let testItem = Item(
            id: "key",
            .name("golden key"),
            .description("A beautifully crafted golden key."),
            .isTakable,
            .in(.nowhere)
        )

        let game = MinimalGame(items: testItem)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("think about key")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > think about key
            You can't see any golden key here.
            """)
    }

    @Test("THINK ABOUT validation succeeds for player")
    func testThinkAboutValidationSucceedsForPlayer() async throws {
        let handler = ThinkAboutActionHandler()
        let (engine, _) = await GameEngine.test()

        let command = Command(
            verb: .thinkAbout,
            directObject: .player,
            rawInput: "think about self"
        )
        let context = ActionContext(
            command: command,
            engine: engine
        )

        // Should not throw - thinking about self is valid
        try await handler.validate(context: context)
    }

    @Test("THINK ABOUT validation succeeds for reachable items")
    func testThinkAboutValidationSucceedsForReachableItems() async throws {
        let handler = ThinkAboutActionHandler()
        let testItem = Item(
            id: "key",
            .name("golden key"),
            .description("A beautifully crafted golden key."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)

        let command = Command(
            verb: .thinkAbout,
            directObject: .item("key"),
            rawInput: "think about key"
        )
        let context = ActionContext(
            command: command,
            engine: engine
        )

        // Should not throw - reachable items are valid
        try await handler.validate(context: context)
    }

    @Test("THINK ABOUT produces correct ActionResult for player")
    func testThinkAboutPlayerActionResult() async throws {
        let handler = ThinkAboutActionHandler()
        let (engine, _) = await GameEngine.test()

        let command = Command(
            verb: .thinkAbout,
            directObject: .player,
            rawInput: "think about self"
        )
        let context = ActionContext(
            command: command,
            engine: engine
        )

        // Process the command directly
        let result = try await handler.process(context: context)

        // Verify result
        #expect(result.message == "Yes, yes, you're very important.")
        #expect(result.changes.isEmpty)  // THINK ABOUT SELF should not modify state
    }

    @Test("THINK ABOUT produces correct ActionResult for item")
    func testThinkAboutItemActionResult() async throws {
        let handler = ThinkAboutActionHandler()
        let testItem = Item(
            id: "mirror",
            .name("ornate mirror"),
            .description("An ornate hand mirror with intricate carvings."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)

        let command = Command(
            verb: .thinkAbout,
            directObject: .item("mirror"),
            rawInput: "think about mirror"
        )
        let context = ActionContext(
            command: command,
            engine: engine
        )

        // Process the command directly
        let result = try await handler.process(context: context)

        // Verify result
        #expect(
            result.message
                == "You contemplate the ornate mirror for a bit, but nothing fruitful comes to mind."
        )
        #expect(!result.changes.isEmpty)  // THINK ABOUT item should set isTouched and update pronouns
    }

    @Test("THINK ABOUT SELF does not modify game state")
    func testThinkAboutSelfDoesNotModifyGameState() async throws {
        let (engine, _) = await GameEngine.test()

        // Capture initial state
        let initialState = await engine.gameState
        let initialScore = initialState.player.score
        let initialMoves = initialState.player.moves
        let initialLocation = initialState.player.currentLocationID

        // Execute THINK ABOUT SELF
        try await engine.execute("think about self")

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

        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)

        // Verify item is not initially touched
        let initialItem = try await engine.item("book")
        #expect(!initialItem.hasFlag(.isTouched))

        // Execute THINK ABOUT
        try await engine.execute("think about book")

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

        let game = MinimalGame(items: testItem)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Test thinking about item in room
        try await engine.execute("think about painting")
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            "> think about painting\n\nYou contemplate the beautiful painting for a bit, but nothing fruitful comes to mind.")
    }

    @Test("THINK ABOUT message is consistent across multiple calls")
    func testThinkAboutConsistency() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Execute THINK ABOUT multiple times
        try await engine.execute("think about self")
        let firstOutput = await mockIO.flush()

        try await engine.execute("think about self")
        let secondOutput = await mockIO.flush()

        try await engine.execute("think about self")
        let thirdOutput = await mockIO.flush()

        // All outputs should be identical
        expectNoDifference(firstOutput, "> think about self\n\nYes, yes, you're very important.")
        expectNoDifference(secondOutput, "> think about self\n\nYes, yes, you're very important.")
        expectNoDifference(thirdOutput, "> think about self\n\nYes, yes, you're very important.")
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
            locations: darkLocation,
            items: testItem
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act: THINK ABOUT should work even in dark rooms (thinking doesn't require sight)
        try await engine.execute("think about coin")

        // Assert Output - should still work
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            "> think about coin\n\nYou contemplate the silver coin for a bit, but nothing fruitful comes to mind.")
    }

    @Test("THINK ABOUT full workflow integration test")
    func testThinkAboutFullWorkflow() async throws {
        let handler = ThinkAboutActionHandler()
        let testItem = Item(
            id: "crystal",
            .name("magic crystal"),
            .description("A glowing crystal with mysterious properties."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)

        let command = Command(
            verb: .thinkAbout,
            directObject: .item("crystal"),
            rawInput: "think about crystal"
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
        #expect(
            result.message
                == "You contemplate the magic crystal for a bit, but nothing fruitful comes to mind."
        )
        #expect(!result.changes.isEmpty)  // Should set touched flag and pronouns
    }

    @Test("THINK ABOUT rejects unreachable items")
    func testThinkAboutRejectsUnreachableItems() async throws {
        let handler = ThinkAboutActionHandler()
        let unreachableItem = Item(
            id: "distant_star",
            .name("distant star"),
            .description("A star far away in the sky."),
            .in(.nowhere)
        )

        let game = MinimalGame(items: unreachableItem)
        let (engine, _) = await GameEngine.test(blueprint: game)

        let command = Command(
            verb: .thinkAbout,
            directObject: .item("distant_star"),
            rawInput: "think about star"
        )
        let context = ActionContext(
            command: command,
            engine: engine
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

        let game = MinimalGame(items: testItem)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act: Should work even if item was already touched
        try await engine.execute("think about sword")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            "> think about sword\n\nYou contemplate the magic sword for a bit, but nothing fruitful comes to mind.")
    }
}
