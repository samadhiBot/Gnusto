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
        await mockIO.expectOutput(
            """
            > think
            Deep cogitation yields no immediate revelations.
            """
        )
    }

    @Test("THINK ABOUT DIRECTOBJECT syntax works")
    func testThinkAboutDirectObjectSyntax() async throws {
        // Given
        let puzzle = Item("puzzle")
            .name("ancient puzzle")
            .description("A mysterious ancient puzzle.")
            .in(.startRoom)

        let game = MinimalGame(
            items: puzzle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("think about puzzle")

        // Then
        await mockIO.expectOutput(
            """
            > think about puzzle
            The ancient puzzle occupies your mental landscape for a
            thoughtful moment.
            """
        )

        let finalState = await engine.item("puzzle")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("CONSIDER DIRECTOBJECT syntax works")
    func testConsiderDirectObjectSyntax() async throws {
        // Given
        let gem = Item("gem")
            .name("sparkling gem")
            .description("A beautiful sparkling gem.")
            .in(.startRoom)

        let game = MinimalGame(
            items: gem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("consider gem")

        // Then
        await mockIO.expectOutput(
            """
            > consider gem
            The sparkling gem occupies your mental landscape for a
            thoughtful moment.
            """
        )

        let finalState = await engine.item("gem")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("PONDER OVER DIRECTOBJECT syntax works")
    func testPonderOverDirectObjectSyntax() async throws {
        // Given
        let riddle = Item("riddle")
            .name("complex riddle")
            .description("A challenging riddle.")
            .in(.startRoom)

        let game = MinimalGame(
            items: riddle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("ponder over riddle")

        // Then
        await mockIO.expectOutput(
            """
            > ponder over riddle
            The complex riddle occupies your mental landscape for a
            thoughtful moment.
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
        await mockIO.expectOutput(
            """
            > think about nonexistent
            You cannot reach any such thing from here.
            """
        )
    }

    @Test("Cannot think about item not in scope")
    func testCannotThinkAboutItemNotInScope() async throws {
        // Given
        let anotherRoom = Location("anotherRoom")
            .name("Another Room")
            .inherentlyLit

        let distantItem = Item("distantItem")
            .name("distant object")
            .description("An object in another room.")
            .in("anotherRoom")

        let game = MinimalGame(
            locations: anotherRoom,
            items: distantItem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("think about object")

        // Then
        await mockIO.expectOutput(
            """
            > think about object
            You cannot reach any such thing from here.
            """
        )
    }

    @Test("Think works in dark rooms without object")
    func testThinkWorksInDarkRooms() async throws {
        // Given: Dark room (thinking doesn't require light)
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")
            // Note: No .inherentlyLit property

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("think")

        // Then
        await mockIO.expectOutput(
            """
            > think
            Deep cogitation yields no immediate revelations.
            """
        )
    }

    @Test("Think about item works in dark rooms")
    func testThinkAboutItemWorksInDarkRooms() async throws {
        // Given: Dark room with item (thinking doesn't require light)
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")
            // Note: No .inherentlyLit property

        let stone = Item("stone")
            .name("smooth stone")
            .description("A smooth stone.")
            .in("darkRoom")

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: stone
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("think about stone")

        // Then
        await mockIO.expectOutput(
            """
            > think about stone
            The smooth stone occupies your mental landscape for a
            thoughtful moment.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Think about character gives appropriate message")
    func testThinkAboutCharacter() async throws {
        // Given
        let wizard = Item("wizard")
            .name("old wizard")
            .description("A wise old wizard.")
            .characterSheet(.default)
            .in(.startRoom)

        let game = MinimalGame(
            items: wizard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("think about wizard")

        // Then
        await mockIO.expectOutput(
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
        await mockIO.expectOutput(
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
        let box = Item("box")
            .name("wooden box")
            .description("A simple wooden box.")
            .in(.startRoom)

        let game = MinimalGame(
            items: box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("think about box")

        // Then
        await mockIO.expectOutput(
            """
            > think about box
            The wooden box occupies your mental landscape for a thoughtful
            moment.
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
        await mockIO.expectOutput(
            """
            > think about myself
            You turn your thoughts inward, finding the usual mixture of
            hope and regret.
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
        await mockIO.expectOutput(
            """
            > think about the test room
            You cannot reach any such thing from here.
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
        await mockIO.expectOutput(
            """
            > think about silence
            The nature of the silence occupies your philosophical
            attention.
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
        await mockIO.expectOutput(
            """
            > think
            Deep cogitation yields no immediate revelations.
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
