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
        try await engine.execute("turn dial", times: 3)

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > turn dial
            The brass dial responds to your efforts with the immovable
            dignity of something that predates your arrival.

            > turn dial
            The brass dial demonstrates the sort of steadfast resolve that
            comes with being bolted to reality.

            > turn dial
            You find that the brass dial has strong architectural opinions
            about remaining in its designated spot.
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
            The steering wheel responds to your efforts with the immovable
            dignity of something that predates your arrival.
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
            The door knob responds to your efforts with the immovable
            dignity of something that predates your arrival.
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
        try await engine.execute("turn guard", times: 3)

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > turn guard
            You discover that the palace guard has developed a
            philosophical attachment to facing this particular way.

            > turn guard
            Your attempt to turn the palace guard reveals that they’re
            surprisingly committed to their present orientation.

            > turn guard
            The palace guard maintains their bearing with the quiet dignity
            of someone who knows which way they’re facing.
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
        try await engine.execute("turn cube", times: 3)

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > turn cube
            The puzzle cube responds to your turning attempt with the
            unwavering resolve of the professionally immobile.

            > turn cube
            The puzzle cube demonstrates the sort of stubborn integrity
            that refuses to be turned by mere enthusiasm.

            > turn cube
            Your turning efforts bounce off the puzzle cube like optimism
            off a tax collector.
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
        try await engine.execute("turn statue", times: 3)

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > turn statue
            The marble statue responds to your efforts with the immovable
            dignity of something that predates your arrival.

            > turn statue
            The marble statue demonstrates the sort of steadfast resolve
            that comes with being bolted to reality.

            > turn statue
            You find that the marble statue has strong architectural
            opinions about remaining in its designated spot.
            """)
    }

    @Test("Turn location")
    func testTurnLocation() async throws {
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
        try await engine.execute("turn Test Room")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > turn Test Room
            You can’t turn that.
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

        let (engine, _) = await GameEngine.test(blueprint: game)

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
            The first dial responds to your efforts with the immovable
            dignity of something that predates your arrival.

            > rotate second dial
            The second dial demonstrates the sort of steadfast resolve that
            comes with being bolted to reality.
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
