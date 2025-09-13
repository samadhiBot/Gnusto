import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("TakeActionHandler Tests")
struct TakeActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("TAKE DIRECTOBJECT syntax works")
    func testTakeDirectObjectSyntax() async throws {
        // Given
        let book = Item(
            id: "book",
            .name("leather book"),
            .description("A worn leather-bound book."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
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
            """
        )

        let finalState = try await engine.item("book")
        #expect(try await finalState.playerIsHolding)
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("GET syntax works")
    func testGetSyntax() async throws {
        // Given
        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .description("A shiny gold coin."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
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
            """
        )

        let finalState = try await engine.item("coin")
        #expect(try await finalState.playerIsHolding)
    }

    @Test("GRAB syntax works")
    func testGrabSyntax() async throws {
        // Given
        let key = Item(
            id: "key",
            .name("brass key"),
            .description("A small brass key."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
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
            """
        )

        let finalState = try await engine.item("key")
        #expect(try await finalState.playerIsHolding)
    }

    @Test("STEAL syntax works")
    func testStealSyntax() async throws {
        // Given
        let gem = Item(
            id: "gem",
            .name("sparkling gem"),
            .description("A beautiful sparkling gem."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
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
            """
        )

        let finalState = try await engine.item("gem")
        #expect(try await finalState.playerIsHolding)
    }

    @Test("PICK UP syntax works")
    func testPickUpSyntax() async throws {
        // Given
        let feather = Item(
            id: "feather",
            .name("white feather"),
            .description("A delicate white feather."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
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
            """
        )

        let finalState = try await engine.item("feather")
        #expect(try await finalState.playerIsHolding)
    }

    @Test("TAKE DIRECTOBJECT FROM INDIRECTOBJECT syntax works")
    func testTakeFromContainerSyntax() async throws {
        // Given
        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A sturdy wooden box."),
            .isContainer,
            .isOpen,
            .in(.startRoom)
        )

        let ring = Item(
            id: "ring",
            .name("silver ring"),
            .description("A beautiful silver ring."),
            .isTakable,
            .in(.item("box"))
        )

        let game = MinimalGame(
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
            """
        )

        let finalState = try await engine.item("ring")
        #expect(try await finalState.playerIsHolding)
    }

    @Test("TAKE ALL syntax works")
    func testTakeAllSyntax() async throws {
        // Given
        let book = Item(
            id: "book",
            .name("red book"),
            .description("A red book."),
            .isTakable,
            .in(.startRoom)
        )

        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .description("A gold coin."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
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
            You take the red book and the gold coin.
            """
        )

        let finalBook = try await engine.item("book")
        let finalCoin = try await engine.item("coin")
        #expect(try await finalBook.playerIsHolding)
        #expect(try await finalCoin.playerIsHolding)
    }

    // MARK: - Validation Testing

    @Test("Cannot take without specifying what")
    func testCannotTakeWithoutWhat() async throws {
        // Given
        let game = MinimalGame()
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
            """
        )
    }

    @Test("Cannot take non-existent item")
    func testCannotTakeNonExistentItem() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take nonexistent")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take nonexistent
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot take item not in scope")
    func testCannotTakeItemNotInScope() async throws {
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
            .isTakable,
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
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
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot take non-takable item")
    func testCannotTakeNonTakableItem() async throws {
        // Given
        let statue = Item(
            id: "statue",
            .name("stone statue"),
            .description("A heavy stone statue."),
            // Note: No .isTakable flag
            .in(.startRoom)
        )

        let game = MinimalGame(
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
            The stone statue stubbornly resists your attempts to take it.
            """
        )
    }

    @Test("Cannot take item already held")
    func testCannotTakeItemAlreadyHeld() async throws {
        // Given
        let book = Item(
            id: "book",
            .name("leather book"),
            .description("A worn leather book."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
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
            That already resides among your possessions.
            """
        )
    }

    @Test("Cannot take from closed container")
    func testCannotTakeFromClosedContainer() async throws {
        // Given
        let chest = Item(
            id: "chest",
            .name("wooden chest"),
            .description("A sturdy wooden chest."),
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
        try await engine.execute("take treasure")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take treasure
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot take from transparent closed container if item is touched")
    func testCannotTakeFromTransparentClosedContainer() async throws {
        // Given
        let jar = Item(
            id: "jar",
            .name("glass jar"),
            .description("A transparent glass jar."),
            .isContainer,
            .isTransparent,
            // Note: No .isOpen flag - container is closed but transparent
            .in(.startRoom)
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
            """
        )
    }

    @Test("Can take item from non-container")
    func testCanTakeItemFromNonContainer() async throws {
        // Given
        let rock = Item(
            id: "rock",
            .name("large rock"),
            .description("A large boulder."),
            // Note: Not a container or surface
            .in(.startRoom)
        )

        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .firstDescription("A gold coin lodged in the rock."),
            .isTakable,
            .in(.item("rock"))
        )

        let game = MinimalGame(
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
            Taken.
            """
        )
    }

    @Test("Cannot take from wrong container when using FROM syntax")
    func testCannotTakeFromWrongContainer() async throws {
        // Given
        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A wooden box."),
            .isContainer,
            .isOpen,
            .in(.startRoom)
        )

        let bag = Item(
            id: "bag",
            .name("leather bag"),
            .description("A leather bag."),
            .isContainer,
            .isOpen,
            .in(.startRoom)
        )

        let ring = Item(
            id: "ring",
            .name("silver ring"),
            .description("A silver ring."),
            .isTakable,
            .in(.item("box"))
        )

        let game = MinimalGame(
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
            The silver ring is not in the leather bag.
            """
        )
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
            .in("darkRoom")
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
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Take item from open container")
    func testTakeItemFromOpenContainer() async throws {
        // Given
        let cabinet = Item(
            id: "cabinet",
            .name("oak cabinet"),
            .description("A sturdy oak cabinet."),
            .isContainer,
            .isOpen,
            .in(.startRoom)
        )

        let vase = Item(
            id: "vase",
            .name("ceramic vase"),
            .description("A delicate ceramic vase."),
            .isTakable,
            .in(.item("cabinet"))
        )

        let game = MinimalGame(
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
            """
        )

        let finalState = try await engine.item("vase")
        #expect(try await finalState.playerIsHolding)
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Take item from surface")
    func testTakeItemFromSurface() async throws {
        // Given
        let table = Item(
            id: "table",
            .name("wooden table"),
            .description("A sturdy wooden table."),
            .isSurface,
            .in(.startRoom)
        )

        let candle = Item(
            id: "candle",
            .name("wax candle"),
            .description("A simple wax candle."),
            .isTakable,
            .in(.item("table"))
        )

        let game = MinimalGame(
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
            """
        )

        let finalState = try await engine.item("candle")
        #expect(try await finalState.playerIsHolding)
    }

    @Test("Take multiple items with TAKE ALL")
    func testTakeMultipleItemsWithTakeAll() async throws {
        // Given
        let book = Item(
            id: "book",
            .name("red book"),
            .description("A red book."),
            .isTakable,
            .in(.startRoom)
        )

        let pen = Item(
            id: "pen",
            .name("blue pen"),
            .description("A blue pen."),
            .isTakable,
            .in(.startRoom)
        )

        let statue = Item(
            id: "statue",
            .name("stone statue"),
            .description("A heavy statue."),
            // Note: Not takable
            .in(.startRoom)
        )

        let game = MinimalGame(
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
            You take the red book and the blue pen.
            """
        )

        let finalBook = try await engine.item("book")
        let finalPen = try await engine.item("pen")
        let finalStatue = try await engine.item("statue")
        let startRoom = try await engine.location(.startRoom)

        #expect(try await finalBook.playerIsHolding)
        #expect(try await finalPen.playerIsHolding)
        #expect(try await finalStatue.parent == .location(startRoom))  // Statue not taken
    }

    @Test("TAKE ALL with nothing takable")
    func testTakeAllWithNothingTakable() async throws {
        // Given
        let statue = Item(
            id: "statue",
            .name("stone statue"),
            .description("A heavy statue."),
            // Note: Not takable
            .in(.startRoom)
        )

        let game = MinimalGame(
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
            Take what?
            """
        )
    }

    @Test("TAKE ALL skips items already held")
    func testTakeAllSkipsItemsAlreadyHeld() async throws {
        // Given
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
            .in(.startRoom)
        )

        let game = MinimalGame(
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
            You take the blue pen.
            """
        )

        let finalPen = try await engine.item("pen")
        #expect(try await finalPen.playerIsHolding)
    }

    @Test("Updates pronouns to refer to taken item")
    func testUpdatesPronounsToTakenItem() async throws {
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
            """
        )
    }

    // MARK: - Get All issue test

    @Test("Get all should not show 'all all' error")
    func testGetAllShouldNotShowAllAllError() async throws {
        // Arrange: Set up a basic game with some takable items
        let basket = Item(
            id: "basket",
            .name("wicker basket"),
            .in(.startRoom),
            .isTakable,
            .size(5)
        )
        let jug = Item(
            id: "jug",
            .name("lemonade jug"),
            .in(.startRoom),
            .isTakable,
            .size(3)
        )

        let (engine, _) = await GameEngine.test(
            blueprint: MinimalGame(
                player: Player(in: .startRoom, characterSheet: .weak),
                items: basket, jug
            )
        )

        // Act: Parse "get all" directly
        let result = try await engine.parser.parse(
            input: "get all",
            vocabulary: engine.vocabulary,
            engine: engine
        )

        let basketProxy = try await basket.proxy(engine)
        let jugProxy = try await jug.proxy(engine)

        expectNoDifference(
            result,
            .success(
                Command(
                    verb: .get,
                    directObjects: [
                        .item(basketProxy),
                        .item(jugProxy),
                    ],
                    isAllCommand: true,
                    rawInput: "get all"
                )
            )
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = TakeActionHandler()
        #expect(handler.synonyms.contains(.take))
        #expect(handler.synonyms.contains(.get))
        #expect(handler.synonyms.contains(.grab))
        #expect(handler.synonyms.contains(.steal))
        #expect(handler.synonyms.count == 4)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = TakeActionHandler()
        #expect(handler.requiresLight == true)
    }
}
