import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("KnockActionHandler Tests")
struct KnockActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("KNOCK syntax works")
    func testKnockSyntax() async throws {
        // Given
        let door = Item(
            id: "door",
            .name("wooden door"),
            .description("A sturdy wooden door."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: door
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("knock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > knock
            Knock what?
            """
        )
    }

    @Test("TAP DIRECTOBJECT syntax works")
    func testTapDirectObjectSyntax() async throws {
        // Given
        let table = Item(
            id: "table",
            .name("wooden table"),
            .description("A wooden table."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: table
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tap table")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tap table
            With practiced efficiency, you tap the wooden table.
            """
        )

        let finalState = await engine.item("table")
        #expect(await finalState.hasFlag(.isTouched))
    }

    @Test("KNOCK ON DIRECTOBJECT syntax works")
    func testKnockOnDirectObjectSyntax() async throws {
        // Given
        let door = Item(
            id: "door",
            .name("front door"),
            .description("The front door."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: door
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("knock on door")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > knock on door
            With practiced efficiency, you knock on the front door.
            """
        )
    }

    @Test("RAP syntax works")
    func testRapSyntax() async throws {
        // Given
        let window = Item(
            id: "window",
            .name("glass window"),
            .description("A glass window."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: window
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("rap on window")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > rap on window
            With practiced efficiency, you rap on the glass window.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot knock without specifying target for KNOCK ON")
    func testCannotKnockWithoutTargetForKnockOn() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("knock on")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > knock on
            Knock on what?
            """
        )
    }

    @Test("Cannot knock on target not in scope")
    func testCannotKnockOnTargetNotInScope() async throws {
        // Given
        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let remoteDoor = Item(
            id: "remoteDoor",
            .name("distant door"),
            .description("A door in another room."),
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteDoor
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("knock on door")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > knock on door
            Any such thing remains frustratingly inaccessible.
            """
        )
    }

    @Test("Requires light to knock")
    func testRequiresLight() async throws {
        // Given: Dark room with door
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let door = Item(
            id: "door",
            .name("mysterious door"),
            .description("A mysterious door."),
            .in("darkRoom")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: door
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("knock on door")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > knock on door
            You stand in a depthless black where even your thoughts seem to
            whisper, careful not to make a sound.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Knock on empty container")
    func testKnockOnEmptyContainer() async throws {
        // Given
        let chest = Item(
            id: "chest",
            .name("treasure chest"),
            .description("A treasure chest."),
            .isContainer,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: chest
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("knock on chest")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > knock on chest
            With practiced efficiency, you knock on the treasure chest.
            """
        )

        let finalState = await engine.item("chest")
        #expect(await finalState.hasFlag(.isTouched))
    }

    @Test("Knock on generic object")
    func testKnockOnGenericObject() async throws {
        // Given
        let wall = Item(
            id: "wall",
            .name("stone wall"),
            .description("A stone wall."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: wall
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("knock on wall")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > knock on wall
            With practiced efficiency, you knock on the stone wall.
            """
        )
    }

    @Test("Knock sets touched flag on target")
    func testKnockSetsTouchedFlagOnTarget() async throws {
        // Given
        let post = Item(
            id: "post",
            .name("wooden post"),
            .description("A wooden post."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: post
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tap post")

        // Then: Verify state changes
        let finalState = await engine.item("post")
        #expect(await finalState.hasFlag(.isTouched))

        // Verify message
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tap post
            With practiced efficiency, you tap the wooden post.
            """
        )
    }

    @Test("Knock on multiple different objects")
    func testKnockOnMultipleDifferentObjects() async throws {
        // Given
        let door = Item(
            id: "door",
            .name("blue door"),
            .description("A blue door."),
            .in(.startRoom)
        )

        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A wooden box."),
            .isContainer,
            .in(.startRoom)
        )

        let barrel = Item(
            id: "barrel",
            .name("oak barrel"),
            .description("An oak barrel."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: door, box, barrel
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Knock on door
        try await engine.execute(
            "knock on door",
            "rap on box",
            "tap barrel"
        )

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > knock on door
            With practiced efficiency, you knock on the blue door.

            > rap on box
            You rap on the wooden box.

            > tap barrel
            You successfully tap the oak barrel.
            """
        )

        // Verify all items were touched
        let doorState = await engine.item("door")
        let boxState = await engine.item("box")
        let barrelState = await engine.item("barrel")
        #expect(await doorState.hasFlag(.isTouched))
        #expect(await boxState.hasFlag(.isTouched))
        #expect(await barrelState.hasFlag(.isTouched))
    }

    @Test("Knock using different verb synonyms")
    func testKnockUsingDifferentVerbSynonyms() async throws {
        // Given
        let door1 = Item(
            id: "door1",
            .name("red door"),
            .description("A red door."),
            .in(.startRoom)
        )

        let door2 = Item(
            id: "door2",
            .name("green door"),
            .description("A green door."),
            .in(.startRoom)
        )

        let door3 = Item(
            id: "door3",
            .name("yellow door"),
            .description("A yellow door."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: door1, door2, door3
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Use "knock"
        try await engine.execute(
            "knock on red door",
            "rap on green door",
            "tap yellow door"
        )

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > knock on red door
            With practiced efficiency, you knock on the red door.

            > rap on green door
            You rap on the green door.

            > tap yellow door
            You successfully tap the yellow door.
            """
        )
    }

    @Test("Knock on doors with different states")
    func testKnockOnDoorsWithDifferentStates() async throws {
        // Given
        // Set up the test state with doors in different states
        let openDoor = Item(
            id: "openDoor",
            .name("open door"),
            .description("An open door."),
            .isOpen,
            .in(.startRoom)
        )

        let closedDoor = Item(
            id: "closedDoor",
            .name("closed door"),
            .description("A closed door."),
            .in(.startRoom)
        )

        let lockedDoor = Item(
            id: "lockedDoor",
            .name("locked door"),
            .description("A locked door."),
            .isLocked,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: openDoor, closedDoor, lockedDoor
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Knock on doors with different states
        try await engine.execute(
            "knock on the open door",
            "tap on the closed door",
            "rap on the locked door"
        )

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > knock on the open door
            With practiced efficiency, you knock on the open door.

            > tap on the closed door
            You tap on the closed door.

            > rap on the locked door
            You successfully rap on the locked door.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = KnockActionHandler()
        #expect(handler.synonyms.contains(.knock))
        #expect(handler.synonyms.contains(.rap))
        #expect(handler.synonyms.contains(.tap))
        #expect(handler.synonyms.count == 3)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = KnockActionHandler()
        #expect(handler.requiresLight == true)
    }
}
