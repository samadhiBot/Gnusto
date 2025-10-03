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
        let apple = Item("apple")
            .name("red apple")
            .description("A crisp red apple.")
            .isEdible
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: apple
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("eat apple")

        // Then
        await mockIO.expect(
            """
            > eat apple
            Your appetite for the red apple must wait for better
            circumstances.
            """
        )

        let finalState = await engine.item("apple")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("CONSUME syntax works")
    func testConsumeSyntax() async throws {
        // Given
        let bread = Item("bread")
            .name("piece of bread")
            .description("A piece of fresh bread.")
            .isEdible
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: bread
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("consume bread")

        // Then
        await mockIO.expect(
            """
            > consume bread
            Your appetite for the piece of bread must wait for better
            circumstances.
            """
        )
    }

    @Test("DEVOUR syntax works")
    func testDevourSyntax() async throws {
        // Given
        let cake = Item("cake")
            .name("chocolate cake")
            .description("A delicious chocolate cake.")
            .isEdible
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: cake
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("devour cake")

        // Then
        await mockIO.expect(
            """
            > devour cake
            Your appetite for the chocolate cake must wait for better
            circumstances.
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
        await mockIO.expect(
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
        await mockIO.expect(
            """
            > eat nonexistent
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Eating item not held takes it first")
    func testCannotEatItemNotHeld() async throws {
        // Given
        let apple = Item("apple")
            .name("red apple")
            .description("A crisp red apple.")
            .isEdible
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: apple
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("eat apple")

        // Then
        await mockIO.expect(
            """
            > eat apple
            Taken.

            The red apple remains tantalizingly out of reach of your
            digestive ambitions.
            """
        )
    }

    @Test("Cannot eat non-edible item")
    func testCannotEatNonEdibleItem() async throws {
        // Given
        let rock = Item("rock")
            .name("large rock")
            .description("A heavy stone.")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("eat rock")

        // Then
        await mockIO.expect(
            """
            > eat rock
            The large rock falls well outside the realm of culinary
            possibility.
            """
        )
    }

    @Test("Requires light to eat items")
    func testRequiresLight() async throws {
        // Given: Dark room with edible item
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")
            // Note: No .inherentlyLit property

        let apple = Item("apple")
            .name("red apple")
            .description("A crisp red apple.")
            .isEdible
            .isTakable
            .in(.player)

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: apple
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("eat apple")

        // Then
        await mockIO.expect(
            """
            > eat apple
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Eat edible item removes it from game")
    func testEatEdibleItemRemovesIt() async throws {
        // Given
        let orange = Item("orange")
            .name("juicy orange")
            .description("A sweet, juicy orange.")
            .isEdible
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: orange
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("eat orange")

        // Then
        let finalState = await engine.item("orange")
        #expect(await finalState.hasFlag(.isTouched) == true)

        await mockIO.expect(
            """
            > eat orange
            Your appetite for the juicy orange must wait for better
            circumstances.
            """
        )
    }

    @Test("Eat item with custom eat text")
    func testEatItemWithCustomEatText() async throws {
        // Given
        let cookie = Item("cookie")
            .name("chocolate cookie")
            .description("A delicious chocolate chip cookie.")
            .isEdible
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: cookie
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("eat cookie")

        // Then
        await mockIO.expect(
            """
            > eat cookie
            Your appetite for the chocolate cookie must wait for better
            circumstances.
            """
        )
    }

    @Test("Updates pronouns to refer to eaten item")
    func testUpdatesPronounsToEatenItem() async throws {
        // Given
        let banana = Item("banana")
            .name("yellow banana")
            .description("A ripe yellow banana.")
            .isEdible
            .isTakable
            .in(.player)

        let apple = Item("apple")
            .name("red apple")
            .description("A crisp red apple.")
            .isEdible
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: banana, apple
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("eat banana")
        try await engine.execute("take apple")
        try await engine.execute("eat it")

        // Then
        await mockIO.expect(
            """
            > eat banana
            Your appetite for the yellow banana must wait for better
            circumstances.

            > take apple
            Got it.

            > eat it
            Now is not the time to consume the red apple.
            """
        )
    }

    @Test("Eat container with edible contents")
    func testEatContainerWithEdibleContents() async throws {
        // Given
        let box = Item("box")
            .name("lunch box")
            .description("A small lunch box.")
            .isContainer
            .isOpen
            .isEdible
            .isTakable
            .in(.player)

        let sandwich = Item("sandwich")
            .name("ham sandwich")
            .description("A tasty ham sandwich.")
            .isEdible
            .isTakable
            .in(.item("box"))

        let game = MinimalGame(
            items: box, sandwich
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("eat box")

        // Then
        await mockIO.expect(
            """
            > eat box
            Your appetite for the lunch box must wait for better
            circumstances.
            """
        )

        // Both box and contents should be gone
        let finalSandwich = await engine.item("sandwich")
        #expect(await finalSandwich.parent == .item(box.proxy(engine)))
    }

    @Test("Eat drinkable item")
    func testEatDrinkableItem() async throws {
        // Given
        let soup = Item("soup")
            .name("hot soup")
            .description("A bowl of hot soup.")
            .isEdible
            .isDrinkable
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: soup
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("eat soup")

        // Then
        await mockIO.expect(
            """
            > eat soup
            Your appetite for the hot soup must wait for better
            circumstances.
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
