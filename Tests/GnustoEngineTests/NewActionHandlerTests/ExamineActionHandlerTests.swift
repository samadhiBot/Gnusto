import CustomDump
import Testing

@testable import GnustoEngine

@Suite("ExamineActionHandler Tests")
struct ExamineActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("EXAMINE DIRECTOBJECT syntax works")
    func testExamineDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let book = Item(
            id: "book",
            .name("leather book"),
            .description("A worn leather-bound book with mysterious symbols."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("examine book")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine book
            A worn leather-bound book with mysterious symbols.
            """)

        let finalState = try await engine.item("book")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("X syntax works")
    func testXSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let gem = Item(
            id: "gem",
            .name("sparkling gem"),
            .description("A beautiful gem that catches the light."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: gem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("x gem")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > x gem
            A beautiful gem that catches the light.
            """)

        let finalState = try await engine.item("gem")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("INSPECT syntax works")
    func testInspectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let sword = Item(
            id: "sword",
            .name("steel sword"),
            .description("A sharp steel sword with intricate engravings."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: sword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("inspect sword")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > inspect sword
            A sharp steel sword with intricate engravings.
            """)
    }

    @Test("LOOK AT syntax works")
    func testLookAtSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let painting = Item(
            id: "painting",
            .name("oil painting"),
            .description("A masterful oil painting of a distant landscape."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: painting
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look at painting")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look at painting
            A masterful oil painting of a distant landscape.
            """)
    }

    @Test("EXAMINE ALL syntax works")
    func testExamineAllSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let book = Item(
            id: "book",
            .name("red book"),
            .description("A red leather book."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let candle = Item(
            id: "candle",
            .name("wax candle"),
            .description("A simple wax candle."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: book, candle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("examine all")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine all
            red book: A red leather book.
            wax candle: A simple wax candle.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot examine without specifying what")
    func testCannotExamineWithoutWhat() async throws {
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
        try await engine.execute("examine")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine
            Examine what?
            """)
    }

    @Test("Cannot examine non-existent item")
    func testCannotExamineNonExistentItem() async throws {
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
        try await engine.execute("examine nonexistent")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine nonexistent
            You can't see any such thing.
            """)
    }

    @Test("Cannot examine item not in scope")
    func testCannotExamineItemNotInScope() async throws {
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

        let remoteBook = Item(
            id: "remoteBook",
            .name("remote book"),
            .description("A book in another room."),
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteBook
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("examine book")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine book
            You can't see any such thing.
            """)
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
            .in(.location("darkRoom"))
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
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine book
            It is pitch black. You can't see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Examine self")
    func testExamineSelf() async throws {
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
        try await engine.execute("examine me")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine me
            You look about the same as always.
            """)
    }

    @Test("Examine readable item shows read text")
    func testExamineReadableItemShowsReadText() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let scroll = Item(
            id: "scroll",
            .name("ancient scroll"),
            .description("An ancient parchment scroll."),
            .isReadable,
            .readText("The scroll contains mystical runes and arcane symbols."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: scroll
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("examine scroll")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine scroll
            The scroll contains mystical runes and arcane symbols.
            """)
    }

    @Test("Examine open container shows contents")
    func testExamineOpenContainerShowsContents() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A sturdy wooden box."),
            .isContainer,
            .isOpen,
            .in(.location("testRoom"))
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
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box, gem, coin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("examine box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine box
            A sturdy wooden box. The wooden box is open.

            In the wooden box you can see a ruby gem and a gold coin.
            """)
    }

    @Test("Examine closed container shows closed state")
    func testExamineClosedContainerShowsClosedState() async throws {
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
            // Note: No .isOpen flag - container is closed
            .in(.location("testRoom"))
        )

        let treasure = Item(
            id: "treasure",
            .name("golden treasure"),
            .description("Precious golden treasure."),
            .isTakable,
            .in(.item("chest"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: chest, treasure
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("examine chest")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine chest
            An ornate treasure chest. The treasure chest is closed.
            """)
    }

    @Test("Examine surface shows items on it")
    func testExamineSurfaceShowsItemsOnIt() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let table = Item(
            id: "table",
            .name("oak table"),
            .description("A solid oak table."),
            .isSurface,
            .in(.location("testRoom"))
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
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: table, book, candle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("examine table")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine table
            A solid oak table.

            On the oak table you can see a leather book and a wax candle.
            """)
    }

    @Test("Examine empty container")
    func testExamineEmptyContainer() async throws {
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
            .isOpen,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: bag
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("examine bag")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine bag
            A worn leather bag. The leather bag is open.

            The leather bag is empty.
            """)
    }

    @Test("Examine empty surface")
    func testExamineEmptySurface() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let desk = Item(
            id: "desk",
            .name("wooden desk"),
            .description("A simple wooden desk."),
            .isSurface,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: desk
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("examine desk")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine desk
            A simple wooden desk.

            There is nothing on the wooden desk.
            """)
    }

    @Test("Examine door shows door state")
    func testExamineDoorShowsDoorState() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let door = Item(
            id: "door",
            .name("oak door"),
            .description("A heavy oak door."),
            .isDoor,
            .isOpen,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: door
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("examine door")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine door
            A heavy oak door. The oak door is open.
            """)
    }

    @Test("Updates pronouns to refer to examined item")
    func testUpdatesPronounsToExaminedItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let book = Item(
            id: "book",
            .name("leather book"),
            .description("A worn leather book."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("examine book")
        try await engine.execute("take it")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine book
            A worn leather book.
            > take it
            Taken.
            """)

        let finalState = try await engine.item("book")
        #expect(finalState.parent == .player)
    }

    @Test("EXAMINE ALL with nothing to examine")
    func testExamineAllWithNothingToExamine() async throws {
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
        try await engine.execute("examine all")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine all
            There is nothing here to examine.
            """)
    }

    @Test("Examine IN preposition delegates to look inside")
    func testExamineInDelegatesToLookInside() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A wooden box."),
            .isContainer,
            .isOpen,
            .in(.location("testRoom"))
        )

        let gem = Item(
            id: "gem",
            .name("ruby gem"),
            .description("A precious ruby."),
            .isTakable,
            .in(.item("box"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box, gem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("examine in box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine in box
            In the wooden box you can see a ruby gem.
            """)
    }

    @Test("Examine ON preposition delegates to look inside")
    func testExamineOnDelegatesToLookInside() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let table = Item(
            id: "table",
            .name("wooden table"),
            .description("A wooden table."),
            .isSurface,
            .in(.location("testRoom"))
        )

        let book = Item(
            id: "book",
            .name("red book"),
            .description("A red book."),
            .isTakable,
            .in(.item("table"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: table, book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("examine on table")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine on table
            On the wooden table you can see a red book.
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = ExamineActionHandler()
        // ExamineActionHandler doesn't specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = ExamineActionHandler()
        #expect(handler.verbs.contains(.examine))
        #expect(handler.verbs.contains("x"))
        #expect(handler.verbs.contains(.inspect))
        #expect(handler.verbs.count == 3)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = ExamineActionHandler()
        #expect(handler.requiresLight == true)
    }
}
