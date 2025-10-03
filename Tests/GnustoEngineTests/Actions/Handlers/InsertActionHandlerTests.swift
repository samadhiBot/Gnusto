import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("InsertActionHandler Tests")
struct InsertActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("INSERT DIRECTOBJECTS IN INDIRECTOBJECT syntax works")
    func testInsertDirectObjectsInIndirectObjectSyntax() async throws {
        // Given
        let coin = Item("coin")
            .name("gold coin")
            .description("A shiny gold coin.")
            .isTakable
            .in(.player)

        let box = Item("box")
            .name("wooden box")
            .description("A wooden box.")
            .isContainer
            .isOpen
            .in(.startRoom)

        let game = MinimalGame(
            items: coin, box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("insert coin in box")

        // Then
        await mockIO.expect(
            """
            > insert coin in box
            You carefully place the gold coin within the wooden box.
            """
        )

        let finalCoinState = await engine.item("coin")
        let finalBoxState = await engine.item("box")
        #expect(await finalCoinState.parent == .item(box.proxy(engine)))
        #expect(await finalCoinState.hasFlag(.isTouched))
        #expect(await finalBoxState.hasFlag(.isTouched))
    }

    @Test("INSERT DIRECTOBJECTS INSIDE INDIRECTOBJECT syntax works")
    func testInsertDirectObjectsInsideIndirectObjectSyntax() async throws {
        // Given
        let gem = Item("gem")
            .name("red gem")
            .description("A red gem.")
            .isTakable
            .in(.player)

        let pouch = Item("pouch")
            .name("leather pouch")
            .description("A leather pouch.")
            .isContainer
            .isOpen
            .in(.startRoom)

        let game = MinimalGame(
            items: gem, pouch
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("insert gem inside pouch")

        // Then
        await mockIO.expect(
            """
            > insert gem inside pouch
            You carefully place the red gem within the leather pouch.
            """
        )
    }

    @Test("INSERT DIRECTOBJECTS INTO INDIRECTOBJECT syntax works")
    func testInsertDirectObjectsIntoIndirectObjectSyntax() async throws {
        // Given
        let key = Item("key")
            .name("brass key")
            .description("A brass key.")
            .isTakable
            .in(.player)

        let chest = Item("chest")
            .name("treasure chest")
            .description("A treasure chest.")
            .isContainer
            .isOpen
            .in(.startRoom)

        let game = MinimalGame(
            items: key, chest
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("insert key into chest")

        // Then
        await mockIO.expect(
            """
            > insert key into chest
            You carefully place the brass key within the treasure chest.
            """
        )
    }

    @Test("PUT syntax works")
    func testPutSyntax() async throws {
        // Given
        let book = Item("book")
            .name("old book")
            .description("An old book.")
            .isTakable
            .in(.player)

        let bag = Item("bag")
            .name("travel bag")
            .description("A travel bag.")
            .isContainer
            .isOpen
            .in(.startRoom)

        let game = MinimalGame(
            items: book, bag
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("put book in bag")

        // Then
        await mockIO.expect(
            """
            > put book in bag
            You carefully place the old book within the travel bag.
            """
        )
    }

    @Test("PLACE syntax works")
    func testPlaceSyntax() async throws {
        // Given
        let scroll = Item("scroll")
            .name("ancient scroll")
            .description("An ancient scroll.")
            .isTakable
            .in(.player)

        let satchel = Item("satchel")
            .name("leather satchel")
            .description("A leather satchel.")
            .isContainer
            .isOpen
            .in(.startRoom)

        let game = MinimalGame(
            items: scroll, satchel
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("place scroll in satchel")

        // Then
        await mockIO.expect(
            """
            > place scroll in satchel
            You carefully place the ancient scroll within the leather
            satchel.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot insert without specifying what")
    func testCannotInsertWithoutSpecifyingWhat() async throws {
        // Given
        let box = Item("box")
            .name("wooden box")
            .description("A wooden box.")
            .isContainer
            .isOpen
            .in(.startRoom)

        let game = MinimalGame(
            items: box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("insert")

        // Then
        await mockIO.expect(
            """
            > insert
            Insert what?
            """
        )
    }

    @Test("Cannot insert without specifying where")
    func testCannotInsertWithoutSpecifyingWhere() async throws {
        // Given
        let coin = Item("coin")
            .name("gold coin")
            .description("A gold coin.")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: coin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("insert coin")

        // Then
        await mockIO.expect(
            """
            > insert coin
            Insert the gold coin where?
            """
        )
    }

    @Test("Cannot insert item not held")
    func testCannotInsertItemNotHeld() async throws {
        // Given
        let gem = Item("gem")
            .name("precious gem")
            .description("A precious gem.")
            .isTakable
            .in(.startRoom)

        let box = Item("box")
            .name("wooden box")
            .description("A wooden box.")
            .isContainer
            .isOpen
            .in(.startRoom)

        let game = MinimalGame(
            items: gem, box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("insert gem in box")

        // Then
        await mockIO.expect(
            """
            > insert gem in box
            You aren't holding the precious gem.
            """
        )
    }

    @Test("Cannot insert into non-container")
    func testCannotInsertIntoNonContainer() async throws {
        // Given
        let coin = Item("coin")
            .name("gold coin")
            .description("A gold coin.")
            .isTakable
            .in(.player)

        let rock = Item("rock")
            .name("large rock")
            .description("A large boulder.")
            .in(.startRoom)

        let game = MinimalGame(
            items: coin, rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("insert coin in rock")

        // Then
        await mockIO.expect(
            """
            > insert coin in rock
            You can't put things in the large rock.
            """
        )
    }

    @Test("Cannot insert into closed container")
    func testCannotInsertIntoClosedContainer() async throws {
        // Given
        let key = Item("key")
            .name("brass key")
            .description("A brass key.")
            .isTakable
            .in(.player)

        let chest = Item("chest")
            .name("treasure chest")
            .description("A treasure chest.")
            .isContainer
            // Note: No .isOpen flag - container is closed
            .in(.startRoom)

        let game = MinimalGame(
            items: key, chest
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("insert key in chest")

        // Then
        await mockIO.expect(
            """
            > insert key in chest
            The treasure chest is closed.
            """
        )
    }

    @Test("Cannot insert container not in scope")
    func testCannotInsertContainerNotInScope() async throws {
        // Given
        let anotherRoom = Location("anotherRoom")
            .name("Another Room")
            .inherentlyLit

        let coin = Item("coin")
            .name("gold coin")
            .description("A gold coin.")
            .isTakable
            .in(.player)

        let remoteBox = Item("remoteBox")
            .name("remote box")
            .description("A box in another room.")
            .isContainer
            .isOpen
            .in("anotherRoom")

        let game = MinimalGame(
            locations: anotherRoom,
            items: coin, remoteBox
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("insert coin in box")

        // Then
        await mockIO.expect(
            """
            > insert coin in box
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot insert item into itself")
    func testCannotInsertItemIntoItself() async throws {
        // Given
        let bag = Item("bag")
            .name("magic bag")
            .description("A magic bag.")
            .isContainer
            .isOpen
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: bag
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("insert bag in bag")

        // Then
        await mockIO.expect(
            """
            > insert bag in bag
            The universe politely but firmly prevents such recursive
            madness.
            """
        )
    }

    @Test("Cannot insert container into its contents")
    func testCannotInsertContainerIntoItsContents() async throws {
        // Given
        let bag = Item("bag")
            .name("travel bag")
            .description("A travel bag.")
            .isContainer
            .isOpen
            .isTakable
            .in(.player)

        let box = Item("box")
            .name("small box")
            .description("A small box.")
            .isContainer
            .isOpen
            .isTakable
            .in(.item("bag"))

        let game = MinimalGame(
            items: bag, box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("insert bag in box")

        // Then
        await mockIO.expect(
            """
            > insert bag in box
            The laws of physics sternly forbid putting the travel bag
            inside its own contents.
            """
        )
    }

    @Test("Requires light to insert")
    func testRequiresLight() async throws {
        // Given: Dark room with items
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")
            // Note: No .inherentlyLit property

        let coin = Item("coin")
            .name("gold coin")
            .description("A gold coin.")
            .isTakable
            .in(.player)

        let box = Item("box")
            .name("wooden box")
            .description("A wooden box.")
            .isContainer
            .isOpen
            .in("darkRoom")

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: coin, box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("insert coin in box")

        // Then
        await mockIO.expect(
            """
            > insert coin in box
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Insert item successfully transfers to container")
    func testInsertItemSuccessfullyTransfersToContainer() async throws {
        // Given
        let ring = Item("ring")
            .name("silver ring")
            .description("A silver ring.")
            .isTakable
            .in(.player)

        let jewelryBox = Item("jewelryBox")
            .name("jewelry box")
            .description("A jewelry box.")
            .isContainer
            .isOpen
            .in(.startRoom)

        let game = MinimalGame(
            items: ring, jewelryBox
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("insert ring in box")

        // Then: Verify state changes
        let finalRingState = await engine.item("ring")
        let finalBoxState = await engine.item("jewelryBox")
        #expect(await finalRingState.parent == .item(jewelryBox.proxy(engine)))
        #expect(await finalRingState.hasFlag(.isTouched))
        #expect(await finalBoxState.hasFlag(.isTouched))

        // Verify message
        await mockIO.expect(
            """
            > insert ring in box
            You carefully place the silver ring within the jewelry box.
            """
        )
    }

    @Test("Insert multiple items into container")
    func testInsertMultipleItemsIntoContainer() async throws {
        // Given
        let coin1 = Item("coin1")
            .name("gold coin")
            .description("A gold coin.")
            .isTakable
            .in(.player)

        let coin2 = Item("coin2")
            .name("silver coin")
            .description("A silver coin.")
            .isTakable
            .in(.player)

        let purse = Item("purse")
            .name("leather purse")
            .description("A leather purse.")
            .isContainer
            .isOpen
            .in(.startRoom)

        let game = MinimalGame(
            items: coin1, coin2, purse
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("insert gold coin and silver coin in purse")

        // Then
        await mockIO.expect(
            """
            > insert gold coin and silver coin in purse
            You carefully place the gold coin and the silver coin within
            the leather purse.
            """
        )

        // Verify both coins transferred
        let finalCoin1State = await engine.item("coin1")
        let finalCoin2State = await engine.item("coin2")
        #expect(await finalCoin1State.parent == .item(purse.proxy(engine)))
        #expect(await finalCoin2State.parent == .item(purse.proxy(engine)))
    }

    @Test("Insert all items into container")
    func testInsertAllItemsIntoContainer() async throws {
        // Given
        let book = Item("book")
            .name("leather book")
            .description("A leather book.")
            .isTakable
            .in(.player)

        let scroll = Item("scroll")
            .name("ancient scroll")
            .description("An ancient scroll.")
            .isTakable
            .in(.player)

        let satchel = Item("satchel")
            .name("large satchel")
            .description("A large satchel.")
            .isContainer
            .isOpen
            .in(.startRoom)

        let game = MinimalGame(
            items: book, scroll, satchel
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("insert all in satchel")

        // Then
        await mockIO.expect(
            """
            > insert all in satchel
            You carefully place the leather book and the ancient scroll
            within the large satchel.
            """
        )

        // Verify all items transferred
        let finalBookState = await engine.item("book")
        let finalScrollState = await engine.item("scroll")
        #expect(await finalBookState.parent == .item(satchel.proxy(engine)))
        #expect(await finalScrollState.parent == .item(satchel.proxy(engine)))
    }

    @Test("Insert all when player has nothing")
    func testInsertAllWhenPlayerHasNothing() async throws {
        // Given
        let box = Item("box")
            .name("empty box")
            .description("An empty box.")
            .isContainer
            .isOpen
            .in(.startRoom)

        let game = MinimalGame(
            items: box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("insert all in box")

        // Then
        await mockIO.expect(
            """
            > insert all in box
            Your possessions offer nothing suitable for placement in the
            empty box.
            """
        )
    }

    @Test("Insert sets touched flag on both items")
    func testInsertSetsTouchedFlagOnBothItems() async throws {
        // Given
        let crystal = Item("crystal")
            .name("magic crystal")
            .description("A magic crystal.")
            .isTakable
            .in(.player)

        let pouch = Item("pouch")
            .name("velvet pouch")
            .description("A velvet pouch.")
            .isContainer
            .isOpen
            .in(.startRoom)

        let game = MinimalGame(
            items: crystal, pouch
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("insert crystal in pouch")

        // Then: Verify state changes
        let finalCrystalState = await engine.item("crystal")
        let finalPouchState = await engine.item("pouch")
        #expect(await finalCrystalState.hasFlag(.isTouched))
        #expect(await finalPouchState.hasFlag(.isTouched))
        #expect(await finalCrystalState.parent == .item(pouch.proxy(engine)))

        // Verify message
        await mockIO.expect(
            """
            > insert crystal in pouch
            You carefully place the magic crystal within the velvet pouch.
            """
        )
    }

    @Test("Insert into container already containing items")
    func testInsertIntoContainerAlreadyContainingItems() async throws {
        // Given
        let newCoin = Item("newCoin")
            .name("copper coin")
            .description("A copper coin.")
            .isTakable
            .in(.player)

        let existingCoin = Item("existingCoin")
            .name("gold coin")
            .description("A gold coin.")
            .isTakable
            .in(.item("wallet"))

        let wallet = Item("wallet")
            .name("leather wallet")
            .description("A leather wallet.")
            .isContainer
            .isOpen
            .in(.startRoom)

        let game = MinimalGame(
            items: newCoin, existingCoin, wallet
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("insert copper coin in wallet")

        // Then
        await mockIO.expect(
            """
            > insert copper coin in wallet
            You carefully place the copper coin within the leather wallet.
            """
        )

        // Verify new coin is in wallet alongside existing coin
        let finalNewCoinState = await engine.item("newCoin")
        let finalExistingCoinState = await engine.item("existingCoin")
        #expect(await finalNewCoinState.parent == .item(wallet.proxy(engine)))
        #expect(await finalExistingCoinState.parent == .item(wallet.proxy(engine)))
    }

    @Test("Insert using different verb synonyms")
    func testInsertUsingDifferentVerbSynonyms() async throws {
        // Given
        let gem1 = Item("gem1")
            .name("red gem")
            .description("A red gem.")
            .isTakable
            .in(.player)

        let gem2 = Item("gem2")
            .name("blue gem")
            .description("A blue gem.")
            .isTakable
            .in(.player)

        let gem3 = Item("gem3")
            .name("green gem")
            .description("A green gem.")
            .isTakable
            .in(.player)

        let box = Item("box")
            .name("gem box")
            .description("A gem box.")
            .isContainer
            .isOpen
            .in(.startRoom)

        let game = MinimalGame(
            items: gem1, gem2, gem3, box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Use "insert"
        try await engine.execute("insert red gem in box")

        // Then
        await mockIO.expect(
            """
            > insert red gem in box
            You carefully place the red gem within the gem box.
            """
        )

        // When: Use "put"
        try await engine.execute("put blue gem in box")

        // Then
        await mockIO.expect(
            """
            > put blue gem in box
            With practiced ease, you deposit the blue gem in the gem box.
            """
        )

        // When: Use "place"
        try await engine.execute("place green gem in box")

        // Then
        await mockIO.expect(
            """
            > place green gem in box
            The green gem finds a new home inside the gem box.
            """
        )

        // Verify all gems are in box
        let gem1State = await engine.item("gem1")
        let gem2State = await engine.item("gem2")
        let gem3State = await engine.item("gem3")
        #expect(await gem1State.parent == .item(box.proxy(engine)))
        #expect(await gem2State.parent == .item(box.proxy(engine)))
        #expect(await gem3State.parent == .item(box.proxy(engine)))
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = InsertActionHandler()
        #expect(handler.synonyms.contains(.insert))
        #expect(handler.synonyms.contains(.put))
        #expect(handler.synonyms.contains(.place))
        #expect(handler.synonyms.count == 3)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = InsertActionHandler()
        #expect(handler.requiresLight == true)
    }
}
