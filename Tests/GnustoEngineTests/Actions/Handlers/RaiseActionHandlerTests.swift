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
        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A heavy wooden box."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("raise box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > raise box
            Something makes you hesitate before you raise the wooden box.
            Perhaps not.
            """
        )

        let finalState = await engine.item("box")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("LIFT syntax works")
    func testLiftSyntax() async throws {
        // Given
        let stone = Item(
            id: "stone",
            .name("heavy stone"),
            .description("A large heavy stone."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: stone
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("lift stone")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > lift stone
            Something makes you hesitate before you lift the heavy stone.
            Perhaps not.
            """
        )
    }

    @Test("HOIST syntax works")
    func testHoistSyntax() async throws {
        // Given
        let beam = Item(
            id: "beam",
            .name("steel beam"),
            .description("A massive steel beam."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: beam
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("hoist beam")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > hoist beam
            Something makes you hesitate before you hoist the steel beam.
            Perhaps not.
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
        let output = await mockIO.flush()
        expectNoDifference(
            output,
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
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > raise nonexistent
            Any such thing remains frustratingly inaccessible.
            """
        )
    }

    @Test("Cannot raise item not in scope")
    func testCannotRaiseItemNotInScope() async throws {
        // Given
        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let remoteBox = Item(
            id: "remoteBox",
            .name("remote box"),
            .description("A box in another room."),
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteBox
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("raise box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > raise box
            Any such thing remains frustratingly inaccessible.
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
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > raise testRoom
            Any such thing remains frustratingly inaccessible.
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
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > raise me
            You cannot raise yourself, thankfully.
            """
        )
    }

    @Test("Requires light to raise")
    func testRequiresLight() async throws {
        // Given: Dark room with item
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A heavy wooden box."),
            .in("darkRoom")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("raise box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > raise box
            You stand in a depthless black where even your thoughts seem to
            whisper, careful not to make a sound.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Raise item sets touched flag")
    func testRaiseItemSetsTouchedFlag() async throws {
        // Given
        let crate = Item(
            id: "crate",
            .name("wooden crate"),
            .description("A large wooden crate."),
            .in(.startRoom)
        )

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

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > raise crate
            Something makes you hesitate before you raise the wooden crate.
            Perhaps not.
            """
        )
    }

    @Test("Raise item updates pronouns")
    func testRaiseItemUpdatesPronouns() async throws {
        // Given
        let table = Item(
            id: "table",
            .name("heavy table"),
            .description("A massive oak table."),
            .in(.startRoom)
        )

        let book = Item(
            id: "book",
            .name("old book"),
            .description("An old leather book."),
            .in(.startRoom)
        )

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

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine book
            An old leather book.

            > raise table
            Something makes you hesitate before you raise the heavy table.
            Perhaps not.

            > examine it
            A massive oak table.
            """
        )
    }

    @Test("Raise held item works")
    func testRaiseHeldItem() async throws {
        // Given
        let weight = Item(
            id: "weight",
            .name("iron weight"),
            .description("A heavy iron weight."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: weight
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("raise weight")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > raise weight
            Something makes you hesitate before you raise the iron weight.
            Perhaps not.
            """
        )

        let finalState = await engine.item("weight")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Raise item in container")
    func testRaiseItemInContainer() async throws {
        // Given
        let box = Item(
            id: "box",
            .name("storage box"),
            .description("A storage box."),
            .isContainer,
            .isOpen,
            .in(.startRoom)
        )

        let anvil = Item(
            id: "anvil",
            .name("iron anvil"),
            .description("A heavy iron anvil."),
            .in(.item("box"))
        )

        let game = MinimalGame(
            items: box, anvil
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("raise anvil")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > raise anvil
            Something makes you hesitate before you raise the iron anvil.
            Perhaps not.
            """
        )

        let finalState = await engine.item("anvil")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Raise different types of items")
    func testRaiseDifferentTypesOfItems() async throws {
        // Given
        let furniture = Item(
            id: "furniture",
            .name("wooden chair"),
            .description("A heavy wooden chair."),
            .in(.startRoom)
        )

        let character = Item(
            id: "character",
            .name("sleeping giant"),
            .description("A sleeping giant."),
            .characterSheet(.strong),
            .in(.startRoom)
        )

        let device = Item(
            id: "device",
            .name("heavy machine"),
            .description("A heavy industrial machine."),
            .isDevice,
            .in(.startRoom)
        )

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

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > raise chair
            Something makes you hesitate before you raise the wooden chair.
            Perhaps not.

            > raise giant
            You consider whether to raise the sleeping giant, then decide
            against it.

            > raise machine
            On second thought, you decide not to raise the heavy machine.
            """
        )
    }

    @Test("Raise small vs large items")
    func testRaiseSmallVsLargeItems() async throws {
        // Given
        let feather = Item(
            id: "feather",
            .name("small feather"),
            .description("A tiny bird feather."),
            .in(.startRoom)
        )

        let boulder = Item(
            id: "boulder",
            .name("massive boulder"),
            .description("An enormous boulder."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: feather, boulder
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When - Raise small item
        try await engine.execute("raise feather")

        let featherOutput = await mockIO.flush()
        expectNoDifference(
            featherOutput,
            """
            > raise feather
            Something makes you hesitate before you raise the small
            feather. Perhaps not.
            """
        )

        // When - Raise large item
        try await engine.execute("raise boulder")

        let boulderOutput = await mockIO.flush()
        expectNoDifference(
            boulderOutput,
            """
            > raise boulder
            You consider whether to raise the massive boulder, then decide
            against it.
            """
        )
    }

    @Test("Raise with different verb synonyms")
    func testRaiseWithDifferentVerbSynonyms() async throws {
        // Given
        let barrel = Item(
            id: "barrel",
            .name("oak barrel"),
            .description("A heavy oak barrel."),
            .in(.startRoom)
        )

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
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > raise barrel
            Something makes you hesitate before you raise the oak barrel.
            Perhaps not.

            > lift barrel
            You consider whether to lift the oak barrel, then decide
            against it.

            > hoist barrel
            On second thought, you decide not to hoist the oak barrel.
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
