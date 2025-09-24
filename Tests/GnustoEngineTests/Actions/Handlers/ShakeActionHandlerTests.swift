import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("ShakeActionHandler Tests")
struct ShakeActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("SHAKE DIRECTOBJECT syntax works")
    func testShakeDirectObjectSyntax() async throws {
        // Given
        let bottle = Item(
            id: "bottle",
            .name("empty bottle"),
            .description("A glass bottle."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: bottle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("shake bottle")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > shake bottle
            You give the empty bottle a vigorous shake. Nothing rattles,
            breaks, or emerges.
            """
        )

        let finalState = await engine.item("bottle")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    // MARK: - Validation Testing

    @Test("Cannot shake without specifying target")
    func testCannotShakeWithoutTarget() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("shake")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > shake
            You shake yourself like a wet dog, dignity be damned.
            """
        )
    }

    @Test("Cannot shake target not in scope")
    func testCannotShakeTargetNotInScope() async throws {
        // Given
        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let remoteItem = Item(
            id: "remoteItem",
            .name("remote item"),
            .description("An item in another room."),
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteItem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("shake item")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > shake item
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Requires light to shake")
    func testRequiresLight() async throws {
        // Given: Dark room with an object to shake
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let jar = Item(
            id: "jar",
            .name("glass jar"),
            .description("A large glass jar."),
            .in("darkRoom")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: jar
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("shake jar")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > shake jar
            You stand in a depthless black where even your thoughts seem to
            whisper, careful not to make a sound.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Shake character")
    func testShakeCharacter() async throws {
        // Given
        let wizard = Item(
            id: "wizard",
            .name("old wizard"),
            .description("A wise old wizard with a long beard."),
            .characterSheet(.wise),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: wizard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("shake the wizard")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > shake the wizard
            Rattling the old wizard like a maraca would be most
            undignified.
            """
        )
    }

    @Test("Shake enemy")
    func testShakeEnemy() async throws {
        // Given
        let game = MinimalGame(
            items: Lab.troll
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("shake the troll")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > shake the troll
            Rattling the fierce troll like a maraca would be most
            undignified.
            """
        )
    }

    @Test("Shake self")
    func testShakeSelf() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("shake myself")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > shake myself
            A vigorous self-shake loosens your muscles if not your
            troubles.
            """
        )
    }

    @Test("Shaking sets isTouched flag")
    func testShakingSetsTouchedFlag() async throws {
        // Given
        let bell = Item(
            id: "bell",
            .name("small bell"),
            .description("A tiny bronze bell."),
            .isTakable,
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
        try await engine.execute("shake bell")

        // Then
        let finalState = await engine.item("bell")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Shake multiple objects in sequence")
    func testShakeMultipleObjects() async throws {
        // Given
        let box1 = Item(
            id: "box1",
            .name("small box"),
            .description("A small wooden box."),
            .isTakable,
            .in(.startRoom)
        )

        let box2 = Item(
            id: "box2",
            .name("large box"),
            .description("A large cardboard box."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: box1, box2
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute(
            "shake small box",
            "rattle large box"
        )

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > shake small box
            You give the small box a vigorous shake. Nothing rattles,
            breaks, or emerges.

            > rattle large box
            The large box tolerates your shaking with stoic indifference.
            """
        )

        let box1State = await engine.item("box1")
        let box2State = await engine.item("box2")
        #expect(await box1State.hasFlag(.isTouched) == true)
        #expect(await box2State.hasFlag(.isTouched) == true)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = ShakeActionHandler()
        #expect(handler.synonyms.contains(.shake))
        #expect(handler.synonyms.contains(.rattle))
        #expect(handler.synonyms.count == 2)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = ShakeActionHandler()
        #expect(handler.requiresLight == true)
    }
}
