import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("RaiseActionHandler Tests")
struct RaiseActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("RAISE DIRECTOBJECT syntax works")
    func testRaiseDirectObjectSyntax() async throws {
        // Given
        let box = Item("box")
            .name("wooden box")
            .description("A heavy wooden box.")
            .in(.startRoom)

        let game = MinimalGame(
            items: box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("raise box")

        // Then
        await mockIO.expectOutput(
            """
            > raise box
            You consider whether to raise the wooden box, then decide
            against it.
            """
        )

        let finalState = await engine.item("box")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("LIFT syntax works")
    func testLiftSyntax() async throws {
        // Given
        let stone = Item("stone")
            .name("heavy stone")
            .description("A large heavy stone.")
            .in(.startRoom)

        let game = MinimalGame(
            items: stone
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("lift stone")

        // Then
        await mockIO.expectOutput(
            """
            > lift stone
            You consider whether to lift the heavy stone, then decide
            against it.
            """
        )
    }

    @Test("HOIST syntax works")
    func testHoistSyntax() async throws {
        // Given
        let beam = Item("beam")
            .name("steel beam")
            .description("A massive steel beam.")
            .in(.startRoom)

        let game = MinimalGame(
            items: beam
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("hoist beam")

        // Then
        await mockIO.expectOutput(
            """
            > hoist beam
            You consider whether to hoist the steel beam, then decide
            against it.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot raise without specifying object")
    func testCannotRaiseWithoutObject() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("raise")

        // Then
        await mockIO.expectOutput(
            """
            > raise
            Raise what?
            """
        )
    }

    @Test("Cannot raise non-existent item")
    func testCannotRaiseNonExistentItem() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("raise nonexistent")

        // Then
        await mockIO.expectOutput(
            """
            > raise nonexistent
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot raise item not in scope")
    func testCannotRaiseItemNotInScope() async throws {
        // Given
        let anotherRoom = Location("anotherRoom")
            .name("Another Room")
            .inherentlyLit

        let remoteBox = Item("remoteBox")
            .name("remote box")
            .description("A box in another room.")
            .in("anotherRoom")

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteBox
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("raise box")

        // Then
        await mockIO.expectOutput(
            """
            > raise box
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot raise location")
    func testCannotRaiseLocation() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("raise testRoom")

        // Then
        await mockIO.expectOutput(
            """
            > raise testRoom
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot raise player")
    func testCannotRaisePlayer() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("raise me")

        // Then
        await mockIO.expectOutput(
            """
            > raise me
            The logistics of raising oneself prove insurmountable.
            """
        )
    }

    @Test("Requires light to raise")
    func testRequiresLight() async throws {
        // Given: Dark room with item
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")
            // Note: No .inherentlyLit property

        let box = Item("box")
            .name("wooden box")
            .description("A heavy wooden box.")
            .in("darkRoom")

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("raise box")

        // Then
        await mockIO.expectOutput(
            """
            > raise box
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Raise item sets touched flag")
    func testRaiseItemSetsTouchedFlag() async throws {
        // Given
        let crate = Item("crate")
            .name("wooden crate")
            .description("A large wooden crate.")
            .in(.startRoom)

        let game = MinimalGame(
            items: crate
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Verify crate is not touched initially
        let initialState = await engine.item("crate")
        #expect(await initialState.hasFlag(.isTouched) == false)

        // When
        try await engine.execute("raise crate")

        // Then
        let finalState = await engine.item("crate")
        #expect(await finalState.hasFlag(.isTouched) == true)

        await mockIO.expectOutput(
            """
            > raise crate
            You consider whether to raise the wooden crate, then decide
            against it.
            """
        )
    }

    @Test("Raise item updates pronouns")
    func testRaiseItemUpdatesPronouns() async throws {
        // Given
        let table = Item("table")
            .name("heavy table")
            .description("A massive oak table.")
            .in(.startRoom)

        let book = Item("book")
            .name("old book")
            .description("An old leather book.")
            .in(.startRoom)

        let game = MinimalGame(
            items: table, book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // First examine the book to set pronouns
        try await engine.execute("examine book")

        // When - Raise table should update pronouns to table
        try await engine.execute("raise table")

        // Then - "examine it" should now refer to the table
        try await engine.execute("examine it")

        await mockIO.expectOutput(
            """
            > examine book
            An old leather book.

            > raise table
            You consider whether to raise the heavy table, then decide
            against it.

            > examine it
            A massive oak table.
            """
        )
    }

    @Test("Raise held item works")
    func testRaiseHeldItem() async throws {
        // Given
        let weight = Item("weight")
            .name("iron weight")
            .description("A heavy iron weight.")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: weight
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("raise weight")

        // Then
        await mockIO.expectOutput(
            """
            > raise weight
            You consider whether to raise the iron weight, then decide
            against it.
            """
        )

        let finalState = await engine.item("weight")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Raise item in container")
    func testRaiseItemInContainer() async throws {
        // Given
        let box = Item("box")
            .name("storage box")
            .description("A storage box.")
            .isContainer
            .isOpen
            .in(.startRoom)

        let anvil = Item("anvil")
            .name("iron anvil")
            .description("A heavy iron anvil.")
            .in(.item("box"))

        let game = MinimalGame(
            items: box, anvil
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("raise anvil")

        // Then
        await mockIO.expectOutput(
            """
            > raise anvil
            You consider whether to raise the iron anvil, then decide
            against it.
            """
        )

        let finalState = await engine.item("anvil")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Raise different types of items")
    func testRaiseDifferentTypesOfItems() async throws {
        // Given
        let furniture = Item("furniture")
            .name("wooden chair")
            .description("A heavy wooden chair.")
            .in(.startRoom)

        let character = Item("character")
            .name("sleeping giant")
            .description("A sleeping giant.")
            .characterSheet(.strong)
            .in(.startRoom)

        let device = Item("device")
            .name("heavy machine")
            .description("A heavy industrial machine.")
            .isDevice
            .in(.startRoom)

        let game = MinimalGame(
            items: furniture, character, device
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When - Raise furniture
        try await engine.execute(
            "raise chair",
            "raise giant",
            "raise machine"
        )

        await mockIO.expectOutput(
            """
            > raise chair
            You consider whether to raise the wooden chair, then decide
            against it.

            > raise giant
            You start to raise the sleeping giant but stop yourself at the
            last moment.

            > raise machine
            Something makes you hesitate before you raise the heavy
            machine. Perhaps not.
            """
        )
    }

    @Test("Raise small vs large items")
    func testRaiseSmallVsLargeItems() async throws {
        // Given
        let feather = Item("feather")
            .name("small feather")
            .description("A tiny bird feather.")
            .in(.startRoom)

        let boulder = Item("boulder")
            .name("massive boulder")
            .description("An enormous boulder.")
            .in(.startRoom)

        let game = MinimalGame(
            items: feather, boulder
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When - Raise small item
        try await engine.execute("raise feather")

        await mockIO.expectOutput(
            """
            > raise feather
            You consider whether to raise the small feather, then decide
            against it.
            """
        )

        // When - Raise large item
        try await engine.execute("raise boulder")

        await mockIO.expectOutput(
            """
            > raise boulder
            You start to raise the massive boulder but stop yourself at the
            last moment.
            """
        )
    }

    @Test("Raise with different verb synonyms")
    func testRaiseWithDifferentVerbSynonyms() async throws {
        // Given
        let barrel = Item("barrel")
            .name("oak barrel")
            .description("A heavy oak barrel.")
            .in(.startRoom)

        let game = MinimalGame(
            items: barrel
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When - Test different verbs all produce same result

        // Test RAISE
        try await engine.execute(
            "raise barrel",
            "lift barrel",
            "hoist barrel"
        )
        await mockIO.expectOutput(
            """
            > raise barrel
            You consider whether to raise the oak barrel, then decide
            against it.

            > lift barrel
            You start to lift the oak barrel but stop yourself at the last
            moment.

            > hoist barrel
            Something makes you hesitate before you hoist the oak barrel.
            Perhaps not.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = RaiseActionHandler()
        #expect(handler.synonyms.contains(.raise))
        #expect(handler.synonyms.contains(.lift))
        #expect(handler.synonyms.contains(.hoist))
        #expect(handler.synonyms.count == 3)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = RaiseActionHandler()
        #expect(handler.requiresLight == true)
    }

    @Test("Handler uses correct syntax")
    func testSyntaxRules() async throws {
        let handler = RaiseActionHandler()
        #expect(handler.syntax.count == 1)

        // Should have one syntax rule:
        // .match(.verb, .directObject)
    }
}
