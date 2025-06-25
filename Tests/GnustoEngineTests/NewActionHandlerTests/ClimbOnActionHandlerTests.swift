import CustomDump
import Testing

@testable import GnustoEngine

@Suite("ClimbOnActionHandler Tests")
struct ClimbOnActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("CLIMB ON DIRECTOBJECT syntax works")
    func testClimbOnDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let table = Item(
            id: "table",
            .name("wooden table"),
            .description("A sturdy wooden table."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: table
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("climb on table")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > climb on table
            You can't climb on the wooden table.
            """)

        let finalState = try await engine.item("table")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("GET ON DIRECTOBJECT syntax works")
    func testGetOnDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let chair = Item(
            id: "chair",
            .name("comfortable chair"),
            .description("A comfortable chair."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: chair
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("get on chair")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > get on chair
            You can't climb on the comfortable chair.
            """)
    }

    @Test("SIT ON DIRECTOBJECT syntax works")
    func testSitOnDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let bench = Item(
            id: "bench",
            .name("stone bench"),
            .description("A cold stone bench."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: bench
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("sit on bench")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > sit on bench
            You can't climb on the stone bench.
            """)
    }

    @Test("MOUNT DIRECTOBJECT syntax works")
    func testMountDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let horse = Item(
            id: "horse",
            .name("white horse"),
            .description("A beautiful white horse."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: horse
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("mount horse")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > mount horse
            You can't climb on the white horse.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot climb on without specifying target")
    func testCannotClimbOnWithoutTarget() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("climb on")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > climb on
            Climb on what?
            """)
    }

    @Test("Cannot climb on target not in scope")
    func testCannotClimbOnTargetNotInScope() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let remoteTable = Item(
            id: "remoteTable",
            .name("remote table"),
            .description("A table in another room."),
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteTable
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("climb on table")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > climb on table
            You can't see any such thing.
            """)
    }

    @Test("Requires light to climb on")
    func testRequiresLight() async throws {
        // Given: Dark room with item
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let table = Item(
            id: "table",
            .name("wooden table"),
            .description("A sturdy wooden table."),
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: table
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("climb on table")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > climb on table
            It is pitch black. You can't see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Climb on item sets touched flag")
    func testClimbOnItemSetsTouchedFlag() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let stool = Item(
            id: "stool",
            .name("wooden stool"),
            .description("A simple wooden stool."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: stool
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("climb on stool")

        // Then: Verify state change
        let finalState = try await engine.item("stool")
        #expect(finalState.hasFlag(.isTouched) == true)

        // Verify message
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > climb on stool
            You can't climb on the wooden stool.
            """)
    }

    @Test("Climb on different items gives appropriate messages")
    func testClimbOnDifferentItems() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rock = Item(
            id: "rock",
            .name("large rock"),
            .description("A large boulder."),
            .in(.location("testRoom"))
        )

        let tree = Item(
            id: "tree",
            .name("tall tree"),
            .description("A tall oak tree."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rock, tree
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Climb on rock
        try await engine.execute("climb on rock")

        // Then
        let output1 = await mockIO.flush()
        expectNoDifference(
            output1,
            """
            > climb on rock
            You can't climb on the large rock.
            """)

        // When: Climb on tree
        try await engine.execute("sit on tree")

        // Then
        let output2 = await mockIO.flush()
        expectNoDifference(
            output2,
            """
            > sit on tree
            You can't climb on the tall tree.
            """)
    }

    @Test("Climb on item held by player")
    func testClimbOnItemHeldByPlayer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let box = Item(
            id: "box",
            .name("small box"),
            .description("A small wooden box."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("climb on box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > climb on box
            You can't climb on the small box.
            """)

        let finalState = try await engine.item("box")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = ClimbOnActionHandler()
        // ClimbOnActionHandler doesn't specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = ClimbOnActionHandler()
        #expect(handler.verbs.contains(.climb))
        #expect(handler.verbs.contains(.get))
        #expect(handler.verbs.contains(.sit))
        #expect(handler.verbs.contains(.mount))
        #expect(handler.verbs.count == 4)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = ClimbOnActionHandler()
        #expect(handler.requiresLight == true)
    }
}
