import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("ThinkActionHandler Tests")
struct ThinkActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("THINK syntax works")
    func testThinkSyntax() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("think")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > think
            The gears of contemplation grind slowly but surely.
            """
        )
    }

    @Test("THINK ABOUT DIRECTOBJECT syntax works")
    func testThinkAboutDirectObjectSyntax() async throws {
        // Given
        let puzzle = Item(
            id: "puzzle",
            .name("ancient puzzle"),
            .description("A mysterious ancient puzzle."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: puzzle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("think about puzzle")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > think about puzzle
            Your thoughts circle around the ancient puzzle like moths
            around flame.
            """
        )

        let finalState = await engine.item("puzzle")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("CONSIDER DIRECTOBJECT syntax works")
    func testConsiderDirectObjectSyntax() async throws {
        // Given
        let gem = Item(
            id: "gem",
            .name("sparkling gem"),
            .description("A beautiful sparkling gem."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: gem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("consider gem")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > consider gem
            Your thoughts circle around the sparkling gem like moths around
            flame.
            """
        )

        let finalState = await engine.item("gem")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("PONDER OVER DIRECTOBJECT syntax works")
    func testPonderOverDirectObjectSyntax() async throws {
        // Given
        let riddle = Item(
            id: "riddle",
            .name("complex riddle"),
            .description("A challenging riddle."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: riddle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("ponder over riddle")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > ponder over riddle
            Your thoughts circle around the complex riddle like moths
            around flame.
            """
        )

        let finalState = await engine.item("riddle")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    // MARK: - Validation Testing

    @Test("Cannot think about non-existent item")
    func testCannotThinkAboutNonExistentItem() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("think about nonexistent")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > think about nonexistent
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot think about item not in scope")
    func testCannotThinkAboutItemNotInScope() async throws {
        // Given
        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let distantItem = Item(
            id: "distantItem",
            .name("distant object"),
            .description("An object in another room."),
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
            items: distantItem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("think about object")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > think about object
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Think works in dark rooms without object")
    func testThinkWorksInDarkRooms() async throws {
        // Given: Dark room (thinking doesn't require light)
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("think")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > think
            The gears of contemplation grind slowly but surely.
            """
        )
    }

    @Test("Think about item works in dark rooms")
    func testThinkAboutItemWorksInDarkRooms() async throws {
        // Given: Dark room with item (thinking doesn't require light)
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let stone = Item(
            id: "stone",
            .name("smooth stone"),
            .description("A smooth stone."),
            .in("darkRoom")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: stone
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("think about stone")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > think about stone
            Your thoughts circle around the smooth stone like moths around
            flame.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Think about character gives appropriate message")
    func testThinkAboutCharacter() async throws {
        // Given
        let wizard = Item(
            id: "wizard",
            .name("old wizard"),
            .description("A wise old wizard."),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: wizard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("think about wizard")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > think about wizard
            You think about the old wizard.
            """
        )

        let finalState = await engine.item("wizard")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Think about enemy gives appropriate message")
    func testThinkAboutEnemy() async throws {
        // Given
        let game = MinimalGame(
            items: Lab.troll
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("think about troll")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > think about troll
            You think about the fierce troll.
            """
        )

        let finalState = await engine.item("troll")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Think about generic object")
    func testThinkAboutGenericObject() async throws {
        // Given
        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A simple wooden box."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("think about box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > think about box
            Your thoughts circle around the wooden box like moths around
            flame.
            """
        )

        let finalState = await engine.item("box")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Think about self")
    func testThinkAboutSelf() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("think about myself")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > think about myself
            A moment of introspection reveals nothing you didn't already
            suspect.
            """
        )
    }

    @Test("Think about location")
    func testThinkAboutLocation() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("think about the test room")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > think about the test room
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Think about universal concept")
    func testThinkAboutUniversal() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("think about silence")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > think about silence
            You ponder the deeper meaning of the silence.
            """
        )
    }

    @Test("Think without object gives general response")
    func testThinkWithoutObject() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("think")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > think
            The gears of contemplation grind slowly but surely.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = ThinkActionHandler()
        #expect(handler.synonyms.contains(.think))
        #expect(handler.synonyms.contains(.consider))
        #expect(handler.synonyms.contains(.ponder))
        #expect(handler.synonyms.count == 3)
    }

    @Test("Handler does not require light")
    func testDoesNotRequireLight() async throws {
        let handler = ThinkActionHandler()
        #expect(handler.requiresLight == false)
    }
}
