import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("ExamineActionHandler Tests")
struct ExamineActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("EXAMINE DIRECTOBJECT syntax works")
    func testExamineDirectObjectSyntax() async throws {
        // Given
        let book = Item(
            id: "book",
            .name("leather book"),
            .description("A worn leather-bound book with mysterious symbols."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("examine book")

        // Then
        await mockIO.expectOutput(
            """
            > examine book
            A worn leather-bound book with mysterious symbols.
            """
        )

        let finalState = await engine.item("book")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("X syntax works")
    func testXSyntax() async throws {
        // Given
        let gem = Item(
            id: "gem",
            .name("sparkling gem"),
            .description("A beautiful gem that catches the light."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: gem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("x gem")

        // Then
        await mockIO.expectOutput(
            """
            > x gem
            A beautiful gem that catches the light.
            """
        )

        let finalState = await engine.item("gem")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("INSPECT syntax works")
    func testInspectSyntax() async throws {
        // Given
        let sword = Item(
            id: "sword",
            .name("steel sword"),
            .description("A sharp steel sword with intricate engravings."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: sword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("inspect sword")

        // Then
        await mockIO.expectOutput(
            """
            > inspect sword
            A sharp steel sword with intricate engravings.
            """
        )
    }

    @Test("Describe syntax works")
    func testDescribeSyntax() async throws {
        // Given
        let ruby = Item(
            id: "ruby",
            .name("sparkling ruby"),
            .description("A beautiful ruby that catches the light."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: ruby
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("describe the ruby")

        // Then
        await mockIO.expectOutput(
            """
            > describe the ruby
            A beautiful ruby that catches the light.
            """
        )

        let finalState = await engine.item("ruby")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("LOOK AT syntax works")
    func testLookAtSyntax() async throws {
        // Given
        let painting = Item(
            id: "painting",
            .name("oil painting"),
            .description("A masterful oil painting of a distant landscape."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: painting
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look at painting")

        // Then
        await mockIO.expectOutput(
            """
            > look at painting
            A masterful oil painting of a distant landscape.
            """
        )
    }

    @Test("EXAMINE ALL syntax works")
    func testExamineAllSyntax() async throws {
        // Given
        let book = Item(
            id: "book",
            .name("red book"),
            .description("A red leather book."),
            .isTakable,
            .in(.startRoom)
        )

        let candle = Item(
            id: "candle",
            .name("wax candle"),
            .description("A simple wax candle."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: book, candle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("examine all")

        // Then
        await mockIO.expectOutput(
            """
            > examine all
            - Red book: A red leather book.
            - Wax candle: A simple wax candle.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot examine without specifying what")
    func testCannotExamineWithoutWhat() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("examine")

        // Then
        await mockIO.expectOutput(
            """
            > examine
            Examine what?
            """
        )
    }

    @Test("Cannot examine non-existent item")
    func testCannotExamineNonExistentItem() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("examine nonexistent")

        // Then
        await mockIO.expectOutput(
            """
            > examine nonexistent
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot examine item not in scope")
    func testCannotExamineItemNotInScope() async throws {
        // Given
        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let remoteBook = Item(
            id: "remoteBook",
            .name("remote book"),
            .description("A book in another room."),
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteBook
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("examine book")

        // Then
        await mockIO.expectOutput(
            """
            > examine book
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Requires light to examine items")
    func testRequiresLight() async throws {
        // Given: Dark room with item
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let book = Item(
            id: "book",
            .name("leather book"),
            .description("A worn leather book."),
            .in("darkRoom")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("examine book")

        // Then
        await mockIO.expectOutput(
            """
            > examine book
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Examine self")
    func testExamineSelf() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("examine me")

        // Then
        await mockIO.expectOutput(
            """
            > examine me
            As good-looking as ever, which is to say, adequately
            presentable.
            """
        )
    }

    @Test("Examine readable item")
    func testExamineReadableItem() async throws {
        // Given
        let scroll = Item(
            id: "scroll",
            .name("ancient scroll"),
            .description("An ancient parchment scroll."),
            .isReadable,
            .readText("The scroll contains mystical runes and arcane symbols."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: scroll
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute(
            "examine scroll",
            "read it"
        )

        // Then
        await mockIO.expectOutput(
            """
            > examine scroll
            An ancient parchment scroll.

            > read it
            The scroll contains mystical runes and arcane symbols.
            """
        )
    }

    @Test("Examine open container shows contents")
    func testExamineOpenContainerShowsContents() async throws {
        // Given
        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A sturdy wooden box."),
            .isContainer,
            .isOpen,
            .in(.startRoom)
        )

        let gem = Item(
            id: "gem",
            .name("ruby gem"),
            .description("A precious ruby gem."),
            .isTakable,
            .in(.item("box"))
        )

        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .description("A shiny gold coin."),
            .isTakable,
            .in(.item("box"))
        )

        let game = MinimalGame(
            items: box, gem, coin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("examine box")

        // Then
        await mockIO.expectOutput(
            """
            > examine box
            A sturdy wooden box. In the wooden box you can see a gold coin
            and a ruby gem.
            """
        )
    }

    @Test("Examine closed container shows closed state")
    func testExamineClosedContainerShowsClosedState() async throws {
        // Given
        let chest = Item(
            id: "chest",
            .name("treasure chest"),
            .description("An ornate treasure chest."),
            .isContainer,
            // Note: No .isOpen flag - container is closed
            .in(.startRoom)
        )

        let treasure = Item(
            id: "treasure",
            .name("golden treasure"),
            .description("Precious golden treasure."),
            .isTakable,
            .in(.item("chest"))
        )

        let game = MinimalGame(
            items: chest, treasure
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("examine chest")

        // Then
        await mockIO.expectOutput(
            """
            > examine chest
            An ornate treasure chest. The treasure chest is closed.
            """
        )
    }

    @Test("Examine surface shows items on it")
    func testExamineSurfaceShowsItemsOnIt() async throws {
        // Given
        let table = Item(
            id: "table",
            .name("oak table"),
            .description("A solid oak table."),
            .isSurface,
            .in(.startRoom)
        )

        let book = Item(
            id: "book",
            .name("leather book"),
            .description("A leather-bound book."),
            .isTakable,
            .in(.item("table"))
        )

        let candle = Item(
            id: "candle",
            .name("wax candle"),
            .description("A simple wax candle."),
            .isTakable,
            .in(.item("table"))
        )

        let game = MinimalGame(
            items: table, book, candle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("examine table")

        // Then
        await mockIO.expectOutput(
            """
            > examine table
            A solid oak table. On the oak table you can see a leather book
            and a wax candle.
            """
        )
    }

    @Test("Examine empty container")
    func testExamineEmptyContainer() async throws {
        // Given
        let bag = Item(
            id: "bag",
            .name("leather bag"),
            .description("A worn leather bag."),
            .isContainer,
            .isOpen,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: bag
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("examine bag")

        // Then
        await mockIO.expectOutput(
            """
            > examine bag
            A worn leather bag. The leather bag is empty.
            """
        )
    }

    @Test("Examine empty surface")
    func testExamineEmptySurface() async throws {
        // Given
        let desk = Item(
            id: "desk",
            .name("wooden desk"),
            .description("A simple wooden desk."),
            .isSurface,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: desk
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("examine desk")

        // Then
        await mockIO.expectOutput(
            """
            > examine desk
            A simple wooden desk.
            """
        )
    }

    @Test("Examine door shows door state")
    func testExamineDoorShowsDoorState() async throws {
        // Given
        let door = Item(
            id: "door",
            .name("oak door"),
            .description("A heavy oak door."),
            .isOpen,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: door
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("examine door")

        // Then
        await mockIO.expectOutput(
            """
            > examine door
            A heavy oak door. The oak door is open.
            """
        )
    }

    @Test("Updates pronouns to refer to examined item")
    func testUpdatesPronounsToExaminedItem() async throws {
        // Given
        let book = Item(
            id: "book",
            .name("leather book"),
            .description("A worn leather book."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute(
            "examine book",
            "take it"
        )

        // Then
        await mockIO.expectOutput(
            """
            > examine book
            A worn leather book.

            > take it
            Taken.
            """
        )

        let finalState = await engine.item("book")
        #expect(await finalState.playerIsHolding)
    }

    @Test("EXAMINE ALL with nothing to examine")
    func testExamineAllWithNothingToExamine() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("examine all")

        // Then
        await mockIO.expectOutput(
            """
            > examine all
            There is nothing here to examine.
            """
        )
    }

    @Test("Examine IN preposition delegates to look inside")
    func testExamineInDelegatesToLookInside() async throws {
        // Given
        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A wooden box."),
            .isContainer,
            .isOpen,
            .in(.startRoom)
        )

        let gem = Item(
            id: "gem",
            .name("ruby gem"),
            .description("A precious ruby."),
            .isTakable,
            .in(.item("box"))
        )

        let game = MinimalGame(
            items: box, gem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look in box")

        // Then
        await mockIO.expectOutput(
            """
            > look in box
            In the wooden box you can see a ruby gem.
            """
        )
    }

    @Test("Examine ON preposition delegates to look inside")
    func testExamineOnDelegatesToLookInside() async throws {
        // Given
        let table = Item(
            id: "table",
            .name("wooden table"),
            .description("A wooden table."),
            .isSurface,
            .in(.startRoom)
        )

        let book = Item(
            id: "book",
            .name("red book"),
            .description("A red book."),
            .isTakable,
            .in(.item("table"))
        )

        let game = MinimalGame(
            items: table, book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look on table")

        // Then
        await mockIO.expectOutput(
            """
            > look on table
            A wooden table. On the wooden table you can see a red book.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = ExamineActionHandler()
        expectNoDifference(
            handler.synonyms,
            [.examine, "x", .inspect, .describe, .look, "l"]
        )
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = ExamineActionHandler()
        #expect(handler.requiresLight == true)
    }
}
