import Testing
import CustomDump
@testable import GnustoEngine

@Suite("TasteActionHandler Tests")
struct TasteActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("TASTE DIRECTOBJECT syntax works")
    func testTasteDirectObjectSyntax() async throws {
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
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: apple
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("taste apple")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > taste apple
            That tastes about average.
            """)
    }

    @Test("LICK syntax works")
    func testLickSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let candy = Item(
            id: "candy",
            .name("lollipop"),
            .description("A colorful lollipop."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: candy
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("lick lollipop")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > lick lollipop
            That tastes about average.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot taste without specifying target")
    func testCannotTasteWithoutTarget() async throws {
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
        try await engine.execute("taste")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > taste
            Taste what?
            """)
    }

    @Test("Cannot taste target not in scope")
    func testCannotTasteTargetNotInScope() async throws {
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

        let remoteCake = Item(
            id: "remoteCake",
            .name("remote cake"),
            .description("A cake in another room."),
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteCake
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("taste cake")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > taste cake
            You can’t see any such thing.
            """)
    }

    @Test("Taste works in dark room")
    func testTasteWorksInDarkRoom() async throws {
        // Given: Dark room with an object to taste
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let bread = Item(
            id: "bread",
            .name("stale bread"),
            .description("A piece of stale bread."),
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: bread
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("taste bread")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > taste bread
            You can’t see any such thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Taste object in room")
    func testTasteObjectInRoom() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let berry = Item(
            id: "berry",
            .name("wild berry"),
            .description("A small wild berry."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: berry
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("taste berry")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > taste berry
            That tastes about average.
            """)
    }

    @Test("Taste held item")
    func testTasteHeldItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let chocolate = Item(
            id: "chocolate",
            .name("chocolate bar"),
            .description("A sweet chocolate bar."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: chocolate
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("taste chocolate")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > taste chocolate
            That tastes about average.
            """)
    }

    @Test("Taste object in open container")
    func testTasteObjectInOpenContainer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let bowl = Item(
            id: "bowl",
            .name("fruit bowl"),
            .description("A bowl filled with fruit."),
            .isContainer,
            .isOpenable,
            .isOpen,
            .in(.location("testRoom"))
        )

        let orange = Item(
            id: "orange",
            .name("fresh orange"),
            .description("A juicy fresh orange."),
            .in(.item("bowl"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: bowl, orange
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("taste orange")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > taste orange
            That tastes about average.
            """)
    }

    @Test("Taste sequence of different foods")
    func testTasteSequenceOfDifferentFoods() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let cookie = Item(
            id: "cookie",
            .name("sugar cookie"),
            .description("A sweet sugar cookie."),
            .in(.location("testRoom"))
        )

        let milk = Item(
            id: "milk",
            .name("glass of milk"),
            .description("A cold glass of milk."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: cookie, milk
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("taste cookie")
        try await engine.execute("lick milk")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > taste cookie
            That tastes about average.
            > lick milk
            That tastes about average.
            """)
    }

    @Test("Different taste syntax variations")
    func testDifferentTasteSyntaxVariations() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let iceCream = Item(
            id: "iceCream",
            .name("vanilla ice cream"),
            .description("A scoop of vanilla ice cream."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: iceCream
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("taste ice cream")
        try await engine.execute("lick ice cream")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > taste ice cream
            That tastes about average.
            > lick ice cream
            That tastes about average.
            """)
    }

    @Test("Taste unusual objects")
    func testTasteUnusualObjects() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rock = Item(
            id: "rock",
            .name("smooth rock"),
            .description("A smooth stone."),
            .in(.location("testRoom"))
        )

        let metal = Item(
            id: "metal",
            .name("copper coin"),
            .description("A tarnished copper coin."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rock, metal
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("taste rock")
        try await engine.execute("lick coin")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > taste rock
            That tastes about average.
            > lick coin
            That tastes about average.
            """)
    }

    @Test("Multiple taste attempts")
    func testMultipleTasteAttempts() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let soup = Item(
            id: "soup",
            .name("bowl of soup"),
            .description("A warm bowl of soup."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: soup
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("taste soup")
        try await engine.execute("taste soup")
        try await engine.execute("lick soup")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > taste soup
            That tastes about average.
            > taste soup
            That tastes about average.
            > lick soup
            That tastes about average.
            """)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Intents")
    func testIntents() async throws {
        let handler = TasteActionHandler()
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = TasteActionHandler()
        #expect(handler.verbs.contains(.taste))
        #expect(handler.verbs.contains(.lick))
        #expect(handler.verbs.count == 2)
    }

    @Test("Handler does not require light")
    func testDoesNotRequireLight() async throws {
        let handler = TasteActionHandler()
        #expect(handler.requiresLight == false)
    }
}
