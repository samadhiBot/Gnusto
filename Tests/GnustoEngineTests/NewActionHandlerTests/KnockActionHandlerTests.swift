import CustomDump
import Testing

@testable import GnustoEngine

@Suite("KnockActionHandler Tests")
struct KnockActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("KNOCK syntax works")
    func testKnockSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let door = Item(
            id: "door",
            .name("wooden door"),
            .description("A sturdy wooden door."),
            .isDoor,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            Knock on what?
            """)
    }

    @Test("TAP DIRECTOBJECT syntax works")
    func testTapDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let table = Item(
            id: "table",
            .name("wooden table"),
            .description("A wooden table."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            You hear a hollow sound from the wooden table.
            """)

        let finalState = try await engine.item("table")
        #expect(finalState.hasFlag(.isTouched))
    }

    @Test("KNOCK ON DIRECTOBJECT syntax works")
    func testKnockOnDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let door = Item(
            id: "door",
            .name("front door"),
            .description("The front door."),
            .isDoor,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            You knock on the front door. No answer.
            """)
    }

    @Test("RAP syntax works")
    func testRapSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let window = Item(
            id: "window",
            .name("glass window"),
            .description("A glass window."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            You hear a hollow sound from the glass window.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot knock without specifying target for KNOCK ON")
    func testCannotKnockWithoutTargetForKnockOn() async throws {
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
        try await engine.execute("knock on")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > knock on
            Knock on what?
            """)
    }

    @Test("Cannot knock on target not in scope")
    func testCannotKnockOnTargetNotInScope() async throws {
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

        let remoteDoor = Item(
            id: "remoteDoor",
            .name("distant door"),
            .description("A door in another room."),
            .isDoor,
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
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
            You can't see any such thing.
            """)
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
            .isDoor,
            .in(.location("darkRoom"))
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
            It is pitch black. You can't see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Knock on open door")
    func testKnockOnOpenDoor() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let door = Item(
            id: "door",
            .name("oak door"),
            .description("An oak door."),
            .isDoor,
            .isOpen,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            The oak door is open; there's no need to knock.
            """)

        let finalState = try await engine.item("door")
        #expect(finalState.hasFlag(.isTouched))
    }

    @Test("Knock on closed door")
    func testKnockOnClosedDoor() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let door = Item(
            id: "door",
            .name("heavy door"),
            .description("A heavy door."),
            .isDoor,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            You knock on the heavy door. No answer.
            """)
    }

    @Test("Knock on locked door")
    func testKnockOnLockedDoor() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let door = Item(
            id: "door",
            .name("locked door"),
            .description("A locked door."),
            .isDoor,
            .isLocked,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            You knock on the locked door. No answer.
            """)
    }

    @Test("Knock on container")
    func testKnockOnContainer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let chest = Item(
            id: "chest",
            .name("treasure chest"),
            .description("A treasure chest."),
            .isContainer,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            You rap on the treasure chest.
            """)

        let finalState = try await engine.item("chest")
        #expect(finalState.hasFlag(.isTouched))
    }

    @Test("Knock on generic object")
    func testKnockOnGenericObject() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let wall = Item(
            id: "wall",
            .name("stone wall"),
            .description("A stone wall."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            You hear a hollow sound from the stone wall.
            """)
    }

    @Test("Knock sets touched flag on target")
    func testKnockSetsTouchedFlagOnTarget() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let post = Item(
            id: "post",
            .name("wooden post"),
            .description("A wooden post."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: post
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tap post")

        // Then: Verify state changes
        let finalState = try await engine.item("post")
        #expect(finalState.hasFlag(.isTouched))

        // Verify message
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tap post
            You hear a hollow sound from the wooden post.
            """)
    }

    @Test("Knock on multiple different objects")
    func testKnockOnMultipleDifferentObjects() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let door = Item(
            id: "door",
            .name("blue door"),
            .description("A blue door."),
            .isDoor,
            .in(.location("testRoom"))
        )

        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A wooden box."),
            .isContainer,
            .in(.location("testRoom"))
        )

        let barrel = Item(
            id: "barrel",
            .name("oak barrel"),
            .description("An oak barrel."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: door, box, barrel
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Knock on door
        try await engine.execute("knock on door")

        // Then
        let output1 = await mockIO.flush()
        expectNoDifference(
            output1,
            """
            > knock on door
            You knock on the blue door. No answer.
            """)

        // When: Knock on container
        try await engine.execute("rap on box")

        // Then
        let output2 = await mockIO.flush()
        expectNoDifference(
            output2,
            """
            > rap on box
            You rap on the wooden box.
            """)

        // When: Knock on generic object
        try await engine.execute("tap barrel")

        // Then
        let output3 = await mockIO.flush()
        expectNoDifference(
            output3,
            """
            > tap barrel
            You hear a hollow sound from the oak barrel.
            """)

        // Verify all items were touched
        let doorState = try await engine.item("door")
        let boxState = try await engine.item("box")
        let barrelState = try await engine.item("barrel")
        #expect(doorState.hasFlag(.isTouched))
        #expect(boxState.hasFlag(.isTouched))
        #expect(barrelState.hasFlag(.isTouched))
    }

    @Test("Knock using different verb synonyms")
    func testKnockUsingDifferentVerbSynonyms() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let door1 = Item(
            id: "door1",
            .name("red door"),
            .description("A red door."),
            .isDoor,
            .in(.location("testRoom"))
        )

        let door2 = Item(
            id: "door2",
            .name("green door"),
            .description("A green door."),
            .isDoor,
            .in(.location("testRoom"))
        )

        let door3 = Item(
            id: "door3",
            .name("yellow door"),
            .description("A yellow door."),
            .isDoor,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: door1, door2, door3
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Use "knock"
        try await engine.execute("knock on red door")

        // Then
        let output1 = await mockIO.flush()
        expectNoDifference(
            output1,
            """
            > knock on red door
            You knock on the red door. No answer.
            """)

        // When: Use "rap"
        try await engine.execute("rap on green door")

        // Then
        let output2 = await mockIO.flush()
        expectNoDifference(
            output2,
            """
            > rap on green door
            You knock on the green door. No answer.
            """)

        // When: Use "tap"
        try await engine.execute("tap yellow door")

        // Then
        let output3 = await mockIO.flush()
        expectNoDifference(
            output3,
            """
            > tap yellow door
            You knock on the yellow door. No answer.
            """)
    }

    @Test("Knock on doors with different states")
    func testKnockOnDoorsWithDifferentStates() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        // Set up the test state with doors in different states
        let openDoor = Item(
            id: "openDoor",
            .name("open door"),
            .description("An open door."),
            .isDoor,
            .isOpen,
            .in(.location("testRoom"))
        )

        let closedDoor = Item(
            id: "closedDoor",
            .name("closed door"),
            .description("A closed door."),
            .isDoor,
            .in(.location("testRoom"))
        )

        let lockedDoor = Item(
            id: "lockedDoor",
            .name("locked door"),
            .description("A locked door."),
            .isDoor,
            .isLocked,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: openDoor, closedDoor, lockedDoor
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Knock on open door
        try await engine.execute("knock on open door")

        // Then
        let output1 = await mockIO.flush()
        expectNoDifference(
            output1,
            """
            > knock on open door
            The open door is open; there's no need to knock.
            """)

        // When: Knock on closed door
        try await engine.execute("knock on closed door")

        // Then
        let output2 = await mockIO.flush()
        expectNoDifference(
            output2,
            """
            > knock on closed door
            You knock on the closed door. No answer.
            """)

        // When: Knock on locked door
        try await engine.execute("knock on locked door")

        // Then
        let output3 = await mockIO.flush()
        expectNoDifference(
            output3,
            """
            > knock on locked door
            You knock on the locked door. No answer.
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = KnockActionHandler()
        // KnockActionHandler doesn't specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = KnockActionHandler()
        #expect(handler.verbs.contains(.knock))
        #expect(handler.verbs.contains(.rap))
        #expect(handler.verbs.contains(.tap))
        #expect(handler.verbs.count == 3)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = KnockActionHandler()
        #expect(handler.requiresLight == true)
    }
}
