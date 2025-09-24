import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("RubActionHandler Tests")
struct RubActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("RUB DIRECTOBJECT syntax works")
    func testRubDirectObjectSyntax() async throws {
        // Given
        let lamp = Item(
            id: "lamp",
            .name("brass lamp"),
            .description("A shiny brass lamp."),
            .isTakable,
            .isLightSource,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("rub lamp")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > rub lamp
            Your vigorous rubbing of the brass lamp produces neither genies
            nor results.
            """
        )

        let finalState = await engine.item("lamp")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("RUB DIRECTOBJECT WITH INDIRECTOBJECT syntax works")
    func testRubWithIndirectObjectSyntax() async throws {
        // Given
        let table = Item(
            id: "table",
            .name("wooden table"),
            .description("A sturdy wooden table."),
            .in(.startRoom)
        )

        let cloth = Item(
            id: "cloth",
            .name("cleaning cloth"),
            .description("A soft cleaning cloth."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: table, cloth
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("rub table with cloth")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > rub table with cloth
            Your vigorous rubbing of the wooden table produces neither
            genies nor results.
            """
        )

        let finalState = await engine.item("table")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("POLISH syntax works")
    func testPolishSyntax() async throws {
        // Given
        let mirror = Item(
            id: "mirror",
            .name("silver mirror"),
            .description("A polished silver mirror."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: mirror
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("polish mirror")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > polish mirror
            Your vigorous rubbing of the silver mirror produces neither
            genies nor results.
            """
        )
    }

    @Test("CLEAN syntax works")
    func testCleanSyntax() async throws {
        // Given
        let window = Item(
            id: "window",
            .name("dirty window"),
            .description("A window covered in grime."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: window
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("clean window")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > clean window
            Your vigorous rubbing of the dirty window produces neither
            genies nor results.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot rub without specifying what")
    func testCannotRubWithoutTarget() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("rub")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > rub
            Rub what?
            """
        )
    }

    @Test("Cannot rub non-existent item")
    func testCannotRubNonExistentItem() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("rub nonexistent")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > rub nonexistent
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot rub item not in reach")
    func testCannotRubItemNotInReach() async throws {
        // Given
        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let distantItem = Item(
            id: "distantItem",
            .name("distant statue"),
            .description("A statue in another room."),
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
            items: distantItem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("rub statue")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > rub statue
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot rub non-item")
    func testCannotRubNonItem() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("rub me")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > rub me
            Your self-massage provides minimal therapeutic value.
            """
        )
    }

    @Test("Requires light to rub")
    func testRequiresLight() async throws {
        // Given: Dark room with item
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let statue = Item(
            id: "statue",
            .name("stone statue"),
            .description("A carved stone statue."),
            .in("darkRoom")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: statue
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("rub statue")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > rub statue
            You stand in a depthless black where even your thoughts seem to
            whisper, careful not to make a sound.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Rub character gives appropriate message")
    func testRubCharacter() async throws {
        // Given
        let wizard = Item(
            id: "wizard",
            .name("old wizard"),
            .description("A wise old wizard."),
            .characterSheet(.wise),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: wizard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("rub the wizard")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > rub the wizard
            I don't think the old wizard would appreciate that.
            """
        )

        let finalState = await engine.item("wizard")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Rub enemy gives appropriate message")
    func testRubEnemy() async throws {
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
        try await engine.execute("rub the necromancer")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > rub the necromancer
            That would be quite inappropriate.

            The furious necromancer attacks with pure murderous intent! You
            brace yourself for the impact, guard up, ready for the worst
            kind of fight.
            """
        )

        let finalState = await engine.item("necromancer")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Rub generic object")
    func testRubGenericObject() async throws {
        // Given
        let wall = Item(
            id: "wall",
            .name("stone wall"),
            .description("A rough stone wall."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: wall
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("rub the wall")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > rub the wall
            Your vigorous rubbing of the stone wall produces neither genies
            nor results.
            """
        )

        let finalState = await engine.item("wall")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Rub with indirect object")
    func testRubWithIndirectObject() async throws {
        // Given
        let vase = Item(
            id: "vase",
            .name("ceramic vase"),
            .description("A delicate ceramic vase."),
            .isTakable,
            .in(.startRoom)
        )

        let rag = Item(
            id: "rag",
            .name("old rag"),
            .description("A worn cleaning rag."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: vase, rag
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("rub vase with rag")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > rub vase with rag
            Your vigorous rubbing of the ceramic vase produces neither
            genies nor results.
            """
        )

        let finalState = await engine.item("vase")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = RubActionHandler()
        expectNoDifference(handler.synonyms, [.rub, .polish, .clean, .massage])
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = RubActionHandler()
        #expect(handler.requiresLight == true)
    }
}
