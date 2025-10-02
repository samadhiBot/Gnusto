import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("GiveActionHandler Tests")
struct GiveActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("GIVE DIRECTOBJECT TO INDIRECTOBJECT syntax works")
    func testGiveDirectObjectToIndirectObjectSyntax() async throws {
        // Given
        let coin = Item("coin")
            .name("gold coin")
            .description("A shiny gold coin.")
            .isTakable
            .in(.player)

        let merchant = Item("merchant")
            .name("traveling merchant")
            .description("A traveling merchant.")
            .characterSheet(.default)
            .in(.startRoom)

        let game = MinimalGame(
            items: coin, merchant
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("give coin to merchant")

        // Then
        await mockIO.expect(
            """
            > give coin to merchant
            You give the gold coin to the traveling merchant.
            """
        )

        let finalCoinState = await engine.item("coin")
        #expect(await finalCoinState.parent == .item(merchant.proxy(engine)))
        #expect(await finalCoinState.hasFlag(.isTouched))
    }

    @Test("GIVE INDIRECTOBJECT DIRECTOBJECT syntax works")
    func testGiveIndirectObjectDirectObjectSyntax() async throws {
        // Given
        let scroll = Item("scroll")
            .name("ancient scroll")
            .description("An ancient scroll.")
            .isTakable
            .in(.player)

        let wizard = Item("wizard")
            .name("old wizard")
            .description("A wise old wizard.")
            .characterSheet(.wise)
            .in(.startRoom)

        let game = MinimalGame(
            items: scroll, wizard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("give wizard the scroll")

        // Then
        await mockIO.expect(
            """
            > give wizard the scroll
            You give the ancient scroll to the old wizard.
            """
        )

        let finalScrollState = await engine.item("scroll")
        #expect(await finalScrollState.parent == .item(wizard.proxy(engine)))
    }

    @Test("OFFER syntax works")
    func testOfferSyntax() async throws {
        // Given
        let flower = Item("flower")
            .name("red flower")
            .description("A beautiful red flower.")
            .isTakable
            .in(.player)

        let princess = Item("princess")
            .name("kind princess")
            .description("A kind princess.")
            .characterSheet(.default)
            .in(.startRoom)

        let game = MinimalGame(
            items: flower, princess
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("offer flower to princess")

        // Then
        await mockIO.expect(
            """
            > offer flower to princess
            You give the red flower to the kind princess.
            """
        )
    }

    @Test("DONATE syntax works")
    func testDonateSyntax() async throws {
        // Given
        let bread = Item("bread")
            .name("loaf of bread")
            .description("A fresh loaf of bread.")
            .isTakable
            .in(.player)

        let beggar = Item("beggar")
            .name("hungry beggar")
            .description("A hungry beggar.")
            .characterSheet(.default)
            .in(.startRoom)

        let game = MinimalGame(
            items: bread, beggar
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("donate bread to beggar")

        // Then
        await mockIO.expect(
            """
            > donate bread to beggar
            You give the loaf of bread to the hungry beggar.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot give without specifying what")
    func testCannotGiveWithoutSpecifyingWhat() async throws {
        // Given
        let castleGuard = Item("castleGuard")
            .name("castle guard")
            .description("A stern castle guard.")
            .characterSheet(.strong)
            .in(.startRoom)

        let game = MinimalGame(
            items: castleGuard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("give")

        // Then
        await mockIO.expect(
            """
            > give
            Give what to whom?
            """
        )
    }

    @Test("Cannot give without specifying to whom")
    func testCannotGiveWithoutSpecifyingToWhom() async throws {
        // Given
        let key = Item("key")
            .name("brass key")
            .description("A brass key.")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("give key")

        // Then
        await mockIO.expect(
            """
            > give key
            Give what to whom?
            """
        )
    }

    @Test("Cannot give item not held")
    func testCannotGiveItemNotHeld() async throws {
        // Given
        let gem = Item("gem")
            .name("precious gem")
            .description("A precious gem.")
            .isTakable
            .in(.startRoom)

        let collector = Item("collector")
            .name("gem collector")
            .description("A gem collector.")
            .characterSheet(.default)
            .in(.startRoom)

        let game = MinimalGame(
            items: gem, collector
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("give gem to collector")

        // Then
        await mockIO.expect(
            """
            > give gem to collector
            You search in vain for the precious gem among your belongings.
            """
        )
    }

    @Test("Cannot give to non-character")
    func testCannotGiveToNonCharacter() async throws {
        // Given
        let apple = Item("apple")
            .name("red apple")
            .description("A red apple.")
            .isTakable
            .in(.player)

        let rock = Item("rock")
            .name("large rock")
            .description("A large boulder.")
            .in(.startRoom)

        let game = MinimalGame(
            items: apple, rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("give apple to rock")

        // Then
        await mockIO.expect(
            """
            > give apple to rock
            You'll need someone animate to give to.
            """
        )
    }

    @Test("Cannot give to character not in scope")
    func testCannotGiveToCharacterNotInScope() async throws {
        // Given
        let anotherRoom = Location("anotherRoom")
            .name("Another Room")
            .inherentlyLit

        let ring = Item("ring")
            .name("silver ring")
            .description("A silver ring.")
            .isTakable
            .in(.player)

        let remoteNPC = Item("remoteNPC")
            .name("distant person")
            .description("A person in another room.")
            .characterSheet(.default)
            .in("anotherRoom")

        let game = MinimalGame(
            locations: anotherRoom,
            items: ring, remoteNPC
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("give ring to person")

        // Then
        await mockIO.expect(
            """
            > give ring to person
            You cannot reach any such thing from here.
            """
        )
    }

    @Test("Requires light to give")
    func testRequiresLight() async throws {
        // Given: Dark room with character
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")
            // Note: No .inherentlyLit property

        let coin = Item("coin")
            .name("gold coin")
            .description("A gold coin.")
            .isTakable
            .in(.player)

        let stranger = Item("stranger")
            .name("mysterious stranger")
            .description("A mysterious stranger.")
            .characterSheet(.default)
            .in("darkRoom")

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: coin, stranger
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("give coin to stranger")

        // Then
        await mockIO.expect(
            """
            > give coin to stranger
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Give item successfully transfers ownership")
    func testGiveItemSuccessfullyTransfersOwnership() async throws {
        // Given
        let book = Item("book")
            .name("leather book")
            .description("A leather-bound book.")
            .isTakable
            .in(.player)

        let librarian = Item("librarian")
            .name("old librarian")
            .description("An old librarian.")
            .characterSheet(.default)
            .in(.startRoom)

        let game = MinimalGame(
            items: book, librarian
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("give book to librarian")

        // Then: Verify state changes
        let finalBookState = await engine.item("book")
        #expect(await finalBookState.parent == .item(librarian.proxy(engine)))
        #expect(await finalBookState.hasFlag(.isTouched))

        // Verify message
        await mockIO.expect(
            """
            > give book to librarian
            You give the leather book to the old librarian.
            """
        )
    }

    @Test("Give multiple items to character")
    func testGiveMultipleItemsToCharacter() async throws {
        // Given
        let coin1 = Item("coin1")
            .name("silver coin")
            .description("A silver coin.")
            .adjectives("silver")
            .isTakable
            .in(.player)

        let coin2 = Item("coin2")
            .name("copper coin")
            .description("A copper coin.")
            .adjectives("copper")
            .isTakable
            .in(.player)

        let merchant = Item("merchant")
            .name("coin merchant")
            .description("A coin merchant.")
            .characterSheet(.default)
            .in(.startRoom)

        let game = MinimalGame(
            items: coin1, coin2, merchant
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("give silver coin and copper coin to merchant")

        // Then
        await mockIO.expect(
            """
            > give silver coin and copper coin to merchant
            You give the silver coin and the copper coin to the coin
            merchant.
            """
        )

        // Verify both coins transferred
        let finalCoin1State = await engine.item("coin1")
        let finalCoin2State = await engine.item("coin2")
        #expect(await finalCoin1State.parent == .item(merchant.proxy(engine)))
        #expect(await finalCoin2State.parent == .item(merchant.proxy(engine)))
    }

    @Test("Give all items to character")
    func testGiveAllItemsToCharacter() async throws {
        // Given
        let sword = Item("sword")
            .name("steel sword")
            .description("A steel sword.")
            .isTakable
            .in(.player)

        let shield = Item("shield")
            .name("wooden shield")
            .description("A wooden shield.")
            .isTakable
            .in(.player)

        let knight = Item("knight")
            .name("noble knight")
            .description("A noble knight.")
            .characterSheet(.strong)
            .in(.startRoom)

        let game = MinimalGame(
            items: sword, shield, knight
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("give all to knight")

        // Then
        await mockIO.expect(
            """
            > give all to knight
            You give the wooden shield and the steel sword to the noble
            knight.
            """
        )

        // Verify all items transferred
        let finalSwordState = await engine.item("sword")
        let finalShieldState = await engine.item("shield")
        #expect(await finalSwordState.parent == .item(knight.proxy(engine)))
        #expect(await finalShieldState.parent == .item(knight.proxy(engine)))
    }

    @Test("Give all when player has nothing")
    func testGiveAllWhenPlayerHasNothing() async throws {
        // Given
        let sage = Item("sage")
            .name("wise sage")
            .description("A wise sage.")
            .characterSheet(.default)
            .in(.startRoom)

        let game = MinimalGame(
            items: sage
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("give all to sage")

        // Then
        await mockIO.expect(
            """
            > give all to sage
            You carry nothing but your own thoughts.
            """
        )
    }

    @Test("Give sets touched flag on item")
    func testGiveSetsTouchedFlag() async throws {
        // Given
        let crystal = Item("crystal")
            .name("magic crystal")
            .description("A magic crystal.")
            .isTakable
            .in(.player)

        let mage = Item("mage")
            .name("ancient mage")
            .description("An ancient mage.")
            .characterSheet(.default)
            .in(.startRoom)

        let game = MinimalGame(
            items: crystal, mage
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("give crystal to mage")

        // Then: Verify state changes
        let finalCrystalState = await engine.item("crystal")
        #expect(await finalCrystalState.hasFlag(.isTouched))
        #expect(await finalCrystalState.parent == .item(mage.proxy(engine)))

        // Verify message
        await mockIO.expect(
            """
            > give crystal to mage
            You give the magic crystal to the ancient mage.
            """
        )
    }

    @Test("Give different items to different characters")
    func testGiveDifferentItemsToDifferentCharacters() async throws {
        // Given
        let food = Item("food")
            .name("fresh food")
            .description("Fresh food.")
            .isTakable
            .in(.player)

        let money = Item("money")
            .name("bag of money")
            .description("A bag of money.")
            .isTakable
            .in(.player)

        let chef = Item("chef")
            .name("busy chef")
            .description("A busy chef.")
            .characterSheet(.default)
            .in(.startRoom)

        let banker = Item("banker")
            .name("bank clerk")
            .description("A bank clerk.")
            .characterSheet(.default)
            .in(.startRoom)

        let game = MinimalGame(
            items: food, money, chef, banker
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Give food to chef
        try await engine.execute("give food to chef")

        // Then
        await mockIO.expect(
            """
            > give food to chef
            You give the fresh food to the busy chef.
            """
        )

        // When: Give money to banker
        try await engine.execute("give money to banker")

        // Then
        await mockIO.expect(
            """
            > give money to banker
            You give the bag of money to the bank clerk.
            """
        )

        // Verify items transferred to correct recipients
        let finalFoodState = await engine.item("food")
        let finalMoneyState = await engine.item("money")
        #expect(await finalFoodState.parent == .item(chef.proxy(engine)))
        #expect(await finalMoneyState.parent == .item(banker.proxy(engine)))
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = GiveActionHandler()
        #expect(handler.synonyms.contains(.give))
        #expect(handler.synonyms.contains(.offer))
        #expect(handler.synonyms.contains(.donate))
        #expect(handler.synonyms.count == 3)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = GiveActionHandler()
        #expect(handler.requiresLight == true)
    }
}
