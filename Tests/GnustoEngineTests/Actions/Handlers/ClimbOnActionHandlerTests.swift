import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("ClimbOnActionHandler Tests")
struct ClimbOnActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("CLIMB ON DIRECTOBJECT syntax works")
    func testClimbOnDirectObjectSyntax() async throws {
        // Given
        let table = Item(
            id: "table",
            .name("wooden table"),
            .description("A sturdy wooden table."),
            .in(.startRoom)
        )

        let game = MinimalGame(
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
            The universe denies your request to climb on the wooden table.
            """
        )

        let finalState = await engine.item("table")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("GET ON DIRECTOBJECT syntax works")
    func testGetOnDirectObjectSyntax() async throws {
        // Given
        let chair = Item(
            id: "chair",
            .name("comfortable chair"),
            .description("A comfortable chair."),
            .in(.startRoom)
        )

        let game = MinimalGame(
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
            The universe denies your request to get on the comfortable
            chair.
            """
        )
    }

    @Test("SIT ON DIRECTOBJECT syntax works")
    func testSitOnDirectObjectSyntax() async throws {
        // Given
        let bench = Item(
            id: "bench",
            .name("stone bench"),
            .description("A cold stone bench."),
            .in(.startRoom)
        )

        let game = MinimalGame(
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
            The universe denies your request to sit on the stone bench.
            """
        )
    }

    @Test("MOUNT DIRECTOBJECT syntax works")
    func testMountDirectObjectSyntax() async throws {
        // Given
        let horse = Item(
            id: "horse",
            .name("white horse"),
            .description("A beautiful white horse."),
            .in(.startRoom)
        )

        let game = MinimalGame(
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
            The universe denies your request to mount the white horse.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot climb on without specifying target")
    func testCannotClimbOnWithoutTarget() async throws {
        // Given
        let game = MinimalGame()
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
            """
        )
    }

    @Test("Cannot climb on target not in scope")
    func testCannotClimbOnTargetNotInScope() async throws {
        // Given
        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let remoteTable = Item(
            id: "remoteTable",
            .name("remote table"),
            .description("A table in another room."),
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
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
            Any such thing remains frustratingly inaccessible.
            """
        )
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
            .in("darkRoom")
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
            You stand in a depthless black where even your thoughts seem to
            whisper, careful not to make a sound.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Climb on item sets touched flag")
    func testClimbOnItemSetsTouchedFlag() async throws {
        // Given
        let stool = Item(
            id: "stool",
            .name("wooden stool"),
            .description("A simple wooden stool."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: stool
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("climb on stool")

        // Then: Verify state change
        let finalState = await engine.item("stool")
        #expect(await finalState.hasFlag(.isTouched) == true)

        // Verify message
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > climb on stool
            The universe denies your request to climb on the wooden stool.
            """
        )
    }

    @Test("Climb on different items gives appropriate messages")
    func testClimbOnDifferentItems() async throws {
        // Given
        let rock = Item(
            id: "rock",
            .name("large rock"),
            .description("A large boulder."),
            .in(.startRoom)
        )

        let tree = Item(
            id: "tree",
            .name("tall tree"),
            .description("A tall oak tree."),
            .in(.startRoom)
        )

        let game = MinimalGame(
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
            The universe denies your request to climb on the large rock.
            """
        )

        // When: Climb on tree
        try await engine.execute("sit on tree")

        // Then
        let output2 = await mockIO.flush()
        expectNoDifference(
            output2,
            """
            > sit on tree
            The tall tree stubbornly resists your attempts to sit on it.
            """
        )
    }

    @Test("Climb on item held by player")
    func testClimbOnItemHeldByPlayer() async throws {
        // Given
        let box = Item(
            id: "box",
            .name("small box"),
            .description("A small wooden box."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
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
            The universe denies your request to climb on the small box.
            """
        )

        let finalState = await engine.item("box")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = ClimbOnActionHandler()
        // ClimbOnActionHandler uses specific verbs in syntax rules (.climb, .get, .sit, .mount)
        // rather than generic .verb tokens, so verbs array should be empty
        #expect(handler.synonyms.isEmpty)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = ClimbOnActionHandler()
        #expect(handler.requiresLight == true)
    }
}
