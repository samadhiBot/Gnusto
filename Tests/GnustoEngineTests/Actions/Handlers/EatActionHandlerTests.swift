import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("EatActionHandler Tests")
struct EatActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("EAT DIRECTOBJECT syntax works")
    func testEatDirectObjectSyntax() async throws {
        // Given
        let apple = Item(
            id: "apple",
            .name("red apple"),
            .description("A crisp red apple."),
            .isEdible,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: apple
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("eat apple")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > eat apple
            Now is not the time to consume the red apple.
            """
        )

        let finalState = await engine.item("apple")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("CONSUME syntax works")
    func testConsumeSyntax() async throws {
        // Given
        let bread = Item(
            id: "bread",
            .name("piece of bread"),
            .description("A piece of fresh bread."),
            .isEdible,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: bread
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("consume bread")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > consume bread
            Now is not the time to consume the piece of bread.
            """
        )
    }

    @Test("DEVOUR syntax works")
    func testDevourSyntax() async throws {
        // Given
        let cake = Item(
            id: "cake",
            .name("chocolate cake"),
            .description("A delicious chocolate cake."),
            .isEdible,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: cake
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("devour cake")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > devour cake
            Now is not the time to consume the chocolate cake.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot eat without specifying what")
    func testCannotEatWithoutWhat() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("eat")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > eat
            Eat what?
            """
        )
    }

    @Test("Cannot eat non-existent item")
    func testCannotEatNonExistentItem() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("eat nonexistent")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > eat nonexistent
            Any such thing remains frustratingly inaccessible.
            """
        )
    }

    @Test("Eating item not held takes it first")
    func testCannotEatItemNotHeld() async throws {
        // Given
        let apple = Item(
            id: "apple",
            .name("red apple"),
            .description("A crisp red apple."),
            .isEdible,
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: apple
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("eat apple")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > eat apple
            Acquired.

            Your appetite for the red apple must wait for better
            circumstances.
            """
        )
    }

    @Test("Cannot eat non-edible item")
    func testCannotEatNonEdibleItem() async throws {
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
        try await engine.execute("eat rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > eat rock
            Your digestive system firmly vetoes the consumption of the
            large rock.
            """
        )
    }

    @Test("Requires light to eat items")
    func testRequiresLight() async throws {
        // Given: Dark room with edible item
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let apple = Item(
            id: "apple",
            .name("red apple"),
            .description("A crisp red apple."),
            .isEdible,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: apple
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("eat apple")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > eat apple
            You stand in a depthless black where even your thoughts seem to
            whisper, careful not to make a sound.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Eat edible item removes it from game")
    func testEatEdibleItemRemovesIt() async throws {
        // Given
        let orange = Item(
            id: "orange",
            .name("juicy orange"),
            .description("A sweet, juicy orange."),
            .isEdible,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: orange
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("eat orange")

        // Then
        let finalState = await engine.item("orange")
        #expect(await finalState.hasFlag(.isTouched) == true)

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > eat orange
            Now is not the time to consume the juicy orange.
            """
        )
    }

    @Test("Eat item with custom eat text")
    func testEatItemWithCustomEatText() async throws {
        // Given
        let cookie = Item(
            id: "cookie",
            .name("chocolate cookie"),
            .description("A delicious chocolate chip cookie."),
            .isEdible,
            //            .eatText("The cookie is absolutely delicious! You feel satisfied."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: cookie
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("eat cookie")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > eat cookie
            Now is not the time to consume the chocolate cookie.
            """
        )
    }

    @Test("Updates pronouns to refer to eaten item")
    func testUpdatesPronounsToEatenItem() async throws {
        // Given
        let banana = Item(
            id: "banana",
            .name("yellow banana"),
            .description("A ripe yellow banana."),
            .isEdible,
            .isTakable,
            .in(.player)
        )

        let apple = Item(
            id: "apple",
            .name("red apple"),
            .description("A crisp red apple."),
            .isEdible,
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: banana, apple
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("eat banana")
        try await engine.execute("take apple")
        try await engine.execute("eat it")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > eat banana
            Now is not the time to consume the yellow banana.

            > take apple
            Taken.

            > eat it
            The red apple remains tantalizingly out of reach of your
            digestive ambitions.
            """
        )
    }

    @Test("Eat container with edible contents")
    func testEatContainerWithEdibleContents() async throws {
        // Given
        let box = Item(
            id: "box",
            .name("lunch box"),
            .description("A small lunch box."),
            .isContainer,
            .isOpen,
            .isEdible,
            .isTakable,
            .in(.player)
        )

        let sandwich = Item(
            id: "sandwich",
            .name("ham sandwich"),
            .description("A tasty ham sandwich."),
            .isEdible,
            .isTakable,
            .in(.item("box"))
        )

        let game = MinimalGame(
            items: box, sandwich
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("eat box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > eat box
            Now is not the time to consume the lunch box.
            """
        )

        // Both box and contents should be gone
        let finalSandwich = await engine.item("sandwich")
        #expect(await finalSandwich.parent == .item(box.proxy(engine)))
    }

    @Test("Eat drinkable item")
    func testEatDrinkableItem() async throws {
        // Given
        let soup = Item(
            id: "soup",
            .name("hot soup"),
            .description("A bowl of hot soup."),
            .isEdible,
            .isDrinkable,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: soup
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("eat soup")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > eat soup
            Now is not the time to consume the hot soup.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = EatActionHandler()
        #expect(handler.synonyms.contains(.eat))
        #expect(handler.synonyms.contains(.consume))
        #expect(handler.synonyms.contains(.devour))
        #expect(handler.synonyms.count == 3)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = EatActionHandler()
        #expect(handler.requiresLight == true)
    }
}
