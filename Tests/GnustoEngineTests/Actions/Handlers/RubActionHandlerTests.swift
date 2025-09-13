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
            The brass lamp endures your rubbing without transformation or
            complaint.
            """
        )

        let finalState = try await engine.item("lamp")
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
            The wooden table endures your rubbing without transformation or
            complaint.
            """
        )

        let finalState = try await engine.item("table")
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
            The silver mirror endures your rubbing without transformation
            or complaint.
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
            The dirty window endures your rubbing without transformation or
            complaint.
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
            You cannot reach any such thing from here.
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
            You cannot reach any such thing from here.
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
            You rub yourself vigorously, achieving little beyond mild
            warmth.
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
            The darkness here is absolute, consuming all light and hope of
            sight.
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

        let finalState = try await engine.item("wizard")
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

            In a moment of raw violence, the furious necromancer comes at
            you with nothing but fury! You raise your fists, knowing this
            will hurt regardless of who wins.
            """
        )

        let finalState = try await engine.item("necromancer")
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
            The stone wall endures your rubbing without transformation or
            complaint.
            """
        )

        let finalState = try await engine.item("wall")
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
            The ceramic vase endures your rubbing without transformation or
            complaint.
            """
        )

        let finalState = try await engine.item("vase")
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
