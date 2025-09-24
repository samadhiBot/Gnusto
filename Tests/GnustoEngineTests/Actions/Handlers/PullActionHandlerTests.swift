import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("PullActionHandler Tests")
struct PullActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("PULL DIRECTOBJECT syntax works")
    func testPullDirectObjectSyntax() async throws {
        // Given
        let rope = Item(
            id: "rope",
            .name("thick rope"),
            .description("A thick hemp rope."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: rope
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pull rope")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > pull rope
            No amount of pulling will budge the thick rope.
            """
        )

        let finalState = await engine.item("rope")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("PULL CHARACTER syntax works")
    func testPullCharacterSyntax() async throws {
        // Given
        let towerGuard = Item(
            id: "guard",
            .name("surly guard"),
            .description("A surly tower guard."),
            .in(.startRoom),
            .characterSheet(.init())
        )

        let game = MinimalGame(
            items: towerGuard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pull guard")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > pull guard
            Yanking the surly guard about would strain both fabric and
            friendship.
            """
        )

        let finalState = await engine.item("guard")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("PULL ENEMY syntax works")
    func testPullEnemySyntax() async throws {
        // Given
        let game = MinimalGame(
            items: Lab.troll
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pull troll")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > pull troll
            Yanking the fierce troll about would strain both fabric and
            friendship.
            """
        )

        let finalState = await engine.item("troll")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    // MARK: - Validation Testing

    @Test("Cannot pull without specifying target")
    func testCannotPullWithoutTarget() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pull")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > pull
            Pull what?
            """
        )
    }

    @Test("Cannot pull target not in scope")
    func testCannotPullTargetNotInScope() async throws {
        // Given
        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let remoteLever = Item(
            id: "remoteLever",
            .name("remote lever"),
            .description("A lever in another room."),
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteLever
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pull lever")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > pull lever
            Any such thing remains frustratingly inaccessible.
            """
        )
    }

    @Test("Requires light to pull")
    func testRequiresLight() async throws {
        // Given: Dark room with an object to pull
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let chain = Item(
            id: "chain",
            .name("metal chain"),
            .description("A heavy metal chain."),
            .in("darkRoom")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: chain
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pull chain")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > pull chain
            You stand in a depthless black where even your thoughts seem to
            whisper, careful not to make a sound.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Pulling sets isTouched flag")
    func testPullingSetsTouchedFlag() async throws {
        // Given
        let bell = Item(
            id: "bell",
            .name("church bell"),
            .description("A large church bell with a rope."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: bell
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // Verify initial state
        let initialState = await engine.item("bell")
        #expect(await initialState.hasFlag(.isTouched) == false)

        // When
        try await engine.execute("pull bell")

        // Then
        let finalState = await engine.item("bell")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Pull sequence of different objects")
    func testPullSequenceOfDifferentObjects() async throws {
        // Given
        let rope1 = Item(
            id: "rope1",
            .name("first rope"),
            .description("A thick rope."),
            .in(.startRoom)
        )

        let rope2 = Item(
            id: "rope2",
            .name("second rope"),
            .description("A thin rope."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: rope1, rope2
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute(
            "pull first rope",
            "pull second rope"
        )

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > pull first rope
            No amount of pulling will budge the first rope.

            > pull second rope
            The second rope resists your tugging with stoic determination.
            """
        )

        let rope1State = await engine.item("rope1")
        let rope2State = await engine.item("rope2")
        #expect(await rope1State.hasFlag(.isTouched) == true)
        #expect(await rope2State.hasFlag(.isTouched) == true)
    }

    @Test("Pull object in open container")
    func testPullObjectInOpenContainer() async throws {
        // Given
        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A wooden box with mechanisms."),
            .isContainer,
            .isOpenable,
            .isOpen,
            .in(.startRoom)
        )

        let string = Item(
            id: "string",
            .name("pull string"),
            .description("A string for pulling."),
            .in(.item("box"))
        )

        let game = MinimalGame(
            items: box, string
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pull string")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > pull string
            No amount of pulling will budge the pull string.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = PullActionHandler()
        #expect(handler.synonyms.contains(.pull))
        #expect(handler.synonyms.count == 1)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = PullActionHandler()
        #expect(handler.requiresLight == true)
    }
}
