import CustomDump
import Testing

@testable import GnustoEngine

@Suite("RaiseActionHandler Tests")
struct RaiseActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("RAISE DIRECTOBJECT syntax works")
    func testRaiseDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A heavy wooden box."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            You can’t lift the wooden box.
            """)

        let finalState = try await engine.item("box")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("LIFT syntax works")
    func testLiftSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let stone = Item(
            id: "stone",
            .name("heavy stone"),
            .description("A large heavy stone."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            You can’t lift the heavy stone.
            """)
    }

    @Test("HOIST syntax works")
    func testHoistSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let beam = Item(
            id: "beam",
            .name("steel beam"),
            .description("A massive steel beam."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            You can’t lift the steel beam.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot raise without specifying object")
    func testCannotRaiseWithoutObject() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

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
            """)
    }

    @Test("Cannot raise non-existent item")
    func testCannotRaiseNonExistentItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("raise nonexistent")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > raise nonexistent
            You can’t see any such thing.
            """)
    }

    @Test("Cannot raise item not in scope")
    func testCannotRaiseItemNotInScope() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let remoteBox = Item(
            id: "remoteBox",
            .name("remote box"),
            .description("A box in another room."),
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
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
            You can’t see any such thing.
            """)
    }

    @Test("Cannot raise location")
    func testCannotRaiseLocation() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("raise testRoom")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > raise testRoom
            That’s not something you can raise.
            """)
    }

    @Test("Cannot raise player")
    func testCannotRaisePlayer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("raise me")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > raise me
            That’s not something you can raise.
            """)
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
            .in(.location("darkRoom"))
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
            It is pitch black. You can’t see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Raise item sets touched flag")
    func testRaiseItemSetsTouchedFlag() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let crate = Item(
            id: "crate",
            .name("wooden crate"),
            .description("A large wooden crate."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: crate
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Verify crate is not touched initially
        let initialState = try await engine.item("crate")
        #expect(initialState.hasFlag(.isTouched) == false)

        // When
        try await engine.execute("raise crate")

        // Then
        let finalState = try await engine.item("crate")
        #expect(finalState.hasFlag(.isTouched) == true)

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > raise crate
            You can’t lift the wooden crate.
            """)
    }

    @Test("Raise item updates pronouns")
    func testRaiseItemUpdatesPronouns() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let table = Item(
            id: "table",
            .name("heavy table"),
            .description("A massive oak table."),
            .in(.location("testRoom"))
        )

        let book = Item(
            id: "book",
            .name("old book"),
            .description("An old leather book."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: table, book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // First examine the book to set pronouns
        try await engine.execute("examine book")
        _ = await mockIO.flush()

        // When - Raise table should update pronouns to table
        try await engine.execute("raise table")
        _ = await mockIO.flush()

        // Then - "examine it" should now refer to the table
        try await engine.execute("examine it")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine it
            A massive oak table.
            """)
    }

    @Test("Raise held item works")
    func testRaiseHeldItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let weight = Item(
            id: "weight",
            .name("iron weight"),
            .description("A heavy iron weight."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            You can’t lift the iron weight.
            """)

        let finalState = try await engine.item("weight")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Raise item in container")
    func testRaiseItemInContainer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let box = Item(
            id: "box",
            .name("storage box"),
            .description("A storage box."),
            .isContainer,
            .isOpen,
            .in(.location("testRoom"))
        )

        let anvil = Item(
            id: "anvil",
            .name("iron anvil"),
            .description("A heavy iron anvil."),
            .in(.item("box"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            You can’t lift the iron anvil.
            """)

        let finalState = try await engine.item("anvil")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Raise different types of items")
    func testRaiseDifferentTypesOfItems() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let furniture = Item(
            id: "furniture",
            .name("wooden chair"),
            .description("A heavy wooden chair."),
            .in(.location("testRoom"))
        )

        let character = Item(
            id: "character",
            .name("sleeping giant"),
            .description("A sleeping giant."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let device = Item(
            id: "device",
            .name("heavy machine"),
            .description("A heavy industrial machine."),
            .isDevice,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: furniture, character, device
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When - Raise furniture
        try await engine.execute("raise chair")

        let furnitureOutput = await mockIO.flush()
        expectNoDifference(
            furnitureOutput,
            """
            > raise chair
            You can’t lift the wooden chair.
            """)

        // When - Raise character
        try await engine.execute("raise giant")

        let characterOutput = await mockIO.flush()
        expectNoDifference(
            characterOutput,
            """
            > raise giant
            You can’t lift the sleeping giant.
            """)

        // When - Raise device
        try await engine.execute("raise machine")

        let deviceOutput = await mockIO.flush()
        expectNoDifference(
            deviceOutput,
            """
            > raise machine
            You can’t lift the heavy machine.
            """)
    }

    @Test("Raise small vs large items")
    func testRaiseSmallVsLargeItems() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let feather = Item(
            id: "feather",
            .name("small feather"),
            .description("A tiny bird feather."),
            .in(.location("testRoom"))
        )

        let boulder = Item(
            id: "boulder",
            .name("massive boulder"),
            .description("An enormous boulder."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            You can’t lift the small feather.
            """)

        // When - Raise large item
        try await engine.execute("raise boulder")

        let boulderOutput = await mockIO.flush()
        expectNoDifference(
            boulderOutput,
            """
            > raise boulder
            You can’t lift the massive boulder.
            """)
    }

    @Test("Raise with different verb synonyms")
    func testRaiseWithDifferentVerbSynonyms() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let barrel = Item(
            id: "barrel",
            .name("oak barrel"),
            .description("A heavy oak barrel."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: barrel
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When - Test different verbs all produce same result

        // Test RAISE
        try await engine.execute("raise barrel")
        let raiseOutput = await mockIO.flush()
        expectNoDifference(
            raiseOutput,
            """
            > raise barrel
            You can’t lift the oak barrel.
            """)

        // Test LIFT
        try await engine.execute("lift barrel")
        let liftOutput = await mockIO.flush()
        expectNoDifference(
            liftOutput,
            """
            > lift barrel
            You can’t lift the oak barrel.
            """)

        // Test HOIST
        try await engine.execute("hoist barrel")
        let hoistOutput = await mockIO.flush()
        expectNoDifference(
            hoistOutput,
            """
            > hoist barrel
            You can’t lift the oak barrel.
            """)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Intents")
    func testIntents() async throws {
        let handler = RaiseActionHandler()
        // RaiseActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = RaiseActionHandler()
        #expect(handler.verbs.contains(.raise))
        #expect(handler.verbs.contains(.lift))
        #expect(handler.verbs.contains(.hoist))
        #expect(handler.verbs.count == 3)
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
