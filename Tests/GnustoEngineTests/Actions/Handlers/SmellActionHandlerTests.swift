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
            .name("apple"),
            .adjectives("red"),
            .description("A juicy red apple."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(items: testItem)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act: Use engine.execute for full pipeline
        try await engine.execute("smell the red apple")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > smell the red apple
            The apple smells about average.
            """)
    }

    @Test("SMELL validation rejects non-item objects")
    func testSmellValidationRejectsNonItems() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("smell the void")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > smell the void
            You smell nothing unusual.
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
            The rose smells about average.
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
        #expect(result.message == "The old cheese smells about average.")
        #expect(result.changes.isEmpty)  // SMELL should not modify state
        #expect(result.effects.isEmpty)  // SMELL should not have side effects
    }

    @Test("SMELL myself")
    func testPlayerSmellMyself() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("smell myself", times: 3)

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > smell myself
            You smell yourself with admirable commitment to personal
            quality control.

            > smell myself
            You inhale your own scent, proving your dedication to
            comprehensive self-monitoring.

            > smell myself
            You smell yourself with the determination of someone who faces
            facts head-on.
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
        expectNoDifference(output1, """
            > smell
            You smell nothing unusual.
            """)

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
        expectNoDifference(output2, """
            > smell
            You smell nothing unusual.
            """)
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
            The bottle of perfume smells about average.
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
            The bar of soap smells about average.
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
            You can’t see any such thing.
            """)
    }
}
