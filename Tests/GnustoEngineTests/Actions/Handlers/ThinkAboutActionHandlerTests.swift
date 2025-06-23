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
            Yes, yes, you’re very important.
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
            You contemplate the mysterious puzzle for a bit, but nothing
            fruitful comes to mind.
            """)
    }

    @Test("THINK ABOUT with location is rejected")
    func testThinkAboutWithLocation() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("think about the void")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > think about the void
            The more you think, the more it remains stubbornly locational.
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
            You can’t see any such thing.
            """)
    }

    @Test("THINK ABOUT produces correct ActionResult for player")
    func testThinkAboutPlayerActionResult() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act:
        try await engine.execute("think about self")

        // Assert:
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > think about self
            Yes, yes, you’re very important.
            """)
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

        let game = MinimalGame(items: testItem)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act:
        try await engine.execute("think about the mirror")

        // Assert:
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > think about the mirror
            You contemplate the ornate mirror for a bit, but nothing
            fruitful comes to mind.
            """)
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

        // Verify core state hasn’t changed
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

        // Act: THINK ABOUT should work even in dark rooms (thinking doesn’t require sight)
        try await engine.execute("think about coin")

        // Assert Output - should still work
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > think about coin
            You contemplate the silver coin for a bit, but nothing fruitful
            comes to mind.
            """)
    }

    @Test("THINK ABOUT rejects unreachable items")
    func testThinkAboutRejectsUnreachableItems() async throws {
        let unreachableItem = Item(
            id: "distant_star",
            .name("distant star"),
            .description("A star far away in the sky."),
            .in(.nowhere)
        )

        let game = MinimalGame(items: unreachableItem)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act:
        try await engine.execute("think about star")

        // Assert:
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > think about star
            You can’t see any such thing.
            """)
    }
}
