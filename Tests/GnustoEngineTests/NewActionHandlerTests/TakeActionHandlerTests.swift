import CustomDump
import Testing

@testable import GnustoEngine

@Suite("TakeActionHandler Tests")
struct TakeActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("TAKE DIRECTOBJECT syntax works")
    func testTakeDirectObjectSyntax() async throws {
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
            .description("A worn leather-bound book."),
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
        try await engine.execute("take book")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take book
            Taken.
            """)

        let finalState = try await engine.item("book")
        #expect(finalState.parent == .player)
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("GET syntax works")
    func testGetSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .description("A shiny gold coin."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: coin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("get coin")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > get coin
            Taken.
            """)

        let finalState = try await engine.item("coin")
        #expect(finalState.parent == .player)
    }

    @Test("GRAB syntax works")
    func testGrabSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let key = Item(
            id: "key",
            .name("brass key"),
            .description("A small brass key."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("grab key")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > grab key
            Taken.
            """)

        let finalState = try await engine.item("key")
        #expect(finalState.parent == .player)
    }

    @Test("STEAL syntax works")
    func testStealSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let gem = Item(
            id: "gem",
            .name("sparkling gem"),
            .description("A beautiful sparkling gem."),
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
        try await engine.execute("steal gem")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > steal gem
            Taken.
            """)

        let finalState = try await engine.item("gem")
        #expect(finalState.parent == .player)
    }

    @Test("PICK UP syntax works")
    func testPickUpSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let feather = Item(
            id: "feather",
            .name("white feather"),
            .description("A delicate white feather."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: feather
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pick up feather")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > pick up feather
            Taken.
            """)

        let finalState = try await engine.item("feather")
        #expect(finalState.parent == .player)
    }

    @Test("TAKE DIRECTOBJECT FROM INDIRECTOBJECT syntax works")
    func testTakeFromContainerSyntax() async throws {
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

        let ring = Item(
            id: "ring",
            .name("silver ring"),
            .description("A beautiful silver ring."),
            .isTakable,
            .in(.item("box"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box, ring
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take ring from box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take ring from box
            Taken.
            """)

        let finalState = try await engine.item("ring")
        #expect(finalState.parent == .player)
    }

    @Test("TAKE ALL syntax works")
    func testTakeAllSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let book = Item(
            id: "book",
            .name("red book"),
            .description("A red book."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .description("A gold coin."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: book, coin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take all")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take all
            red book: Taken.
            gold coin: Taken.
            """)

        let finalBook = try await engine.item("book")
        let finalCoin = try await engine.item("coin")
        #expect(finalBook.parent == .player)
        #expect(finalCoin.parent == .player)
    }

    // MARK: - Validation Testing

    @Test("Cannot take without specifying what")
    func testCannotTakeWithoutWhat() async throws {
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
        try await engine.execute("take")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take
            Take what?
            """)
    }

    @Test("Cannot take non-existent item")
    func testCannotTakeNonExistentItem() async throws {
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
        try await engine.execute("take nonexistent")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take nonexistent
            You can't see any such thing.
            """)
    }

    @Test("Cannot take item not in scope")
    func testCannotTakeItemNotInScope() async throws {
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
            .isTakable,
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteBook
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take book")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take book
            You can't see any such thing.
            """)
    }

    @Test("Cannot take non-takable item")
    func testCannotTakeNonTakableItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let statue = Item(
            id: "statue",
            .name("stone statue"),
            .description("A heavy stone statue."),
            // Note: No .isTakable flag
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: statue
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take statue")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take statue
            You can't take the stone statue.
            """)
    }

    @Test("Cannot take item already held")
    func testCannotTakeItemAlreadyHeld() async throws {
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
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take book")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take book
            You already have that.
            """)
    }

    @Test("Cannot take from closed container")
    func testCannotTakeFromClosedContainer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let chest = Item(
            id: "chest",
            .name("wooden chest"),
            .description("A sturdy wooden chest."),
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
        try await engine.execute("take treasure")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take treasure
            You can't see any such thing.
            """)
    }

    @Test("Cannot take from transparent closed container if item is touched")
    func testCannotTakeFromTransparentClosedContainer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let jar = Item(
            id: "jar",
            .name("glass jar"),
            .description("A transparent glass jar."),
            .isContainer,
            .isTransparent,
            // Note: No .isOpen flag - container is closed but transparent
            .in(.location("testRoom"))
        )

        let marble = Item(
            id: "marble",
            .name("blue marble"),
            .description("A beautiful blue marble."),
            .isTakable,
            .isTouched,  // Player knows this item exists
            .in(.item("jar"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: jar, marble
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take marble")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take marble
            The glass jar is closed.
            """)
    }

    @Test("Cannot take item from non-container")
    func testCannotTakeItemFromNonContainer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rock = Item(
            id: "rock",
            .name("large rock"),
            .description("A large boulder."),
            // Note: Not a container or surface
            .in(.location("testRoom"))
        )

        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .description("A gold coin somehow inside the rock."),
            .isTakable,
            .in(.item("rock"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rock, coin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take coin")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take coin
            You can't take anything from the large rock.
            """)
    }

    @Test("Cannot take from wrong container when using FROM syntax")
    func testCannotTakeFromWrongContainer() async throws {
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

        let bag = Item(
            id: "bag",
            .name("leather bag"),
            .description("A leather bag."),
            .isContainer,
            .isOpen,
            .in(.location("testRoom"))
        )

        let ring = Item(
            id: "ring",
            .name("silver ring"),
            .description("A silver ring."),
            .isTakable,
            .in(.item("box"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box, bag, ring
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take ring from bag")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take ring from bag
            The silver ring isn't in the leather bag.
            """)
    }

    @Test("Requires light to take items")
    func testRequiresLight() async throws {
        // Given: Dark room with takable item
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
            .isTakable,
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take book")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take book
            It is pitch black. You can't see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Take item from open container")
    func testTakeItemFromOpenContainer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let cabinet = Item(
            id: "cabinet",
            .name("oak cabinet"),
            .description("A sturdy oak cabinet."),
            .isContainer,
            .isOpen,
            .in(.location("testRoom"))
        )

        let vase = Item(
            id: "vase",
            .name("ceramic vase"),
            .description("A delicate ceramic vase."),
            .isTakable,
            .in(.item("cabinet"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: cabinet, vase
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take vase")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take vase
            Taken.
            """)

        let finalState = try await engine.item("vase")
        #expect(finalState.parent == .player)
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Take item from surface")
    func testTakeItemFromSurface() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let table = Item(
            id: "table",
            .name("wooden table"),
            .description("A sturdy wooden table."),
            .isSurface,
            .in(.location("testRoom"))
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
            items: table, candle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take candle")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take candle
            Taken.
            """)

        let finalState = try await engine.item("candle")
        #expect(finalState.parent == .player)
    }

    @Test("Take multiple items with TAKE ALL")
    func testTakeMultipleItemsWithTakeAll() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let book = Item(
            id: "book",
            .name("red book"),
            .description("A red book."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let pen = Item(
            id: "pen",
            .name("blue pen"),
            .description("A blue pen."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let statue = Item(
            id: "statue",
            .name("stone statue"),
            .description("A heavy statue."),
            // Note: Not takable
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: book, pen, statue
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take all")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take all
            red book: Taken.
            blue pen: Taken.
            """)

        let finalBook = try await engine.item("book")
        let finalPen = try await engine.item("pen")
        let finalStatue = try await engine.item("statue")

        #expect(finalBook.parent == .player)
        #expect(finalPen.parent == .player)
        #expect(finalStatue.parent == .location("testRoom"))  // Statue not taken
    }

    @Test("TAKE ALL with nothing takable")
    func testTakeAllWithNothingTakable() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let statue = Item(
            id: "statue",
            .name("stone statue"),
            .description("A heavy statue."),
            // Note: Not takable
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: statue
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take all")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take all
            There is nothing here to take.
            """)
    }

    @Test("TAKE ALL skips items already held")
    func testTakeAllSkipsItemsAlreadyHeld() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let book = Item(
            id: "book",
            .name("red book"),
            .description("A red book."),
            .isTakable,
            .in(.player)  // Already held
        )

        let pen = Item(
            id: "pen",
            .name("blue pen"),
            .description("A blue pen."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: book, pen
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take all")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take all
            blue pen: Taken.
            """)

        let finalPen = try await engine.item("pen")
        #expect(finalPen.parent == .player)
    }

    @Test("Updates pronouns to refer to taken item")
    func testUpdatesPronounsToTakenItem() async throws {
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
        try await engine.execute("take book")
        try await engine.execute("examine it")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take book
            Taken.
            > examine it
            A worn leather book.
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = TakeActionHandler()
        #expect(handler.actions.contains(.take))
        #expect(handler.actions.count == 1)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = TakeActionHandler()
        #expect(handler.verbs.contains(.take))
        #expect(handler.verbs.contains(.get))
        #expect(handler.verbs.contains(.grab))
        #expect(handler.verbs.contains(.steal))
        #expect(handler.verbs.count == 4)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = TakeActionHandler()
        #expect(handler.requiresLight == true)
    }
}
