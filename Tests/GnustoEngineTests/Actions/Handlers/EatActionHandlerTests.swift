import CustomDump
import Testing

@testable import GnustoEngine

@Suite("EatActionHandler Tests")
struct EatActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("EAT DIRECTOBJECT syntax works")
    func testEatDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
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
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            You eat the red apple. Not bad.
            """)

        let finalState = try await engine.item("apple")
        #expect(finalState.parent == .nowhere)
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("CONSUME syntax works")
    func testConsumeSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let bread = Item(
            id: "bread",
            .name("piece of bread"),
            .description("A piece of fresh bread."),
            .isEdible,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            You eat the piece of bread. Not bad.
            """)

        let finalState = try await engine.item("bread")
        #expect(finalState.parent == .nowhere)
    }

    @Test("DEVOUR syntax works")
    func testDevourSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let cake = Item(
            id: "cake",
            .name("chocolate cake"),
            .description("A delicious chocolate cake."),
            .isEdible,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            You eat the chocolate cake. Not bad.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot eat without specifying what")
    func testCannotEatWithoutWhat() async throws {
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
        try await engine.execute("eat")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > eat
            Eat what?
            """)
    }

    @Test("Cannot eat non-existent item")
    func testCannotEatNonExistentItem() async throws {
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
        try await engine.execute("eat nonexistent")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > eat nonexistent
            You can’t see any such thing.
            """)
    }

    @Test("Cannot eat item not held")
    func testCannotEatItemNotHeld() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let apple = Item(
            id: "apple",
            .name("red apple"),
            .description("A crisp red apple."),
            .isEdible,
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            You aren’t holding the red apple.
            """)
    }

    @Test("Cannot eat non-edible item")
    func testCannotEatNonEdibleItem() async throws {
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
        try await engine.execute("eat rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > eat rock
            You can’t eat the large rock.
            """)
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
            It is pitch black. You can’t see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Eat edible item removes it from game")
    func testEatEdibleItemRemovesIt() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let orange = Item(
            id: "orange",
            .name("juicy orange"),
            .description("A sweet, juicy orange."),
            .isEdible,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: orange
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("eat orange")

        // Then
        let finalState = try await engine.item("orange")
        #expect(finalState.parent == .nowhere)
        #expect(finalState.hasFlag(.isTouched) == true)

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > eat orange
            You eat the juicy orange. Not bad.
            """)
    }

    @Test("Eat item with custom eat text")
    func testEatItemWithCustomEatText() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

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
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            The cookie is absolutely delicious! You feel satisfied.
            """)

        let finalState = try await engine.item("cookie")
        #expect(finalState.parent == .nowhere)
    }

    @Test("Updates pronouns to refer to eaten item")
    func testUpdatesPronounsToEatenItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

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
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            You eat the yellow banana. Not bad.
            > take apple
            Taken.
            > eat it
            You eat the red apple. Not bad.
            """)
    }

    @Test("Eat container with edible contents")
    func testEatContainerWithEdibleContents() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

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
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            You eat the lunch box. Not bad.
            """)

        // Both box and contents should be gone
        let finalBox = try await engine.item("box")
        let finalSandwich = try await engine.item("sandwich")
        #expect(finalBox.parent == .nowhere)
        #expect(finalSandwich.parent == .nowhere)
    }

    @Test("Eat drinkable item")
    func testEatDrinkableItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

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
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            You eat the hot soup. Not bad.
            """)

        let finalState = try await engine.item("soup")
        #expect(finalState.parent == .nowhere)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Intents")
    func testIntents() async throws {
        let handler = EatActionHandler()
        #expect(handler.actions.contains(.eat))
        #expect(handler.actions.count == 1)
    }

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = EatActionHandler()
        #expect(handler.verbs.contains(.eat))
        #expect(handler.verbs.contains(.consume))
        #expect(handler.verbs.contains(.devour))
        #expect(handler.verbs.count == 3)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = EatActionHandler()
        #expect(handler.requiresLight == true)
    }
}
