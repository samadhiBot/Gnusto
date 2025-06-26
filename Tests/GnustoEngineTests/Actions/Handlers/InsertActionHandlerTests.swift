import CustomDump
import Testing

@testable import GnustoEngine

@Suite("InsertActionHandler Tests")
struct InsertActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("INSERT DIRECTOBJECTS IN INDIRECTOBJECT syntax works")
    func testInsertDirectObjectsInIndirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .description("A shiny gold coin."),
            .isTakable,
            .in(.player)
        )

        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A wooden box."),
            .isContainer,
            .isOpen,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: coin, box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("insert coin in box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > insert coin in box
            You put the gold coin in the wooden box.
            """)

        let finalCoinState = try await engine.item("coin")
        let finalBoxState = try await engine.item("box")
        #expect(finalCoinState.parent == .item("box"))
        #expect(finalCoinState.hasFlag(.isTouched))
        #expect(finalBoxState.hasFlag(.isTouched))
    }

    @Test("INSERT DIRECTOBJECTS INSIDE INDIRECTOBJECT syntax works")
    func testInsertDirectObjectsInsideIndirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let gem = Item(
            id: "gem",
            .name("red gem"),
            .description("A red gem."),
            .isTakable,
            .in(.player)
        )

        let pouch = Item(
            id: "pouch",
            .name("leather pouch"),
            .description("A leather pouch."),
            .isContainer,
            .isOpen,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: gem, pouch
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("insert gem inside pouch")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > insert gem inside pouch
            You put the red gem in the leather pouch.
            """)
    }

    @Test("INSERT DIRECTOBJECTS INTO INDIRECTOBJECT syntax works")
    func testInsertDirectObjectsIntoIndirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let key = Item(
            id: "key",
            .name("brass key"),
            .description("A brass key."),
            .isTakable,
            .in(.player)
        )

        let chest = Item(
            id: "chest",
            .name("treasure chest"),
            .description("A treasure chest."),
            .isContainer,
            .isOpen,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: key, chest
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("insert key into chest")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > insert key into chest
            You put the brass key in the treasure chest.
            """)
    }

    @Test("PUT syntax works")
    func testPutSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let book = Item(
            id: "book",
            .name("old book"),
            .description("An old book."),
            .isTakable,
            .in(.player)
        )

        let bag = Item(
            id: "bag",
            .name("travel bag"),
            .description("A travel bag."),
            .isContainer,
            .isOpen,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: book, bag
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("put book in bag")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > put book in bag
            You put the old book in the travel bag.
            """)
    }

    @Test("PLACE syntax works")
    func testPlaceSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let scroll = Item(
            id: "scroll",
            .name("ancient scroll"),
            .description("An ancient scroll."),
            .isTakable,
            .in(.player)
        )

        let satchel = Item(
            id: "satchel",
            .name("leather satchel"),
            .description("A leather satchel."),
            .isContainer,
            .isOpen,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: scroll, satchel
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("place scroll in satchel")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > place scroll in satchel
            You put the ancient scroll in the leather satchel.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot insert without specifying what")
    func testCannotInsertWithoutSpecifyingWhat() async throws {
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

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("insert")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > insert
            Insert what?
            """)
    }

    @Test("Cannot insert without specifying where")
    func testCannotInsertWithoutSpecifyingWhere() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .description("A gold coin."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: coin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("insert coin")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > insert coin
            Insert the gold coin where?
            """)
    }

    @Test("Cannot insert item not held")
    func testCannotInsertItemNotHeld() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let gem = Item(
            id: "gem",
            .name("precious gem"),
            .description("A precious gem."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A wooden box."),
            .isContainer,
            .isOpen,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: gem, box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("insert gem in box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > insert gem in box
            You aren’t holding the precious gem.
            """)
    }

    @Test("Cannot insert into non-container")
    func testCannotInsertIntoNonContainer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .description("A gold coin."),
            .isTakable,
            .in(.player)
        )

        let rock = Item(
            id: "rock",
            .name("large rock"),
            .description("A large boulder."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: coin, rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("insert coin in rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > insert coin in rock
            The large rock is not a container.
            """)
    }

    @Test("Cannot insert into closed container")
    func testCannotInsertIntoClosedContainer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let key = Item(
            id: "key",
            .name("brass key"),
            .description("A brass key."),
            .isTakable,
            .in(.player)
        )

        let chest = Item(
            id: "chest",
            .name("treasure chest"),
            .description("A treasure chest."),
            .isContainer,
            // Note: No .isOpen flag - container is closed
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: key, chest
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("insert key in chest")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > insert key in chest
            The treasure chest is closed.
            """)
    }

    @Test("Cannot insert container not in scope")
    func testCannotInsertContainerNotInScope() async throws {
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

        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .description("A gold coin."),
            .isTakable,
            .in(.player)
        )

        let remoteBox = Item(
            id: "remoteBox",
            .name("remote box"),
            .description("A box in another room."),
            .isContainer,
            .isOpen,
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: coin, remoteBox
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("insert coin in box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > insert coin in box
            You can’t see any such thing.
            """)
    }

    @Test("Cannot insert item into itself")
    func testCannotInsertItemIntoItself() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let bag = Item(
            id: "bag",
            .name("magic bag"),
            .description("A magic bag."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: bag
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("insert bag in bag")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > insert bag in bag
            You can’t put the magic bag in itself.
            """)
    }

    @Test("Cannot insert container into its contents")
    func testCannotInsertContainerIntoItsContents() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let bag = Item(
            id: "bag",
            .name("travel bag"),
            .description("A travel bag."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.player)
        )

        let box = Item(
            id: "box",
            .name("small box"),
            .description("A small box."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.item("bag"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: bag, box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("insert bag in box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > insert bag in box
            You can’t put the travel bag in the small box.
            """)
    }

    @Test("Requires light to insert")
    func testRequiresLight() async throws {
        // Given: Dark room with items
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .description("A gold coin."),
            .isTakable,
            .in(.player)
        )

        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A wooden box."),
            .isContainer,
            .isOpen,
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: coin, box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("insert coin in box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > insert coin in box
            It is pitch black. You can’t see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Insert item successfully transfers to container")
    func testInsertItemSuccessfullyTransfersToContainer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let ring = Item(
            id: "ring",
            .name("silver ring"),
            .description("A silver ring."),
            .isTakable,
            .in(.player)
        )

        let jewelryBox = Item(
            id: "jewelryBox",
            .name("jewelry box"),
            .description("A jewelry box."),
            .isContainer,
            .isOpen,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: ring, jewelryBox
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("insert ring in box")

        // Then: Verify state changes
        let finalRingState = try await engine.item("ring")
        let finalBoxState = try await engine.item("jewelryBox")
        #expect(finalRingState.parent == .item("jewelryBox"))
        #expect(finalRingState.hasFlag(.isTouched))
        #expect(finalBoxState.hasFlag(.isTouched))

        // Verify message
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > insert ring in box
            You put the silver ring in the jewelry box.
            """)
    }

    @Test("Insert multiple items into container")
    func testInsertMultipleItemsIntoContainer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let coin1 = Item(
            id: "coin1",
            .name("gold coin"),
            .description("A gold coin."),
            .isTakable,
            .in(.player)
        )

        let coin2 = Item(
            id: "coin2",
            .name("silver coin"),
            .description("A silver coin."),
            .isTakable,
            .in(.player)
        )

        let purse = Item(
            id: "purse",
            .name("leather purse"),
            .description("A leather purse."),
            .isContainer,
            .isOpen,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: coin1, coin2, purse
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("insert coins in purse")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > insert coins in purse
            You put the gold coin and the silver coin in the leather purse.
            """)

        // Verify both coins transferred
        let finalCoin1State = try await engine.item("coin1")
        let finalCoin2State = try await engine.item("coin2")
        #expect(finalCoin1State.parent == .item("purse"))
        #expect(finalCoin2State.parent == .item("purse"))
    }

    @Test("Insert all items into container")
    func testInsertAllItemsIntoContainer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let book = Item(
            id: "book",
            .name("leather book"),
            .description("A leather book."),
            .isTakable,
            .in(.player)
        )

        let scroll = Item(
            id: "scroll",
            .name("ancient scroll"),
            .description("An ancient scroll."),
            .isTakable,
            .in(.player)
        )

        let satchel = Item(
            id: "satchel",
            .name("large satchel"),
            .description("A large satchel."),
            .isContainer,
            .isOpen,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: book, scroll, satchel
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("insert all in satchel")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > insert all in satchel
            You put the leather book and the ancient scroll in the large satchel.
            """)

        // Verify all items transferred
        let finalBookState = try await engine.item("book")
        let finalScrollState = try await engine.item("scroll")
        #expect(finalBookState.parent == .item("satchel"))
        #expect(finalScrollState.parent == .item("satchel"))
    }

    @Test("Insert all when player has nothing")
    func testInsertAllWhenPlayerHasNothing() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let box = Item(
            id: "box",
            .name("empty box"),
            .description("An empty box."),
            .isContainer,
            .isOpen,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("insert all in box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > insert all in box
            You have nothing to put in the empty box.
            """)
    }

    @Test("Insert sets touched flag on both items")
    func testInsertSetsTouchedFlagOnBothItems() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let crystal = Item(
            id: "crystal",
            .name("magic crystal"),
            .description("A magic crystal."),
            .isTakable,
            .in(.player)
        )

        let pouch = Item(
            id: "pouch",
            .name("velvet pouch"),
            .description("A velvet pouch."),
            .isContainer,
            .isOpen,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: crystal, pouch
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("insert crystal in pouch")

        // Then: Verify state changes
        let finalCrystalState = try await engine.item("crystal")
        let finalPouchState = try await engine.item("pouch")
        #expect(finalCrystalState.hasFlag(.isTouched))
        #expect(finalPouchState.hasFlag(.isTouched))
        #expect(finalCrystalState.parent == .item("pouch"))

        // Verify message
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > insert crystal in pouch
            You put the magic crystal in the velvet pouch.
            """)
    }

    @Test("Insert into container already containing items")
    func testInsertIntoContainerAlreadyContainingItems() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let newCoin = Item(
            id: "newCoin",
            .name("copper coin"),
            .description("A copper coin."),
            .isTakable,
            .in(.player)
        )

        let existingCoin = Item(
            id: "existingCoin",
            .name("gold coin"),
            .description("A gold coin."),
            .isTakable,
            .in(.item("wallet"))
        )

        let wallet = Item(
            id: "wallet",
            .name("leather wallet"),
            .description("A leather wallet."),
            .isContainer,
            .isOpen,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: newCoin, existingCoin, wallet
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("insert copper coin in wallet")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > insert copper coin in wallet
            You put the copper coin in the leather wallet.
            """)

        // Verify new coin is in wallet alongside existing coin
        let finalNewCoinState = try await engine.item("newCoin")
        let finalExistingCoinState = try await engine.item("existingCoin")
        #expect(finalNewCoinState.parent == .item("wallet"))
        #expect(finalExistingCoinState.parent == .item("wallet"))
    }

    @Test("Insert using different verb synonyms")
    func testInsertUsingDifferentVerbSynonyms() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let gem1 = Item(
            id: "gem1",
            .name("red gem"),
            .description("A red gem."),
            .isTakable,
            .in(.player)
        )

        let gem2 = Item(
            id: "gem2",
            .name("blue gem"),
            .description("A blue gem."),
            .isTakable,
            .in(.player)
        )

        let gem3 = Item(
            id: "gem3",
            .name("green gem"),
            .description("A green gem."),
            .isTakable,
            .in(.player)
        )

        let box = Item(
            id: "box",
            .name("gem box"),
            .description("A gem box."),
            .isContainer,
            .isOpen,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: gem1, gem2, gem3, box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Use "insert"
        try await engine.execute("insert red gem in box")

        // Then
        let output1 = await mockIO.flush()
        expectNoDifference(
            output1,
            """
            > insert red gem in box
            You put the red gem in the gem box.
            """)

        // When: Use "put"
        try await engine.execute("put blue gem in box")

        // Then
        let output2 = await mockIO.flush()
        expectNoDifference(
            output2,
            """
            > put blue gem in box
            You put the blue gem in the gem box.
            """)

        // When: Use "place"
        try await engine.execute("place green gem in box")

        // Then
        let output3 = await mockIO.flush()
        expectNoDifference(
            output3,
            """
            > place green gem in box
            You put the green gem in the gem box.
            """)

        // Verify all gems are in box
        let gem1State = try await engine.item("gem1")
        let gem2State = try await engine.item("gem2")
        let gem3State = try await engine.item("gem3")
        #expect(gem1State.parent == .item("box"))
        #expect(gem2State.parent == .item("box"))
        #expect(gem3State.parent == .item("box"))
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Intents")
    func testIntents() async throws {
        let handler = InsertActionHandler()
        // InsertActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = InsertActionHandler()
        #expect(handler.verbs.contains(.insert))
        #expect(handler.verbs.contains(.put))
        #expect(handler.verbs.contains(.place))
        #expect(handler.verbs.count == 3)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = InsertActionHandler()
        #expect(handler.requiresLight == true)
    }
}
