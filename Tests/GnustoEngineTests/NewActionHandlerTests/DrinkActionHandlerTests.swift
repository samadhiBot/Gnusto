import CustomDump
import Testing

@testable import GnustoEngine

@Suite("DrinkActionHandler Tests")
struct DrinkActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("DRINK DIRECTOBJECT syntax works")
    func testDrinkDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let water = Item(
            id: "water",
            .name("glass of water"),
            .description("A clear glass of water."),
            .isDrinkable,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: water
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("drink water")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > drink water
            You drink the glass of water. Refreshing!
            """)

        let finalState = try await engine.item("water")
        #expect(finalState.parent == .nowhere)
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("SIP syntax works")
    func testSipSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let coffee = Item(
            id: "coffee",
            .name("cup of coffee"),
            .description("A steaming cup of coffee."),
            .isDrinkable,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: coffee
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("sip coffee")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > sip coffee
            You drink the cup of coffee. Refreshing!
            """)

        let finalState = try await engine.item("coffee")
        #expect(finalState.parent == .nowhere)
    }

    @Test("IMBIBE syntax works")
    func testImbibeSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let potion = Item(
            id: "potion",
            .name("magic potion"),
            .description("A mysterious magic potion."),
            .isDrinkable,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: potion
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("imbibe potion")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > imbibe potion
            You drink the magic potion. Refreshing!
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot drink without specifying what")
    func testCannotDrinkWithoutWhat() async throws {
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
        try await engine.execute("drink")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > drink
            Drink what?
            """)
    }

    @Test("Cannot drink non-existent item")
    func testCannotDrinkNonExistentItem() async throws {
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
        try await engine.execute("drink nonexistent")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > drink nonexistent
            You can't see any such thing.
            """)
    }

    @Test("Cannot drink item not held")
    func testCannotDrinkItemNotHeld() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let water = Item(
            id: "water",
            .name("glass of water"),
            .description("A clear glass of water."),
            .isDrinkable,
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: water
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("drink water")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > drink water
            You aren't holding the glass of water.
            """)
    }

    @Test("Cannot drink non-drinkable item")
    func testCannotDrinkNonDrinkableItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rock = Item(
            id: "rock",
            .name("large rock"),
            .description("A heavy stone."),
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
        try await engine.execute("drink rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > drink rock
            You can't drink the large rock.
            """)
    }

    @Test("Requires light to drink items")
    func testRequiresLight() async throws {
        // Given: Dark room with drinkable item
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let water = Item(
            id: "water",
            .name("glass of water"),
            .description("A clear glass of water."),
            .isDrinkable,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: water
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("drink water")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > drink water
            It is pitch black. You can't see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Drink drinkable item removes it from game")
    func testDrinkDrinkableItemRemovesIt() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let juice = Item(
            id: "juice",
            .name("orange juice"),
            .description("A glass of fresh orange juice."),
            .isDrinkable,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: juice
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("drink juice")

        // Then
        let finalState = try await engine.item("juice")
        #expect(finalState.parent == .nowhere)
        #expect(finalState.hasFlag(.isTouched) == true)

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > drink juice
            You drink the orange juice. Refreshing!
            """)
    }

    @Test("Drink item with custom drink text")
    func testDrinkItemWithCustomDrinkText() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let elixir = Item(
            id: "elixir",
            .name("healing elixir"),
            .description("A shimmering healing elixir."),
            .isDrinkable,
//            .drinkText("The elixir tastes magical and you feel your strength returning."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: elixir
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("drink elixir")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > drink elixir
            The elixir tastes magical and you feel your strength returning.
            """)

        let finalState = try await engine.item("elixir")
        #expect(finalState.parent == .nowhere)
    }

    @Test("Drink from open container with drinkable contents")
    func testDrinkFromOpenContainerWithDrinkableContents() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let bottle = Item(
            id: "bottle",
            .name("glass bottle"),
            .description("A clear glass bottle."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.player)
        )

        let wine = Item(
            id: "wine",
            .name("red wine"),
            .description("Rich red wine."),
            .isDrinkable,
            .isTakable,
            .in(.item("bottle"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: bottle, wine
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("drink bottle")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > drink bottle
            You drink the red wine from the glass bottle.
            """)

        // Wine should be consumed, bottle should remain
        let finalBottle = try await engine.item("bottle")
        let finalWine = try await engine.item("wine")
        #expect(finalBottle.parent == .player)
        #expect(finalWine.parent == .nowhere)
    }

    @Test("Drink from closed container fails")
    func testDrinkFromClosedContainerFails() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let bottle = Item(
            id: "bottle",
            .name("sealed bottle"),
            .description("A sealed bottle."),
            .isContainer,
            // Note: Not open
            .isTakable,
            .in(.player)
        )

        let water = Item(
            id: "water",
            .name("pure water"),
            .description("Crystal clear water."),
            .isDrinkable,
            .isTakable,
            .in(.item("bottle"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: bottle, water
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("drink bottle")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > drink bottle
            You can't drink from the sealed bottle while it's closed.
            """)
    }

    @Test("Drink from container with no drinkable contents")
    func testDrinkFromContainerWithNoDrinkableContents() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let cup = Item(
            id: "cup",
            .name("empty cup"),
            .description("An empty ceramic cup."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: cup
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("drink cup")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > drink cup
            There's nothing to drink in the empty cup.
            """)
    }

    @Test("Updates pronouns to refer to drunk item")
    func testUpdatesPronounsToDrunkItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let tea = Item(
            id: "tea",
            .name("hot tea"),
            .description("A cup of steaming hot tea."),
            .isDrinkable,
            .isTakable,
            .in(.player)
        )

        let water = Item(
            id: "water",
            .name("cold water"),
            .description("A glass of cold water."),
            .isDrinkable,
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: tea, water
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("drink tea")
        try await engine.execute("take water")
        try await engine.execute("drink it")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > drink tea
            You drink the hot tea. Refreshing!
            > take water
            Taken.
            > drink it
            You drink the cold water. Refreshing!
            """)
    }

    @Test("Drink edible and drinkable item")
    func testDrinkEdibleAndDrinkableItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let smoothie = Item(
            id: "smoothie",
            .name("fruit smoothie"),
            .description("A thick fruit smoothie."),
            .isDrinkable,
            .isEdible,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: smoothie
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("drink smoothie")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > drink smoothie
            You drink the fruit smoothie. Refreshing!
            """)

        let finalState = try await engine.item("smoothie")
        #expect(finalState.parent == .nowhere)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = DrinkActionHandler()
        #expect(handler.actions.contains(.drink))
        #expect(handler.actions.count == 1)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = DrinkActionHandler()
        #expect(handler.verbs.contains(.drink))
        #expect(handler.verbs.contains(.sip))
        #expect(handler.verbs.contains(.imbibe))
        #expect(handler.verbs.count == 3)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = DrinkActionHandler()
        #expect(handler.requiresLight == true)
    }
}
