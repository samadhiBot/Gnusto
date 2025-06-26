import CustomDump
import Testing

@testable import GnustoEngine

@Suite("WearActionHandler Tests")
struct WearActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("WEAR DIRECTOBJECT syntax works")
    func testWearDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let hat = Item(
            id: "hat",
            .name("red hat"),
            .description("A stylish red hat."),
            .isWearable,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: hat
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wear hat")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wear hat
            You put on the red hat.
            """)

        let finalState = try await engine.item("hat")
        #expect(finalState.hasFlag(.isWorn) == true)
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("PUT ON DIRECTOBJECT syntax works")
    func testPutOnSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let jacket = Item(
            id: "jacket",
            .name("leather jacket"),
            .description("A worn leather jacket."),
            .isWearable,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: jacket
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("put on jacket")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > put on jacket
            You put on the leather jacket.
            """)

        let finalState = try await engine.item("jacket")
        #expect(finalState.hasFlag(.isWorn) == true)
    }

    @Test("DON syntax works")
    func testDonSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let cloak = Item(
            id: "cloak",
            .name("dark cloak"),
            .description("A mysterious dark cloak."),
            .isWearable,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: cloak
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("don cloak")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > don cloak
            You put on the dark cloak.
            """)
    }

    @Test("WEAR ALL syntax works")
    func testWearAllSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let hat = Item(
            id: "hat",
            .name("blue hat"),
            .description("A blue hat."),
            .isWearable,
            .isTakable,
            .in(.player)
        )

        let gloves = Item(
            id: "gloves",
            .name("wool gloves"),
            .description("Warm wool gloves."),
            .isWearable,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: hat, gloves
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wear all")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wear all
            You put on the blue hat and the wool gloves.
            """)

        let finalHat = try await engine.item("hat")
        let finalGloves = try await engine.item("gloves")
        #expect(finalHat.hasFlag(.isWorn) == true)
        #expect(finalGloves.hasFlag(.isWorn) == true)
    }

    // MARK: - Validation Testing

    @Test("Cannot wear without specifying what")
    func testCannotWearWithoutWhat() async throws {
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
        try await engine.execute("wear")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wear
            Wear what?
            """)
    }

    @Test("Cannot wear item not held")
    func testCannotWearItemNotHeld() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let hat = Item(
            id: "hat",
            .name("fancy hat"),
            .description("A fancy hat."),
            .isWearable,
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: hat
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wear hat")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wear hat
            You aren’t holding the fancy hat.
            """)
    }

    @Test("Cannot wear non-wearable item")
    func testCannotWearNonWearableItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rock = Item(
            id: "rock",
            .name("heavy rock"),
            .description("A heavy rock."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wear rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wear rock
            You can’t wear the heavy rock.
            """)
    }

    @Test("Cannot wear already worn item")
    func testCannotWearAlreadyWornItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let boots = Item(
            id: "boots",
            .name("hiking boots"),
            .description("Sturdy hiking boots."),
            .isWearable,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: boots
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up: boots are already worn
        try await engine.apply(
            await engine.setFlag(.isWorn, on: try await engine.item("boots"))
        )

        // When
        try await engine.execute("wear boots")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wear boots
            You're already wearing the hiking boots.
            """)
    }

    @Test("Requires light to wear")
    func testRequiresLight() async throws {
        // Given: Dark room with wearable item
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let scarf = Item(
            id: "scarf",
            .name("warm scarf"),
            .description("A warm scarf."),
            .isWearable,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: scarf
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wear scarf")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wear scarf
            It is pitch black. You can’t see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Wear single item")
    func testWearSingleItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let ring = Item(
            id: "ring",
            .name("gold ring"),
            .description("A shiny gold ring."),
            .isWearable,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: ring
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wear ring")

        // Then: Verify state change
        let finalState = try await engine.item("ring")
        #expect(finalState.hasFlag(.isWorn) == true)
        #expect(finalState.hasFlag(.isTouched) == true)

        // Verify message
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wear ring
            You put on the gold ring.
            """)
    }

    @Test("Wear multiple items")
    func testWearMultipleItems() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let shoes = Item(
            id: "shoes",
            .name("running shoes"),
            .description("Comfortable running shoes."),
            .isWearable,
            .isTakable,
            .in(.player)
        )

        let socks = Item(
            id: "socks",
            .name("cotton socks"),
            .description("Soft cotton socks."),
            .isWearable,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: shoes, socks
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wear shoes and socks")

        // Then
        let finalShoes = try await engine.item("shoes")
        let finalSocks = try await engine.item("socks")
        #expect(finalShoes.hasFlag(.isWorn) == true)
        #expect(finalSocks.hasFlag(.isWorn) == true)

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wear shoes and socks
            You put on the running shoes and the cotton socks.
            """)
    }

    @Test("Wear all with mixed wearable and non-wearable items")
    func testWearAllMixedItems() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let shirt = Item(
            id: "shirt",
            .name("white shirt"),
            .description("A clean white shirt."),
            .isWearable,
            .isTakable,
            .in(.player)
        )

        let book = Item(
            id: "book",
            .name("leather book"),
            .description("A bound leather book."),
            .isTakable,
            .in(.player)
        )

        let tie = Item(
            id: "tie",
            .name("silk tie"),
            .description("An elegant silk tie."),
            .isWearable,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: shirt, book, tie
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wear all")

        // Then: Only wearable items should be worn
        let finalShirt = try await engine.item("shirt")
        let finalBook = try await engine.item("book")
        let finalTie = try await engine.item("tie")

        #expect(finalShirt.hasFlag(.isWorn) == true)
        #expect(finalBook.hasFlag(.isWorn) == false)
        #expect(finalTie.hasFlag(.isWorn) == true)

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wear all
            You put on the white shirt and the silk tie.
            """)
    }

    @Test("Wear all with no wearable items")
    func testWearAllNoWearableItems() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .description("A valuable gold coin."),
            .isTakable,
            .in(.player)
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
            items: coin, key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wear all")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wear all
            There’s nothing here you can wear.
            """)
    }

    @Test("Wear all with already worn items")
    func testWearAllWithAlreadyWornItems() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let hat = Item(
            id: "hat",
            .name("winter hat"),
            .description("A warm winter hat."),
            .isWearable,
            .isTakable,
            .in(.player)
        )

        let mittens = Item(
            id: "mittens",
            .name("wool mittens"),
            .description("Cozy wool mittens."),
            .isWearable,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: hat, mittens
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up: hat is already worn
        try await engine.apply(
            await engine.setFlag(.isWorn, on: try await engine.item("hat"))
        )

        // When
        try await engine.execute("wear all")

        // Then: Only mittens should be newly worn
        let finalHat = try await engine.item("hat")
        let finalMittens = try await engine.item("mittens")

        #expect(finalHat.hasFlag(.isWorn) == true)
        #expect(finalMittens.hasFlag(.isWorn) == true)

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wear all
            You put on the wool mittens.
            """)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Intents")
    func testIntents() async throws {
        let handler = WearActionHandler()
        // WearActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = WearActionHandler()
        #expect(handler.verbs.contains(.wear))
        #expect(handler.verbs.contains(.don))
        #expect(handler.verbs.count == 2)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = WearActionHandler()
        #expect(handler.requiresLight == true)
    }
}
