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
        let book = Item("book")
            .name("leather book")
            .description("A worn leather-bound book.")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take book")

        // Then
        await mockIO.expectOutput(
            """
            > take book
            Taken.
            """
        )

        let finalState = await engine.item("book")
        #expect(await finalState.playerIsHolding)
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("GET syntax works")
    func testGetSyntax() async throws {
        // Given
        let coin = Item("coin")
            .name("gold coin")
            .description("A shiny gold coin.")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: coin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("get coin")

        // Then
        await mockIO.expectOutput(
            """
            > get coin
            Taken.
            """
        )

        let finalState = await engine.item("coin")
        #expect(await finalState.playerIsHolding)
    }

    @Test("GRAB syntax works")
    func testGrabSyntax() async throws {
        // Given
        let key = Item("key")
            .name("brass key")
            .description("A small brass key.")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("grab key")

        // Then
        await mockIO.expectOutput(
            """
            > grab key
            Taken.
            """
        )

        let finalState = await engine.item("key")
        #expect(await finalState.playerIsHolding)
    }

    @Test("STEAL syntax works")
    func testStealSyntax() async throws {
        // Given
        let gem = Item("gem")
            .name("sparkling gem")
            .description("A beautiful sparkling gem.")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: gem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("steal gem")

        // Then
        await mockIO.expectOutput(
            """
            > steal gem
            Taken.
            """
        )

        let finalState = await engine.item("gem")
        #expect(await finalState.playerIsHolding)
    }

    @Test("PICK UP syntax works")
    func testPickUpSyntax() async throws {
        // Given
        let feather = Item("feather")
            .name("white feather")
            .description("A delicate white feather.")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: feather
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pick up feather")

        // Then
        await mockIO.expectOutput(
            """
            > pick up feather
            Taken.
            """
        )

        let finalState = await engine.item("feather")
        #expect(await finalState.playerIsHolding)
    }

    @Test("TAKE DIRECTOBJECT FROM INDIRECTOBJECT syntax works")
    func testTakeFromContainerSyntax() async throws {
        // Given
        let box = Item("box")
            .name("wooden box")
            .description("A sturdy wooden box.")
            .isContainer
            .isOpen
            .in(.startRoom)

        let ring = Item("ring")
            .name("silver ring")
            .description("A beautiful silver ring.")
            .isTakable
            .in(.item("box"))

        let game = MinimalGame(
            items: box, ring
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take ring from box")

        // Then
        await mockIO.expectOutput(
            """
            > take ring from box
            Taken.
            """
        )

        let finalState = await engine.item("ring")
        #expect(await finalState.playerIsHolding)
    }

    @Test("TAKE ALL syntax works")
    func testTakeAllSyntax() async throws {
        // Given
        let book = Item("book")
            .name("red book")
            .description("A red book.")
            .isTakable
            .in(.startRoom)

        let coin = Item("coin")
            .name("gold coin")
            .description("A gold coin.")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: book, coin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take all")

        // Then
        await mockIO.expectOutput(
            """
            > take all
            You take the red book and the gold coin.
            """
        )

        let finalBook = await engine.item("book")
        let finalCoin = await engine.item("coin")
        #expect(await finalBook.playerIsHolding)
        #expect(await finalCoin.playerIsHolding)
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
        await mockIO.expectOutput(
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
        await mockIO.expectOutput(
            """
            > take nonexistent
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot take item not in scope")
    func testCannotTakeItemNotInScope() async throws {
        // Given
        let anotherRoom = Location("anotherRoom")
            .name("Another Room")
            .inherentlyLit

        let remoteBook = Item("remoteBook")
            .name("remote book")
            .description("A book in another room.")
            .isTakable
            .in("anotherRoom")

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteBook
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take book")

        // Then
        await mockIO.expectOutput(
            """
            > take book
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot take non-takable item")
    func testCannotTakeNonTakableItem() async throws {
        // Given
        let statue = Item("statue")
            .name("stone statue")
            .description("A heavy stone statue.")
            // Note: No .isTakable flag
            .in(.startRoom)

        let game = MinimalGame(
            items: statue
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take statue")

        // Then
        await mockIO.expectOutput(
            """
            > take statue
            The stone statue stubbornly resists your attempts to take it.
            """
        )
    }

    @Test("Cannot take item already held")
    func testCannotTakeItemAlreadyHeld() async throws {
        // Given
        let book = Item("book")
            .name("leather book")
            .description("A worn leather book.")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take book")

        // Then
        await mockIO.expectOutput(
            """
            > take book
            That already resides among your possessions.
            """
        )
    }

    @Test("Cannot take from closed container")
    func testCannotTakeFromClosedContainer() async throws {
        // Given
        let chest = Item("chest")
            .name("wooden chest")
            .description("A sturdy wooden chest.")
            .isContainer
            // Note: No .isOpen flag - container is closed
            .in(.startRoom)

        let treasure = Item("treasure")
            .name("golden treasure")
            .description("Precious golden treasure.")
            .isTakable
            .in(.item("chest"))

        let game = MinimalGame(
            items: chest, treasure
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take treasure")

        // Then
        await mockIO.expectOutput(
            """
            > take treasure
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot take from transparent closed container if item is touched")
    func testCannotTakeFromTransparentClosedContainer() async throws {
        // Given
        let jar = Item("jar")
            .name("glass jar")
            .description("A transparent glass jar.")
            .isContainer
            .isTransparent
            // Note: No .isOpen flag - container is closed but transparent
            .in(.startRoom)

        let marble = Item("marble")
            .name("blue marble")
            .description("A beautiful blue marble.")
            .isTakable
            .isTouched  // Player knows this item exists
            .in(.item("jar"))

        let game = MinimalGame(
            items: jar, marble
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take marble")

        // Then
        await mockIO.expectOutput(
            """
            > take marble
            The glass jar is closed.
            """
        )
    }

    @Test("Can take item from non-container")
    func testCanTakeItemFromNonContainer() async throws {
        // Given
        let rock = Item("rock")
            .name("large rock")
            .description("A large boulder.")
            // Note: Not a container or surface
            .in(.startRoom)

        let coin = Item("coin")
            .name("gold coin")
            .firstDescription("A gold coin lodged in the rock.")
            .isTakable
            .in(.item("rock"))

        let game = MinimalGame(
            items: rock, coin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take coin")

        // Then
        await mockIO.expectOutput(
            """
            > take coin
            Taken.
            """
        )
    }

    @Test("Cannot take from wrong container when using FROM syntax")
    func testCannotTakeFromWrongContainer() async throws {
        // Given
        let box = Item("box")
            .name("wooden box")
            .description("A wooden box.")
            .isContainer
            .isOpen
            .in(.startRoom)

        let bag = Item("bag")
            .name("leather bag")
            .description("A leather bag.")
            .isContainer
            .isOpen
            .in(.startRoom)

        let ring = Item("ring")
            .name("silver ring")
            .description("A silver ring.")
            .isTakable
            .in(.item("box"))

        let game = MinimalGame(
            items: box, bag, ring
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take ring from bag")

        // Then
        await mockIO.expectOutput(
            """
            > take ring from bag
            The silver ring is not in the leather bag.
            """
        )
    }

    @Test("Requires light to take items")
    func testRequiresLight() async throws {
        // Given: Dark room with takable item
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")
            // Note: No .inherentlyLit property

        let book = Item("book")
            .name("leather book")
            .description("A worn leather book.")
            .isTakable
            .in("darkRoom")

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take book")

        // Then
        await mockIO.expectOutput(
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
        let cabinet = Item("cabinet")
            .name("oak cabinet")
            .description("A sturdy oak cabinet.")
            .isContainer
            .isOpen
            .in(.startRoom)

        let vase = Item("vase")
            .name("ceramic vase")
            .description("A delicate ceramic vase.")
            .isTakable
            .in(.item("cabinet"))

        let game = MinimalGame(
            items: cabinet, vase
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take vase")

        // Then
        await mockIO.expectOutput(
            """
            > take vase
            Taken.
            """
        )

        let finalState = await engine.item("vase")
        #expect(await finalState.playerIsHolding)
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Take item from surface")
    func testTakeItemFromSurface() async throws {
        // Given
        let table = Item("table")
            .name("wooden table")
            .description("A sturdy wooden table.")
            .isSurface
            .in(.startRoom)

        let candle = Item("candle")
            .name("wax candle")
            .description("A simple wax candle.")
            .isTakable
            .in(.item("table"))

        let game = MinimalGame(
            items: table, candle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take candle")

        // Then
        await mockIO.expectOutput(
            """
            > take candle
            Taken.
            """
        )

        let finalState = await engine.item("candle")
        #expect(await finalState.playerIsHolding)
    }

    @Test("Take multiple items with TAKE ALL")
    func testTakeMultipleItemsWithTakeAll() async throws {
        // Given
        let book = Item("book")
            .name("red book")
            .description("A red book.")
            .isTakable
            .in(.startRoom)

        let pen = Item("pen")
            .name("blue pen")
            .description("A blue pen.")
            .isTakable
            .in(.startRoom)

        let statue = Item("statue")
            .name("stone statue")
            .description("A heavy statue.")
            // Note: Not takable
            .in(.startRoom)

        let game = MinimalGame(
            items: book, pen, statue
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take all")

        // Then
        await mockIO.expectOutput(
            """
            > take all
            You take the red book and the blue pen.
            """
        )

        let finalBook = await engine.item("book")
        let finalPen = await engine.item("pen")
        let finalStatue = await engine.item("statue")
        let startRoom = await engine.location(.startRoom)

        #expect(await finalBook.playerIsHolding)
        #expect(await finalPen.playerIsHolding)
        #expect(await finalStatue.parent == .location(startRoom))  // Statue not taken
    }

    @Test("TAKE ALL with nothing takable")
    func testTakeAllWithNothingTakable() async throws {
        // Given
        let statue = Item("statue")
            .name("stone statue")
            .description("A heavy statue.")
            // Note: Not takable
            .in(.startRoom)

        let game = MinimalGame(
            items: statue
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take all")

        // Then
        await mockIO.expectOutput(
            """
            > take all
            Take what?
            """
        )
    }

    @Test("TAKE ALL skips items already held")
    func testTakeAllSkipsItemsAlreadyHeld() async throws {
        // Given
        let book = Item("book")
            .name("red book")
            .description("A red book.")
            .isTakable
            .in(.player)  // Already held

        let pen = Item("pen")
            .name("blue pen")
            .description("A blue pen.")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: book, pen
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take all")

        // Then
        await mockIO.expectOutput(
            """
            > take all
            You take the blue pen.
            """
        )

        let finalPen = await engine.item("pen")
        #expect(await finalPen.playerIsHolding)
    }

    @Test("Updates pronouns to refer to taken item")
    func testUpdatesPronounsToTakenItem() async throws {
        // Given
        let book = Item("book")
            .name("leather book")
            .description("A worn leather book.")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take book")
        try await engine.execute("examine it")

        // Then
        await mockIO.expectOutput(
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
        let basket = Item("basket")
            .name("wicker basket")
            .in(.startRoom)
            .isTakable
            .size(5)

        let jug = Item("jug")
            .name("lemonade jug")
            .in(.startRoom)
            .isTakable
            .size(3)

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

        let basketProxy = await basket.proxy(engine)
        let jugProxy = await jug.proxy(engine)

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
