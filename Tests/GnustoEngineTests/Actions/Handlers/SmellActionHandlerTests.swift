import CustomDump
import Testing

@testable import GnustoEngine

@Suite("SmellActionHandler Tests")
struct SmellActionHandlerTests {
    let handler = SmellActionHandler()

    // MARK: - Basic Functionality Tests

    @Test("SMELL without object produces expected message")
    func testSmellWithoutObject() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act: Use engine.execute for full pipeline
        try await engine.execute("smell")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > smell
            You smell nothing unusual.
            """)
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

        let game = MinimalGame(items: testItem)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act: Use engine.execute for full pipeline
        try await engine.execute("smell apple")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > smell apple
            That smells about average.
            """)
    }

    @Test("SMELL validation rejects non-item objects")
    func testSmellValidationRejectsNonItems() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("smell room")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > smell room
            You can only smell specific items.
            """)
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

        let game = MinimalGame(items: testItem)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("smell flower")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > smell flower
            That smells about average.
            """)
    }

    @Test("SMELL validation succeeds with no direct object")
    func testSmellValidationSucceedsWithoutObject() async throws {
        let (engine, _) = await GameEngine.test()

        let command = Command(
            verb: .smell,
            rawInput: "smell"
        )
        let context = ActionContext(
            command: command,
            engine: engine
        )

        // Should not throw - smelling the environment is valid
        try await handler.validate(context: context)
    }

    @Test("SMELL produces correct ActionResult for environment")
    func testSmellEnvironmentActionResult() async throws {
        let (engine, _) = await GameEngine.test()

        let command = Command(
            verb: .smell,
            rawInput: "smell"
        )
        let context = ActionContext(
            command: command,
            engine: engine
        )

        // Process the command directly
        let result = try await handler.process(context: context)

        // Verify result
        #expect(result.message == "You smell nothing unusual.")
        #expect(result.changes.isEmpty)  // SMELL should not modify state
        #expect(result.effects.isEmpty)  // SMELL should not have side effects
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

        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)

        let command = Command(
            verb: .smell,
            directObject: .item("cheese"),
            rawInput: "smell cheese"
        )
        let context = ActionContext(
            command: command,
            engine: engine
        )

        // Process the command directly
        let result = try await handler.process(context: context)

        // Verify result
        #expect(result.message == "That smells about average.")
        #expect(result.changes.isEmpty)  // SMELL should not modify state
        #expect(result.effects.isEmpty)  // SMELL should not have side effects
    }

    @Test("SMELL does not affect game state")
    func testSmellDoesNotAffectGameState() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Capture initial state
        let initialState = await engine.gameState
        let initialScore = initialState.player.score
        let initialMoves = initialState.player.moves
        let initialLocation = initialState.player.currentLocationID

        // Execute SMELL
        try await engine.execute("smell")

        // Verify state hasn’t changed significantly (moves will increment)
        let finalState = await engine.gameState
        #expect(finalState.player.score == initialScore)
        #expect(finalState.player.currentLocationID == initialLocation)

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > smell
            You smell nothing unusual.
            """)
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

        let game = MinimalGame(locations: location1, location2)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Test in first location
        try await engine.execute("smell")
        let output1 = await mockIO.flush()
        expectNoDifference(output1, "> smell\n\nYou smell nothing unusual.")

        // Move to second location
        let moveChange = StateChange(
            entityID: .player,
            attribute: .playerLocation,
            newValue: .parentEntity(.location("kitchen"))
        )
        try await engine.apply(moveChange)

        // Test in second location - should give same generic response
        try await engine.execute("smell")
        let output2 = await mockIO.flush()
        expectNoDifference(output2, "> smell\n\nYou smell nothing unusual.")
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

        let game = MinimalGame(items: testItem)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Test smelling item in room
        try await engine.execute("smell perfume")
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > smell perfume
            That smells about average.
            """)
    }

    @Test("SMELL message is consistent across multiple calls")
    func testSmellConsistency() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Execute SMELL multiple times
        try await engine.execute("smell")
        let firstOutput = await mockIO.flush()

        try await engine.execute("smell")
        let secondOutput = await mockIO.flush()

        try await engine.execute("smell")
        let thirdOutput = await mockIO.flush()

        // All outputs should be identical
        expectNoDifference(firstOutput, """
            > smell
            You smell nothing unusual.
            """)
        expectNoDifference(secondOutput, """
            > smell
            You smell nothing unusual.
            """)
        expectNoDifference(thirdOutput, """
            > smell
            You smell nothing unusual.
            """)
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

        let game = MinimalGame(items: testItem)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act: Use engine.execute for full pipeline
        try await engine.execute("smell soap")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > smell soap
            That smells about average.
            """)
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
            locations: darkLocation
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act: SMELL should work even in dark rooms (smell doesn’t require sight)
        try await engine.execute("smell")

        // Assert Output - should still work
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > smell
            You smell nothing unusual.
            """)
    }

    @Test("SMELL works with unreachable items")
    func testSmellWorksWithUnreachableItems() async throws {
        let testItem = Item(
            id: "flower",
            .name("distant flower"),
            .description("A flower far away."),
            .isTakable,
            .in(.nowhere)
        )

        let game = MinimalGame(items: testItem)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("smell flower")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > smell flower
            You can’t see any distant flower here.
            """)
    }
}
