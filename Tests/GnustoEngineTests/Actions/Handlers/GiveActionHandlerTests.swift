import CustomDump
import Testing

@testable import GnustoEngine

@Suite("GiveActionHandler Tests")
struct GiveActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("GIVE DIRECTOBJECT TO INDIRECTOBJECT syntax works")
    func testGiveDirectObjectToIndirectObjectSyntax() async throws {
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

        let merchant = Item(
            id: "merchant",
            .name("traveling merchant"),
            .description("A traveling merchant."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: coin, merchant
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("give coin to merchant")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > give coin to merchant
            You give the gold coin to the traveling merchant.
            """)

        let finalCoinState = try await engine.item("coin")
        #expect(finalCoinState.parent == .item("merchant"))
        #expect(finalCoinState.hasFlag(.isTouched))
    }

    @Test("GIVE INDIRECTOBJECT DIRECTOBJECT syntax works")
    func testGiveIndirectObjectDirectObjectSyntax() async throws {
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

        let wizard = Item(
            id: "wizard",
            .name("old wizard"),
            .description("A wise old wizard."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: scroll, wizard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("give wizard scroll")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > give wizard scroll
            You give the ancient scroll to the old wizard.
            """)

        let finalScrollState = try await engine.item("scroll")
        #expect(finalScrollState.parent == .item("wizard"))
    }

    @Test("OFFER syntax works")
    func testOfferSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let flower = Item(
            id: "flower",
            .name("red flower"),
            .description("A beautiful red flower."),
            .isTakable,
            .in(.player)
        )

        let princess = Item(
            id: "princess",
            .name("kind princess"),
            .description("A kind princess."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: flower, princess
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("offer flower to princess")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > offer flower to princess
            You give the red flower to the kind princess.
            """)
    }

    @Test("DONATE syntax works")
    func testDonateSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let bread = Item(
            id: "bread",
            .name("loaf of bread"),
            .description("A fresh loaf of bread."),
            .isTakable,
            .in(.player)
        )

        let beggar = Item(
            id: "beggar",
            .name("hungry beggar"),
            .description("A hungry beggar."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: bread, beggar
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("donate bread to beggar")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > donate bread to beggar
            You give the loaf of bread to the hungry beggar.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot give without specifying what")
    func testCannotGiveWithoutSpecifyingWhat() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let castleGuard = Item(
            id: "castleGuard",
            .name("castle guard"),
            .description("A stern castle guard."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: castleGuard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("give")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > give
            Give what?
            """)
    }

    @Test("Cannot give without specifying to whom")
    func testCannotGiveWithoutSpecifyingToWhom() async throws {
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

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("give key")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > give key
            Give to whom?
            """)
    }

    @Test("Cannot give item not held")
    func testCannotGiveItemNotHeld() async throws {
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

        let collector = Item(
            id: "collector",
            .name("gem collector"),
            .description("A gem collector."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: gem, collector
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("give gem to collector")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > give gem to collector
            You don’t have that.
            """)
    }

    @Test("Cannot give to non-character")
    func testCannotGiveToNonCharacter() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let apple = Item(
            id: "apple",
            .name("red apple"),
            .description("A red apple."),
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
            items: apple, rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("give apple to rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > give apple to rock
            That’s not something you can give.
            """)
    }

    @Test("Cannot give to character not in scope")
    func testCannotGiveToCharacterNotInScope() async throws {
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

        let ring = Item(
            id: "ring",
            .name("silver ring"),
            .description("A silver ring."),
            .isTakable,
            .in(.player)
        )

        let remoteNPC = Item(
            id: "remoteNPC",
            .name("distant person"),
            .description("A person in another room."),
            .isCharacter,
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: ring, remoteNPC
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("give ring to person")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > give ring to person
            You can’t see any such thing.
            """)
    }

    @Test("Requires light to give")
    func testRequiresLight() async throws {
        // Given: Dark room with character
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

        let stranger = Item(
            id: "stranger",
            .name("mysterious stranger"),
            .description("A mysterious stranger."),
            .isCharacter,
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: coin, stranger
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("give coin to stranger")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > give coin to stranger
            It is pitch black. You can’t see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Give item successfully transfers ownership")
    func testGiveItemSuccessfullyTransfersOwnership() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let book = Item(
            id: "book",
            .name("leather book"),
            .description("A leather-bound book."),
            .isTakable,
            .in(.player)
        )

        let librarian = Item(
            id: "librarian",
            .name("old librarian"),
            .description("An old librarian."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: book, librarian
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("give book to librarian")

        // Then: Verify state changes
        let finalBookState = try await engine.item("book")
        #expect(finalBookState.parent == .item("librarian"))
        #expect(finalBookState.hasFlag(.isTouched))

        // Verify message
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > give book to librarian
            You give the leather book to the old librarian.
            """)
    }

    @Test("Give multiple items to character")
    func testGiveMultipleItemsToCharacter() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let coin1 = Item(
            id: "coin1",
            .name("silver coin"),
            .description("A silver coin."),
            .isTakable,
            .in(.player)
        )

        let coin2 = Item(
            id: "coin2",
            .name("copper coin"),
            .description("A copper coin."),
            .isTakable,
            .in(.player)
        )

        let merchant = Item(
            id: "merchant",
            .name("coin merchant"),
            .description("A coin merchant."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: coin1, coin2, merchant
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("give coins to merchant")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > give coins to merchant
            You give the silver coin and the copper coin to the coin merchant.
            """)

        // Verify both coins transferred
        let finalCoin1State = try await engine.item("coin1")
        let finalCoin2State = try await engine.item("coin2")
        #expect(finalCoin1State.parent == .item("merchant"))
        #expect(finalCoin2State.parent == .item("merchant"))
    }

    @Test("Give all items to character")
    func testGiveAllItemsToCharacter() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let sword = Item(
            id: "sword",
            .name("steel sword"),
            .description("A steel sword."),
            .isTakable,
            .in(.player)
        )

        let shield = Item(
            id: "shield",
            .name("wooden shield"),
            .description("A wooden shield."),
            .isTakable,
            .in(.player)
        )

        let knight = Item(
            id: "knight",
            .name("noble knight"),
            .description("A noble knight."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: sword, shield, knight
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("give all to knight")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > give all to knight
            You give the steel sword and the wooden shield to the noble knight.
            """)

        // Verify all items transferred
        let finalSwordState = try await engine.item("sword")
        let finalShieldState = try await engine.item("shield")
        #expect(finalSwordState.parent == .item("knight"))
        #expect(finalShieldState.parent == .item("knight"))
    }

    @Test("Give all when player has nothing")
    func testGiveAllWhenPlayerHasNothing() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let sage = Item(
            id: "sage",
            .name("wise sage"),
            .description("A wise sage."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: sage
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("give all to sage")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > give all to sage
            You have nothing to give.
            """)
    }

    @Test("Give sets touched flag on item")
    func testGiveSetsTouchedFlag() async throws {
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

        let mage = Item(
            id: "mage",
            .name("ancient mage"),
            .description("An ancient mage."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: crystal, mage
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("give crystal to mage")

        // Then: Verify state changes
        let finalCrystalState = try await engine.item("crystal")
        #expect(finalCrystalState.hasFlag(.isTouched))
        #expect(finalCrystalState.parent == .item("mage"))

        // Verify message
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > give crystal to mage
            You give the magic crystal to the ancient mage.
            """)
    }

    @Test("Give different items to different characters")
    func testGiveDifferentItemsToDifferentCharacters() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let food = Item(
            id: "food",
            .name("fresh food"),
            .description("Fresh food."),
            .isTakable,
            .in(.player)
        )

        let money = Item(
            id: "money",
            .name("bag of money"),
            .description("A bag of money."),
            .isTakable,
            .in(.player)
        )

        let chef = Item(
            id: "chef",
            .name("busy chef"),
            .description("A busy chef."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let banker = Item(
            id: "banker",
            .name("bank clerk"),
            .description("A bank clerk."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: food, money, chef, banker
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Give food to chef
        try await engine.execute("give food to chef")

        // Then
        let output1 = await mockIO.flush()
        expectNoDifference(
            output1,
            """
            > give food to chef
            You give the fresh food to the busy chef.
            """)

        // When: Give money to banker
        try await engine.execute("give money to banker")

        // Then
        let output2 = await mockIO.flush()
        expectNoDifference(
            output2,
            """
            > give money to banker
            You give the bag of money to the bank clerk.
            """)

        // Verify items transferred to correct recipients
        let finalFoodState = try await engine.item("food")
        let finalMoneyState = try await engine.item("money")
        #expect(finalFoodState.parent == .item("chef"))
        #expect(finalMoneyState.parent == .item("banker"))
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Intents")
    func testIntents() async throws {
        let handler = GiveActionHandler()
        // GiveActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = GiveActionHandler()
        #expect(handler.verbs.contains(.give))
        #expect(handler.verbs.contains(.offer))
        #expect(handler.verbs.contains(.donate))
        #expect(handler.verbs.count == 3)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = GiveActionHandler()
        #expect(handler.requiresLight == true)
    }
}
