import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("SqueezeActionHandler Tests")
struct SqueezeActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("SQUEEZE DIRECTOBJECT syntax works")
    func testSqueezeDirectObjectSyntax() async throws {
        // Given
        let sponge = Item(
            id: "sponge",
            .name("wet sponge"),
            .description("A soggy wet sponge."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: sponge
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("squeeze sponge")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > squeeze sponge
            You squeeze the wet sponge with determination. Nothing of note
            occurs.
            """
        )

        let finalState = await engine.item("sponge")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("COMPRESS syntax works")
    func testCompressSyntax() async throws {
        // Given
        let bellows = Item(
            id: "bellows",
            .name("leather bellows"),
            .description("A set of leather bellows."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: bellows
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("compress bellows")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > compress bellows
            You compress the leather bellows with determination. Nothing of
            note occurs.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot squeeze without specifying what")
    func testCannotSqueezeWithoutTarget() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("squeeze")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > squeeze
            Squeeze what?
            """
        )
    }

    @Test("Cannot squeeze non-existent item")
    func testCannotSqueezeNonExistentItem() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("squeeze nonexistent")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > squeeze nonexistent
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot squeeze item not in reach")
    func testCannotSqueezeItemNotInReach() async throws {
        // Given
        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let distantItem = Item(
            id: "distantItem",
            .name("distant pillow"),
            .description("A pillow in another room."),
            .isTakable,
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
            items: distantItem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("squeeze pillow")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > squeeze pillow
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot squeeze non-item")
    func testCannotSqueezeNonItem() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("squeeze the ocean")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > squeeze the ocean
            That defies the fundamental laws of squeezing.
            """
        )
    }

    @Test("Requires light to squeeze")
    func testRequiresLight() async throws {
        // Given: Dark room with item
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let cushion = Item(
            id: "cushion",
            .name("soft cushion"),
            .description("A soft, squishy cushion."),
            .isTakable,
            .in("darkRoom")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: cushion
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("squeeze cushion")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > squeeze cushion
            You stand in a depthless black where even your thoughts seem to
            whisper, careful not to make a sound.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Squeeze generic item")
    func testSqueezeGenericItem() async throws {
        // Given
        let ball = Item(
            id: "ball",
            .name("rubber ball"),
            .description("A squishy rubber ball."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: ball
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("squeeze the rubber ball")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > squeeze the rubber ball
            You squeeze the rubber ball with determination. Nothing of note
            occurs.
            """
        )

        let finalState = await engine.item("ball")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Squeeze character gives appropriate message")
    func testSqueezeCharacter() async throws {
        // Given
        let cat = Item(
            id: "cat",
            .name("fluffy cat"),
            .description("A soft, fluffy cat."),
            .characterSheet(.strong),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: cat
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("squeeze the cat")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > squeeze the cat
            The fluffy cat is unlikely to appreciate being squeezed right
            now.
            """
        )

        let finalState = await engine.item("cat")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Squeeze enemy gives appropriate message")
    func testSqueezeEnemy() async throws {
        // Given
        let necromancer = Item(
            id: "necromancer",
            .name("furious necromancer"),
            .description("An angry old necromancer."),
            .characterSheet(
                CharacterSheet(isFighting: true)
            ),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: necromancer
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("squeeze the necromancer")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > squeeze the necromancer
            Squeezing the furious necromancer seems… ill-advised in the
            current climate.

            The furious necromancer attacks with pure murderous intent! You
            brace yourself for the impact, guard up, ready for the worst
            kind of fight.
            """
        )

        let finalState = await engine.item("necromancer")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Squeeze self")
    func testSqueezeSelf() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("squeeze myself")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > squeeze myself
            A reassuring self-squeeze bolsters your spirits.
            """
        )
    }

    @Test("Squeeze multiple items sequentially")
    func testSqueezeMultipleItemsSequentially() async throws {
        // Given
        let pillow1 = Item(
            id: "pillow1",
            .name("red pillow"),
            .description("A soft red pillow."),
            .isTakable,
            .in(.startRoom)
        )

        let pillow2 = Item(
            id: "pillow2",
            .name("blue pillow"),
            .description("A soft blue pillow."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: pillow1, pillow2
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute(
            "squeeze red pillow",
            "squeeze blue pillow"
        )

        // Then - verify second pillow was squeezed
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > squeeze red pillow
            You squeeze the red pillow with determination. Nothing of note
            occurs.

            > squeeze blue pillow
            You apply pressure to the blue pillow. The universe declines to
            be impressed.
            """
        )

        let finalPillow2 = await engine.item("pillow2")
        #expect(await finalPillow2.hasFlag(.isTouched) == true)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = SqueezeActionHandler()
        expectNoDifference(handler.synonyms, [.squeeze, .compress, .hug])
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = SqueezeActionHandler()
        #expect(handler.requiresLight == true)
    }
}
