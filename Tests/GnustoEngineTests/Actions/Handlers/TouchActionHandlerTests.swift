import Testing
import CustomDump
@testable import GnustoEngine

@Suite("TouchActionHandler Tests")
struct TouchActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("TOUCH DIRECTOBJECT syntax works")
    func testTouchDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let vase = Item(
            id: "vase",
            .name("ceramic vase"),
            .description("A delicate ceramic vase."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: vase
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("touch vase")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > touch vase
            You feel nothing special.
            """)

        let finalState = try await engine.item("vase")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("FEEL syntax works")
    func testFeelSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let fabric = Item(
            id: "fabric",
            .name("silk fabric"),
            .description("A piece of smooth silk fabric."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: fabric
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("feel fabric")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > feel fabric
            You feel nothing special.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot touch without specifying target")
    func testCannotTouchWithoutTarget() async throws {
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
        try await engine.execute("touch")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > touch
            Touch what?
            """)
    }

    @Test("Cannot touch target not in scope")
    func testCannotTouchTargetNotInScope() async throws {
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

        let remoteObject = Item(
            id: "remoteObject",
            .name("remote object"),
            .description("An object in another room."),
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteObject
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("touch object")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > touch object
            You can’t see any such thing.
            """)
    }

    @Test("Requires light to touch")
    func testRequiresLight() async throws {
        // Given: Dark room with an object to touch
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let statue = Item(
            id: "statue",
            .name("marble statue"),
            .description("A cold marble statue."),
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: statue
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("touch statue")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > touch statue
            It is pitch black. You can’t see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Touch object in room")
    func testTouchObjectInRoom() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
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
        try await engine.execute("touch table")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > touch table
            You feel nothing special.
            """)

        let finalState = try await engine.item("table")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Touch held item")
    func testTouchHeldItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .description("A shiny gold coin."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: coin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("touch coin")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > touch coin
            You feel nothing special.
            """)

        let finalState = try await engine.item("coin")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Touch object in open container")
    func testTouchObjectInOpenContainer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A wooden storage box."),
            .isContainer,
            .isOpenable,
            .isOpen,
            .in(.location("testRoom"))
        )

        let gem = Item(
            id: "gem",
            .name("sparkling gem"),
            .description("A beautiful gem."),
            .in(.item("box"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box, gem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("touch gem")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > touch gem
            You feel nothing special.
            """)

        let finalState = try await engine.item("gem")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Touching sets isTouched flag")
    func testTouchingSetsTouchedFlag() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let crystal = Item(
            id: "crystal",
            .name("blue crystal"),
            .description("A mysterious blue crystal."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: crystal
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Verify initial state
        let initialState = try await engine.item("crystal")
        #expect(initialState.hasFlag(.isTouched) == false)

        // When
        try await engine.execute("touch crystal")

        // Then
        let finalState = try await engine.item("crystal")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Touch multiple objects in sequence")
    func testTouchMultipleObjects() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let wall = Item(
            id: "wall",
            .name("stone wall"),
            .description("A rough stone wall."),
            .in(.location("testRoom"))
        )

        let door = Item(
            id: "door",
            .name("oak door"),
            .description("A heavy oak door."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: wall, door
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("touch wall")
        try await engine.execute("feel door")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > touch wall
            You feel nothing special.
            > feel door
            You feel nothing special.
            """)

        let wallState = try await engine.item("wall")
        let doorState = try await engine.item("door")
        #expect(wallState.hasFlag(.isTouched) == true)
        #expect(doorState.hasFlag(.isTouched) == true)
    }

    @Test("Touch already touched object still responds")
    func testTouchAlreadyTouchedObject() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let orb = Item(
            id: "orb",
            .name("glowing orb"),
            .description("A mysterious glowing orb."),
            .isTouched, // Already touched
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: orb
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("touch orb")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > touch orb
            You feel nothing special.
            """)

        let finalState = try await engine.item("orb")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = TouchActionHandler()
        // TouchActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = TouchActionHandler()
        #expect(handler.verbs.contains(.touch))
        #expect(handler.verbs.contains(.feel))
        #expect(handler.verbs.count == 2)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = TouchActionHandler()
        #expect(handler.requiresLight == true)
    }
}
