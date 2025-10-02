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
        let rope = Item("rope")
            .name("thick rope")
            .description("A thick hemp rope.")
            .in(.startRoom)

        let game = MinimalGame(
            items: rope
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pull rope")

        // Then
        await mockIO.expectOutput(
            """
            > pull rope
            The thick rope resists your tugging with stoic determination.
            """
        )

        let finalState = await engine.item("rope")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("PULL CHARACTER syntax works")
    func testPullCharacterSyntax() async throws {
        // Given
        let towerGuard = Item("guard")
            .name("surly guard")
            .description("A surly tower guard.")
            .in(.startRoom)
            .characterSheet(.default)

        let game = MinimalGame(
            items: towerGuard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pull guard")

        // Then
        await mockIO.expectOutput(
            """
            > pull guard
            The surly guard is not a rope to be tugged at your convenience.
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
        await mockIO.expectOutput(
            """
            > pull troll
            The fierce troll is not a rope to be tugged at your
            convenience.
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
        await mockIO.expectOutput(
            """
            > pull
            Pull what?
            """
        )
    }

    @Test("Cannot pull target not in scope")
    func testCannotPullTargetNotInScope() async throws {
        // Given
        let anotherRoom = Location("anotherRoom")
            .name("Another Room")
            .inherentlyLit

        let remoteLever = Item("remoteLever")
            .name("remote lever")
            .description("A lever in another room.")
            .in("anotherRoom")

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteLever
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pull lever")

        // Then
        await mockIO.expectOutput(
            """
            > pull lever
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Requires light to pull")
    func testRequiresLight() async throws {
        // Given: Dark room with an object to pull
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")

        let chain = Item("chain")
            .name("metal chain")
            .description("A heavy metal chain.")
            .in("darkRoom")

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: chain
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pull chain")

        // Then
        await mockIO.expectOutput(
            """
            > pull chain
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Pulling sets isTouched flag")
    func testPullingSetsTouchedFlag() async throws {
        // Given
        let bell = Item("bell")
            .name("church bell")
            .description("A large church bell with a rope.")
            .in(.startRoom)

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
        let rope1 = Item("rope1")
            .name("first rope")
            .description("A thick rope.")
            .in(.startRoom)

        let rope2 = Item("rope2")
            .name("second rope")
            .description("A thin rope.")
            .in(.startRoom)

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
        await mockIO.expectOutput(
            """
            > pull first rope
            The first rope resists your tugging with stoic determination.

            > pull second rope
            You strain against the second rope to no avail.
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
        let box = Item("box")
            .name("wooden box")
            .description("A wooden box with mechanisms.")
            .isContainer
            .isOpenable
            .isOpen
            .in(.startRoom)

        let string = Item("string")
            .name("pull string")
            .description("A string for pulling.")
            .in(.item("box"))

        let game = MinimalGame(
            items: box, string
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pull string")

        // Then
        await mockIO.expectOutput(
            """
            > pull string
            The pull string resists your tugging with stoic determination.
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
