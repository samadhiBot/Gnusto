import Testing
import CustomDump
@testable import GnustoEngine

@Suite("TurnActionHandler Tests")
struct TurnActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("TURN DIRECTOBJECT syntax works")
    func testTurnDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let dial = Item(
            id: "dial",
            .name("brass dial"),
            .description("A polished brass dial."),
            .isDial,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: dial
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn dial")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > turn dial
            The brass dial responds to your turning attempt with the
            unwavering resolve of the professionally immobile.
            """)

        let finalState = try await engine.item("dial")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("ROTATE syntax works")
    func testRotateSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let wheel = Item(
            id: "wheel",
            .name("steering wheel"),
            .description("A large steering wheel."),
            .isWheel,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: wheel
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("rotate wheel")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > rotate wheel
            The steering wheel responds to your turning attempt with the
            unwavering resolve of the professionally immobile.
            """)
    }

    @Test("TWIST syntax works")
    func testTwistSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let knob = Item(
            id: "knob",
            .name("door knob"),
            .description("A brass door knob."),
            .isKnob,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: knob
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("twist knob")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > twist knob
            The door knob responds to your turning attempt with the
            unwavering resolve of the professionally immobile.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot turn without specifying target")
    func testCannotTurnWithoutTarget() async throws {
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
        try await engine.execute("turn")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > turn
            Turn what?
            """)
    }

    @Test("Cannot turn target not in scope")
    func testCannotTurnTargetNotInScope() async throws {
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

        let remoteDial = Item(
            id: "remoteDial",
            .name("remote dial"),
            .description("A dial in another room."),
            .isDial,
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteDial
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn dial")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > turn dial
            You can’t see any such thing.
            """)
    }

    @Test("Requires light to turn")
    func testRequiresLight() async throws {
        // Given: Dark room with an object to turn
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let handle = Item(
            id: "handle",
            .name("crank handle"),
            .description("A metal crank handle."),
            .isHandle,
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: handle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn handle")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > turn handle
            It is pitch black. You can’t see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Turn dial")
    func testTurnDial() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let safeDial = Item(
            id: "safeDial",
            .name("combination dial"),
            .description("A dial for entering combinations."),
            .isDial,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: safeDial
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn dial")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > turn dial
            The dial clicks to a new position.
            """)
    }

    @Test("Turn knob")
    func testTurnKnob() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let volumeKnob = Item(
            id: "volumeKnob",
            .name("volume knob"),
            .description("A volume control knob."),
            .isKnob,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: volumeKnob
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn knob")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > turn knob
            The knob clicks to a new position.
            """)
    }

    @Test("Turn wheel")
    func testTurnWheel() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let shipWheel = Item(
            id: "shipWheel",
            .name("ship’s wheel"),
            .description("A large wooden ship’s wheel."),
            .isWheel,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: shipWheel
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn wheel")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > turn wheel
            You turn the wheel with considerable effort.
            """)
    }

    @Test("Turn handle")
    func testTurnHandle() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let crankHandle = Item(
            id: "crankHandle",
            .name("crank handle"),
            .description("A metal crank handle."),
            .isHandle,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: crankHandle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn handle")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > turn handle
            The handle turns with a grinding sound.
            """)
    }

    @Test("Turn key")
    func testTurnKey() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let key = Item(
            id: "key",
            .name("brass key"),
            .description("A small brass key."),
            .isKey,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn key")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > turn key
            You need to be more specific about what to use the key with.
            """)
    }

    @Test("Turn character")
    func testTurnCharacter() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let palaceGuard = Item(
            id: "palaceGuard",
            .name("palace guard"),
            .description("A stern-looking palace guard."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: palaceGuard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn guard")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > turn guard
            You can’t turn the palace guard.
            """)
    }

    @Test("Turn takable object")
    func testTurnTakableObject() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let cube = Item(
            id: "cube",
            .name("puzzle cube"),
            .description("A colorful puzzle cube."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: cube
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn cube")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > turn cube
            You turn the puzzle cube in your hands.
            """)
    }

    @Test("Turn fixed object")
    func testTurnFixedObject() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let statue = Item(
            id: "statue",
            .name("marble statue"),
            .description("A heavy marble statue."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: statue
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn statue")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > turn statue
            You can’t turn the marble statue.
            """)
    }

    @Test("Turning sets isTouched flag")
    func testTurningSetsTouchedFlag() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let valve = Item(
            id: "valve",
            .name("water valve"),
            .description("A metal water valve."),
            .isKnob,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: valve
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Verify initial state
        let initialState = try await engine.item("valve")
        #expect(initialState.hasFlag(.isTouched) == false)

        // When
        try await engine.execute("turn valve")

        // Then
        let finalState = try await engine.item("valve")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Turn multiple mechanisms")
    func testTurnMultipleMechanisms() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let dial1 = Item(
            id: "dial1",
            .name("first dial"),
            .description("The first dial."),
            .isDial,
            .in(.location("testRoom"))
        )

        let dial2 = Item(
            id: "dial2",
            .name("second dial"),
            .description("The second dial."),
            .isDial,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: dial1, dial2
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn first dial")
        try await engine.execute("rotate second dial")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > turn first dial
            The dial clicks to a new position.
            > rotate second dial
            The dial clicks to a new position.
            """)

        let dial1State = try await engine.item("dial1")
        let dial2State = try await engine.item("dial2")
        #expect(dial1State.hasFlag(.isTouched) == true)
        #expect(dial2State.hasFlag(.isTouched) == true)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Intents")
    func testIntents() async throws {
        let handler = TurnActionHandler()
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = TurnActionHandler()
        #expect(handler.verbs.contains(.turn))
        #expect(handler.verbs.contains(.rotate))
        #expect(handler.verbs.contains(.twist))
        #expect(handler.verbs.count == 3)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = TurnActionHandler()
        #expect(handler.requiresLight == true)
    }
}
