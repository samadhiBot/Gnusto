import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("DrinkActionHandler Tests")
struct DrinkActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("DRINK DIRECTOBJECT syntax works")
    func testDrinkDirectObjectSyntax() async throws {
        // Given
        let water = Item(
            id: "water",
            .name("glass of water"),
            .description("A clear glass of water."),
            .isDrinkable,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
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
            Circumstances conspire against drinking the glass of water at
            present.
            """
        )

        let finalState = await engine.item("water")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("SIP syntax works")
    func testSipSyntax() async throws {
        // Given
        let coffee = Item(
            id: "coffee",
            .name("cup of coffee"),
            .description("A steaming cup of coffee."),
            .isDrinkable,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
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
            Circumstances conspire against drinking the cup of coffee at
            present.
            """
        )
    }

    @Test("IMBIBE syntax works")
    func testImbibeSyntax() async throws {
        // Given
        let potion = Item(
            id: "potion",
            .name("magic potion"),
            .description("A mysterious magic potion."),
            .isDrinkable,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
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
            Circumstances conspire against drinking the magic potion at
            present.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot drink without specifying what")
    func testCannotDrinkWithoutWhat() async throws {
        // Given
        let game = MinimalGame()
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
            """
        )
    }

    @Test("Cannot drink non-existent item")
    func testCannotDrinkNonExistentItem() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("drink nonexistent")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > drink nonexistent
            Any such thing remains frustratingly inaccessible.
            """
        )
    }

    @Test("Cannot drink item not held")
    func testCannotDrinkItemNotHeld() async throws {
        // Given
        let water = Item(
            id: "water",
            .name("glass of water"),
            .description("A clear glass of water."),
            .isDrinkable,
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
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
            Circumstances conspire against drinking the glass of water at
            present.
            """
        )
    }

    @Test("Cannot drink non-drinkable item")
    func testCannotDrinkNonDrinkableItem() async throws {
        // Given
        let rock = Item(
            id: "rock",
            .name("large rock"),
            .description("A heavy stone."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
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
            Your throat closes at the mere thought of drinking the large
            rock.
            """
        )
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
            You stand in a depthless black where even your thoughts seem to
            whisper, careful not to make a sound.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Drink drinkable item removes it from game")
    func testDrinkDrinkableItemRemovesIt() async throws {
        // Given
        let juice = Item(
            id: "juice",
            .name("orange juice"),
            .description("A glass of fresh orange juice."),
            .isDrinkable,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: juice
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("drink juice")

        // Then
        let finalState = await engine.item("juice")
        #expect(await finalState.hasFlag(.isTouched) == true)

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > drink juice
            Circumstances conspire against drinking the orange juice at
            present.
            """
        )
    }

    @Test("Drink item with custom drink text")
    func testDrinkItemWithCustomDrinkText() async throws {
        // Given
        let elixir = Item(
            id: "elixir",
            .name("healing elixir"),
            .description("A shimmering healing elixir."),
            .isDrinkable,
            .isTakable,
            .in(.player)
        )

        let elixirHandler = ItemEventHandler { engine, event -> ActionResult? in
            guard case .beforeTurn(let command) = event, command.verb == .drink else {
                return nil
            }
            return ActionResult(
                "The elixir tastes magical and you feel your strength returning.",
                await elixir.proxy(engine).remove()
            )
        }

        let game = MinimalGame(
            items: elixir,
            itemEventHandlers: [elixir.id: elixirHandler]
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
            """
        )
    }

    @Test("Drink from open container with drinkable contents")
    func testDrinkFromOpenContainerWithDrinkableContents() async throws {
        // Given
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
            Circumstances conspire against drinking the red wine at
            present.
            """
        )

        // Wine should be consumed, bottle should remain
        let finalBottle = await engine.item("bottle")
        #expect(await finalBottle.playerIsHolding)
    }

    @Test("Drink from closed container fails")
    func testDrinkFromClosedContainerFails() async throws {
        // Given
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
            Circumstances conspire against drinking the pure water at
            present.
            """
        )
    }

    @Test("Drink from container with no drinkable contents")
    func testDrinkFromContainerWithNoDrinkableContents() async throws {
        // Given
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
            Your hopes for liquid refreshment in the empty cup are sadly
            misplaced.
            """
        )
    }

    @Test("Updates pronouns to refer to drunk item")
    func testUpdatesPronounsToDrunkItem() async throws {
        // Given
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
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: tea, water
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute(
            "drink tea",
            "take water",
            "drink it"
        )

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > drink tea
            Circumstances conspire against drinking the hot tea at present.

            > take water
            Taken.

            > drink it
            The cold water must wait for a more opportune moment of
            consumption.
            """
        )
    }

    @Test("Drink edible and drinkable item")
    func testDrinkEdibleAndDrinkableItem() async throws {
        // Given
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
            Circumstances conspire against drinking the fruit smoothie at
            present.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = DrinkActionHandler()
        expectNoDifference(handler.synonyms, [.drink, .sip, .quaff, .imbibe])
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = DrinkActionHandler()
        #expect(handler.requiresLight == true)
    }
}
