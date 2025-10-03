import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("LookInsideActionHandler Tests")
struct LookInsideActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("LOOK IN DIRECTOBJECT syntax works")
    func testLookInDirectObjectSyntax() async throws {
        // Given
        let box = Item("box")
            .name("wooden box")
            .description("A wooden storage box.")
            .isContainer
            .isOpenable
            .isOpen
            .in(.startRoom)

        let gem = Item("gem")
            .name("sparkling gem")
            .description("A beautiful gem.")
            .in(.item("box"))

        let game = MinimalGame(
            items: box, gem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look in box")

        // Then
        await mockIO.expect(
            """
            > look in box
            In the wooden box you can see a sparkling gem.
            """
        )

        let finalState = await engine.item("box")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("LOOK INSIDE DIRECTOBJECT syntax works")
    func testLookInsideDirectObjectSyntax() async throws {
        // Given
        let chest = Item("chest")
            .name("treasure chest")
            .description("An ornate treasure chest.")
            .isContainer
            .isOpenable
            .isOpen
            .in(.startRoom)

        let game = MinimalGame(
            items: chest
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look inside chest")

        // Then
        await mockIO.expect(
            """
            > look inside chest
            The treasure chest is empty.
            """
        )
    }

    @Test("PEEK syntax works")
    func testPeekSyntax() async throws {
        // Given
        let bag = Item("bag")
            .name("leather bag")
            .description("A worn leather bag.")
            .isContainer
            .isOpenable
            .isOpen
            .in(.startRoom)

        let coin = Item("coin")
            .name("gold coin")
            .description("A shiny gold coin.")
            .in(.item("bag"))

        let game = MinimalGame(
            items: bag, coin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("peek in bag")

        // Then
        await mockIO.expect(
            """
            > peek in bag
            In the leather bag you can see a gold coin.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot look inside without specifying target")
    func testCannotLookInsideWithoutTarget() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look in")

        // Then
        await mockIO.expect(
            """
            > look in
            Look in what?
            """
        )
    }

    @Test("Cannot look inside target not in scope")
    func testCannotLookInsideTargetNotInScope() async throws {
        // Given
        let anotherRoom = Location("anotherRoom")
            .name("Another Room")
            .inherentlyLit

        let remoteContainer = Item("remoteContainer")
            .name("remote container")
            .description("A container in another room.")
            .isContainer
            .in("anotherRoom")

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteContainer
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look in container")

        // Then
        await mockIO.expect(
            """
            > look in container
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Requires light to look inside")
    func testRequiresLight() async throws {
        // Given: Dark room with a container
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")

        let box = Item("box")
            .name("wooden box")
            .description("A wooden storage box.")
            .isContainer
            .in("darkRoom")

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look in box")

        // Then
        await mockIO.expect(
            """
            > look in box
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Look inside open container with items")
    func testLookInsideOpenContainerWithItems() async throws {
        // Given
        let suitcase = Item("suitcase")
            .name("old suitcase")
            .description("A weathered old suitcase.")
            .isContainer
            .isOpenable
            .isOpen
            .in(.startRoom)

        let book = Item("book")
            .name("red book")
            .description("A small red book.")
            .in(.item("suitcase"))

        let pen = Item("pen")
            .name("fountain pen")
            .description("An elegant fountain pen.")
            .in(.item("suitcase"))

        let game = MinimalGame(
            items: suitcase, book, pen
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look inside suitcase")

        // Then
        await mockIO.expect(
            """
            > look inside suitcase
            In the old suitcase you can see a red book and a fountain pen.
            """
        )
    }

    @Test("Look inside empty open container")
    func testLookInsideEmptyOpenContainer() async throws {
        // Given
        let emptyBox = Item("emptyBox")
            .name("empty box")
            .description("A completely empty box.")
            .isContainer
            .isOpenable
            .isOpen
            .in(.startRoom)

        let game = MinimalGame(
            items: emptyBox
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look in box")

        // Then
        await mockIO.expect(
            """
            > look in box
            The empty box is empty.
            """
        )
    }

    @Test("Look inside closed container")
    func testLookInsideClosedContainer() async throws {
        // Given
        let closedTrunk = Item("closedTrunk")
            .name("closed trunk")
            .description("A firmly closed trunk.")
            .isContainer
            .isOpenable
            .in(.startRoom)

        let hiddenItem = Item("hiddenItem")
            .name("hidden item")
            .description("An item hidden in the trunk.")
            .in(.item("closedTrunk"))

        let game = MinimalGame(
            items: closedTrunk, hiddenItem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look inside trunk")

        // Then
        await mockIO.expect(
            """
            > look inside trunk
            The closed trunk is closed.
            """
        )
    }

    @Test("Look inside non-container item")
    func testLookInsideNonContainerItem() async throws {
        // Given
        let statue = Item("statue")
            .name("marble statue")
            .description("A beautiful marble statue of a goddess.")
            .in(.startRoom)

        let game = MinimalGame(
            items: statue
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look inside statue")

        // Then
        await mockIO.expect(
            """
            > look inside statue
            The interior of the marble statue disappoints with its mundane
            emptiness.
            """
        )
    }

    @Test("Look inside non-container with no description")
    func testLookInsideNonContainerWithNoDescription() async throws {
        // Given
        let rock = Item("rock")
            .name("small rock")
            .description("")
            .in(.startRoom)

        let game = MinimalGame(
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look in rock")

        // Then
        await mockIO.expect(
            """
            > look in rock
            The interior of the small rock disappoints with its mundane
            emptiness.
            """
        )
    }

    @Test("Looking inside sets isTouched flag")
    func testLookingInsideSetsTouchedFlag() async throws {
        // Given
        let drawer = Item("drawer")
            .name("desk drawer")
            .description("A wooden desk drawer.")
            .isContainer
            .isOpenable
            .isOpen
            .in(.startRoom)

        let game = MinimalGame(
            items: drawer
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look inside drawer")

        // Then
        let finalState = await engine.item("drawer")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Look inside container with single item")
    func testLookInsideContainerWithSingleItem() async throws {
        // Given
        let bottle = Item("bottle")
            .name("glass bottle")
            .description("A clear glass bottle.")
            .isContainer
            .isOpenable
            .isOpen
            .in(.startRoom)

        let note = Item("note")
            .name("handwritten note")
            .description("A note written in flowing script.")
            .in(.item("bottle"))

        let game = MinimalGame(
            items: bottle, note
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("peek in bottle")

        // Then
        await mockIO.expect(
            """
            > peek in bottle
            In the glass bottle you can see a handwritten note.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = LookInsideActionHandler()
        expectNoDifference(handler.synonyms, [.look, .peek, .peer])
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = LookInsideActionHandler()
        #expect(handler.requiresLight == true)
    }
}
