import Testing
import CustomDump
@testable import GnustoEngine

@Suite("LookInsideActionHandler Tests")
struct LookInsideActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("LOOK IN DIRECTOBJECT syntax works")
    func testLookInDirectObjectSyntax() async throws {
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
            .description("A wooden storage box."),
            .isContainer,
            .isOpenable,
            .isOpen,
            .in(.location("testRoom"))
        )

        let gem = Item(
            id: "gem",
            .name("sparkling gem"),
            .description("A beautiful gem."),
            .in(.item("box"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box, gem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look in box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > look in box
            In the wooden box you see a sparkling gem.
            """)

        let finalState = try await engine.item("box")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("LOOK INSIDE DIRECTOBJECT syntax works")
    func testLookInsideDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let chest = Item(
            id: "chest",
            .name("treasure chest"),
            .description("An ornate treasure chest."),
            .isContainer,
            .isOpenable,
            .isOpen,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: chest
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look inside chest")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > look inside chest
            The treasure chest is empty.
            """)
    }

    @Test("PEEK syntax works")
    func testPeekSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let bag = Item(
            id: "bag",
            .name("leather bag"),
            .description("A worn leather bag."),
            .isContainer,
            .isOpenable,
            .isOpen,
            .in(.location("testRoom"))
        )

        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .description("A shiny gold coin."),
            .in(.item("bag"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: bag, coin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("peek in bag")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > peek in bag
            In the leather bag you see a gold coin.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot look inside without specifying target")
    func testCannotLookInsideWithoutTarget() async throws {
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
        try await engine.execute("look in")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > look in
            Look in what?
            """)
    }

    @Test("Cannot look inside target not in scope")
    func testCannotLookInsideTargetNotInScope() async throws {
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

        let remoteContainer = Item(
            id: "remoteContainer",
            .name("remote container"),
            .description("A container in another room."),
            .isContainer,
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteContainer
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look in container")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > look in container
            You can’t see any such thing.
            """)
    }

    @Test("Requires light to look inside")
    func testRequiresLight() async throws {
        // Given: Dark room with a container
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A wooden storage box."),
            .isContainer,
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look in box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > look in box
            It is pitch black. You can’t see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Look inside open container with items")
    func testLookInsideOpenContainerWithItems() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let suitcase = Item(
            id: "suitcase",
            .name("old suitcase"),
            .description("A weathered old suitcase."),
            .isContainer,
            .isOpenable,
            .isOpen,
            .in(.location("testRoom"))
        )

        let book = Item(
            id: "book",
            .name("red book"),
            .description("A small red book."),
            .in(.item("suitcase"))
        )

        let pen = Item(
            id: "pen",
            .name("fountain pen"),
            .description("An elegant fountain pen."),
            .in(.item("suitcase"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: suitcase, book, pen
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look inside suitcase")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > look inside suitcase
            In the old suitcase you see a fountain pen and a red book.
            """)
    }

    @Test("Look inside empty open container")
    func testLookInsideEmptyOpenContainer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let emptyBox = Item(
            id: "emptyBox",
            .name("empty box"),
            .description("A completely empty box."),
            .isContainer,
            .isOpenable,
            .isOpen,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: emptyBox
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look in box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > look in box
            The empty box is empty.
            """)
    }

    @Test("Look inside closed container")
    func testLookInsideClosedContainer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let closedTrunk = Item(
            id: "closedTrunk",
            .name("closed trunk"),
            .description("A firmly closed trunk."),
            .isContainer,
            .isOpenable,
            .in(.location("testRoom"))
        )

        let hiddenItem = Item(
            id: "hiddenItem",
            .name("hidden item"),
            .description("An item hidden in the trunk."),
            .in(.item("closedTrunk"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: closedTrunk, hiddenItem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look inside trunk")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > look inside trunk
            The closed trunk is closed.
            """)
    }

    @Test("Look inside non-container item")
    func testLookInsideNonContainerItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let statue = Item(
            id: "statue",
            .name("marble statue"),
            .description("A beautiful marble statue of a goddess."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: statue
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look inside statue")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > look inside statue
            A beautiful marble statue of a goddess.
            """)
    }

    @Test("Look inside non-container with no description")
    func testLookInsideNonContainerWithNoDescription() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rock = Item(
            id: "rock",
            .name("small rock"),
            .description(""),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look in rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > look in rock
            You see nothing special inside the small rock.
            """)
    }

    @Test("Looking inside sets isTouched flag")
    func testLookingInsideSetsTouchedFlag() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let drawer = Item(
            id: "drawer",
            .name("desk drawer"),
            .description("A wooden desk drawer."),
            .isContainer,
            .isOpenable,
            .isOpen,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: drawer
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look inside drawer")

        // Then
        let finalState = try await engine.item("drawer")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Look inside container with single item")
    func testLookInsideContainerWithSingleItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let bottle = Item(
            id: "bottle",
            .name("glass bottle"),
            .description("A clear glass bottle."),
            .isContainer,
            .isOpenable,
            .isOpen,
            .in(.location("testRoom"))
        )

        let note = Item(
            id: "note",
            .name("handwritten note"),
            .description("A note written in flowing script."),
            .in(.item("bottle"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: bottle, note
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("peek in bottle")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > peek in bottle
            In the glass bottle you see a handwritten note.
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = LookInsideActionHandler()
        // LookInsideActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = LookInsideActionHandler()
        #expect(handler.verbs.contains(.look))
        #expect(handler.verbs.contains(.peek))
        #expect(handler.verbs.count == 2)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = LookInsideActionHandler()
        #expect(handler.requiresLight == true)
    }
}
