import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("TurnActionHandler Tests")
struct TurnActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("TURN DIRECTOBJECT syntax works")
    func testTurnDirectObjectSyntax() async throws {
        // Given
        let dial = Item(
            id: "dial",
            .name("brass dial"),
            .description("A polished brass dial."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: dial
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn dial")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn dial
            The brass dial remains fixed in its orientation, defying
            rotation.
            """
        )

        let finalState = try await engine.item("dial")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("ROTATE syntax works")
    func testRotateSyntax() async throws {
        // Given
        let wheel = Item(
            id: "wheel",
            .name("steering wheel"),
            .description("A large steering wheel."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: wheel
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("rotate wheel")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > rotate wheel
            The steering wheel remains fixed in its orientation, defying
            rotation.
            """
        )
    }

    @Test("TWIST syntax works")
    func testTwistSyntax() async throws {
        // Given
        let knob = Item(
            id: "knob",
            .name("door knob"),
            .description("A brass door knob."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: knob
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("twist knob")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > twist knob
            The door knob remains fixed in its orientation, defying
            rotation.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot turn without specifying target")
    func testCannotTurnWithoutTarget() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn
            Turn what?
            """
        )
    }

    @Test("Cannot turn target not in scope")
    func testCannotTurnTargetNotInScope() async throws {
        // Given
        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let remoteDial = Item(
            id: "remoteDial",
            .name("remote dial"),
            .description("A dial in another room."),
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteDial
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn dial")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn dial
            Any such thing lurks beyond your reach.
            """
        )
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
            .in("darkRoom")
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
        expectNoDifference(
            output,
            """
            > turn handle
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Turn character")
    func testTurnCharacter() async throws {
        // Given
        let palaceGuard = Item(
            id: "palaceGuard",
            .name("palace guard"),
            .description("A stern-looking palace guard."),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: palaceGuard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn guard")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn guard
            The palace guard is not a crank to be turned at your whim.
            """
        )
    }

    @Test("Turn takable object")
    func testTurnTakableObject() async throws {
        // Given
        let cube = Item(
            id: "cube",
            .name("puzzle cube"),
            .description("A colorful puzzle cube."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: cube
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn cube")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn cube
            You rotate the puzzle cube experimentally. Nothing of
            consequence occurs.
            """
        )
    }

    @Test("Turn fixed object")
    func testTurnFixedObject() async throws {
        // Given
        let statue = Item(
            id: "statue",
            .name("marble statue"),
            .description("A heavy marble statue."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: statue
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn statue")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn statue
            The marble statue remains fixed in its orientation, defying
            rotation.
            """
        )
    }

    @Test("Turn location")
    func testTurnLocation() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn Test Room")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn Test Room
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Turning sets isTouched flag")
    func testTurningSetsTouchedFlag() async throws {
        // Given
        let valve = Item(
            id: "valve",
            .name("water valve"),
            .description("A metal water valve."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: valve
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // Verify initial state
        let initialState = try await engine.item("valve")
        #expect(await initialState.hasFlag(.isTouched) == false)

        // When
        try await engine.execute("turn valve")

        // Then
        let finalState = try await engine.item("valve")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Turn multiple mechanisms")
    func testTurnMultipleMechanisms() async throws {
        // Given
        let dial1 = Item(
            id: "dial1",
            .name("first dial"),
            .description("The first dial."),
            .in(.startRoom)
        )

        let dial2 = Item(
            id: "dial2",
            .name("second dial"),
            .description("The second dial."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: dial1, dial2
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn first dial")
        try await engine.execute("rotate second dial")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn first dial
            The first dial remains fixed in its orientation, defying
            rotation.

            > rotate second dial
            The second dial stubbornly maintains its current facing.
            """
        )

        let dial1State = try await engine.item("dial1")
        let dial2State = try await engine.item("dial2")
        #expect(await dial1State.hasFlag(.isTouched) == true)
        #expect(await dial2State.hasFlag(.isTouched) == true)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = TurnActionHandler()
        #expect(handler.synonyms.contains(.turn))
        #expect(handler.synonyms.contains(.rotate))
        #expect(handler.synonyms.contains(.twist))
        #expect(handler.synonyms.count == 3)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = TurnActionHandler()
        #expect(handler.requiresLight == true)
    }
}
