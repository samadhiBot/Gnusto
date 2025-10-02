import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("WearActionHandler Tests")
struct WearActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("WEAR DIRECTOBJECT syntax works")
    func testWearDirectObjectSyntax() async throws {
        // Given
        let hat = Item("hat")
            .name("red hat")
            .description("A stylish red hat.")
            .isWearable
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: hat
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wear hat")

        // Then
        await mockIO.expect(
            """
            > wear hat
            You don the red hat with practiced ease.
            """
        )

        let finalState = await engine.item("hat")
        #expect(await finalState.hasFlag(.isWorn) == true)
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("PUT ON DIRECTOBJECT syntax works")
    func testPutOnSyntax() async throws {
        // Given
        let jacket = Item("jacket")
            .name("leather jacket")
            .description("A worn leather jacket.")
            .isWearable
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: jacket
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("put on jacket")

        // Then
        await mockIO.expect(
            """
            > put on jacket
            You don the leather jacket with practiced ease.
            """
        )

        let finalState = await engine.item("jacket")
        #expect(await finalState.hasFlag(.isWorn) == true)
    }

    @Test("DON syntax works")
    func testDonSyntax() async throws {
        // Given
        let cloak = Item("cloak")
            .name("dark cloak")
            .description("A mysterious dark cloak.")
            .isWearable
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: cloak
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("don cloak")

        // Then
        await mockIO.expect(
            """
            > don cloak
            You don the dark cloak with practiced ease.
            """
        )
    }

    @Test("WEAR ALL syntax works")
    func testWearAllSyntax() async throws {
        // Given
        let hat = Item("hat")
            .name("blue hat")
            .description("A blue hat.")
            .isWearable
            .isTakable
            .in(.player)

        let gloves = Item("gloves")
            .name("wool gloves")
            .description("Warm wool gloves.")
            .isWearable
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: hat, gloves
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wear all")

        // Then
        await mockIO.expect(
            """
            > wear all
            You don the wool gloves and the blue hat with practiced ease.
            """
        )

        let finalHat = await engine.item("hat")
        let finalGloves = await engine.item("gloves")
        #expect(await finalHat.hasFlag(.isWorn) == true)
        #expect(await finalGloves.hasFlag(.isWorn) == true)
    }

    // MARK: - Validation Testing

    @Test("Cannot wear without specifying what")
    func testCannotWearWithoutWhat() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wear")

        // Then
        await mockIO.expect(
            """
            > wear
            Wear what?
            """
        )
    }

    @Test("Cannot wear item not held")
    func testCannotWearItemNotHeld() async throws {
        // Given
        let hat = Item("hat")
            .name("fancy hat")
            .description("A fancy hat.")
            .isWearable
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: hat
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wear hat")

        // Then
        await mockIO.expect(
            """
            > wear hat
            You aren't holding the fancy hat.
            """
        )
    }

    @Test("Cannot wear non-wearable item")
    func testCannotWearNonWearableItem() async throws {
        // Given
        let rock = Item("rock")
            .name("heavy rock")
            .description("A heavy rock.")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wear rock")

        // Then
        await mockIO.expect(
            """
            > wear rock
            The heavy rock stubbornly resists your attempts to wear it.
            """
        )
    }

    @Test("Cannot wear already worn item")
    func testCannotWearAlreadyWornItem() async throws {
        // Given
        let boots = Item("boots")
            .name("hiking boots")
            .description("Sturdy hiking boots.")
            .isWearable
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: boots
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up: boots are already worn
        try await engine.apply(
            boots.proxy(engine).setFlag(.isWorn)
        )

        // When
        try await engine.execute("wear boots")

        // Then
        await mockIO.expect(
            """
            > wear boots
            You are already wearing the hiking boots.
            """
        )
    }

    @Test("Requires light to wear")
    func testRequiresLight() async throws {
        // Given: Dark room with wearable item
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")
            // Note: No .inherentlyLit property

        let scarf = Item("scarf")
            .name("warm scarf")
            .description("A warm scarf.")
            .isWearable
            .isTakable
            .in(.player)

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: scarf
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wear scarf")

        // Then
        await mockIO.expect(
            """
            > wear scarf
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Wear single item")
    func testWearSingleItem() async throws {
        // Given
        let ring = Item("ring")
            .name("gold ring")
            .description("A shiny gold ring.")
            .isWearable
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: ring
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wear ring")

        // Then: Verify state change
        let finalState = await engine.item("ring")
        #expect(await finalState.hasFlag(.isWorn) == true)
        #expect(await finalState.hasFlag(.isTouched) == true)

        // Verify message
        await mockIO.expect(
            """
            > wear ring
            You don the gold ring with practiced ease.
            """
        )
    }

    @Test("Wear multiple items")
    func testWearMultipleItems() async throws {
        // Given
        let shoes = Item("shoes")
            .name("running shoes")
            .description("Comfortable running shoes.")
            .isWearable
            .isTakable
            .in(.player)

        let socks = Item("socks")
            .name("cotton socks")
            .description("Soft cotton socks.")
            .isWearable
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: shoes, socks
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wear shoes and socks")

        // Then
        let finalShoes = await engine.item("shoes")
        let finalSocks = await engine.item("socks")
        #expect(await finalShoes.hasFlag(.isWorn) == true)
        #expect(await finalSocks.hasFlag(.isWorn) == true)

        await mockIO.expect(
            """
            > wear shoes and socks
            You don the running shoes and the cotton socks with practiced
            ease.
            """
        )
    }

    @Test("Wear all with mixed wearable and non-wearable items")
    func testWearAllMixedItems() async throws {
        // Given
        let shirt = Item("shirt")
            .name("white shirt")
            .description("A clean white shirt.")
            .isWearable
            .isTakable
            .in(.player)

        let book = Item("book")
            .name("leather book")
            .description("A bound leather book.")
            .isTakable
            .in(.player)

        let tie = Item("tie")
            .name("silk tie")
            .description("An elegant silk tie.")
            .isWearable
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: shirt, book, tie
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wear all")

        // Then: Only wearable items should be worn
        let finalShirt = await engine.item("shirt")
        let finalBook = await engine.item("book")
        let finalTie = await engine.item("tie")

        #expect(await finalShirt.hasFlag(.isWorn) == true)
        #expect(await finalBook.hasFlag(.isWorn) == false)
        #expect(await finalTie.hasFlag(.isWorn) == true)

        await mockIO.expect(
            """
            > wear all
            You don the white shirt and the silk tie with practiced ease.
            """
        )
    }

    @Test("Wear all with no wearable items")
    func testWearAllNoWearableItems() async throws {
        // Given
        let coin = Item("coin")
            .name("gold coin")
            .description("A valuable gold coin.")
            .isTakable
            .in(.player)

        let key = Item("key")
            .name("brass key")
            .description("A brass key.")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: coin, key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wear all")

        // Then
        await mockIO.expect(
            """
            > wear all
            There is nothing here to wear.
            """
        )
    }

    @Test("Wear all with already worn items")
    func testWearAllWithAlreadyWornItems() async throws {
        // Given
        let hat = Item("hat")
            .name("winter hat")
            .description("A warm winter hat.")
            .isWearable
            .isTakable
            .in(.player)

        let mittens = Item("mittens")
            .name("wool mittens")
            .description("Cozy wool mittens.")
            .isWearable
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: hat, mittens
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up: hat is already worn
        try await engine.apply(
            hat.proxy(engine).setFlag(.isWorn)
        )

        // When
        try await engine.execute("wear all")

        // Then: Only mittens should be newly worn
        let finalHat = await engine.item("hat")
        let finalMittens = await engine.item("mittens")

        #expect(await finalHat.hasFlag(.isWorn) == true)
        #expect(await finalMittens.hasFlag(.isWorn) == true)

        await mockIO.expect(
            """
            > wear all
            You don the wool mittens with practiced ease.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = WearActionHandler()
        #expect(handler.synonyms.contains(.wear))
        #expect(handler.synonyms.contains(.don))
        #expect(handler.synonyms.count == 2)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = WearActionHandler()
        #expect(handler.requiresLight == true)
    }
}
