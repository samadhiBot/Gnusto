import Testing
import CustomDump
@testable import GnustoEngine

@Suite("ChompActionHandler Tests")
struct ChompActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("CHOMP DIRECTOBJECT syntax works")
    func testChompDirectObjectSyntax() async throws {
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
            .description("A juicy red apple."),
            .isEdible,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: apple
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("chomp apple")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > chomp apple
            You chomp on a red apple. It's quite tasty!
            """)

        let finalState = try await engine.item("apple")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("BITE syntax works")
    func testBiteSyntax() async throws {
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
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: bread
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("bite bread")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > bite bread
            You chomp on a piece of bread. It's quite tasty!
            """)
    }

    @Test("CHEW syntax works")
    func testChewSyntax() async throws {
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
        try await engine.execute("chew")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > chew
            You chew thoughtfully on nothing.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot chomp item not in scope")
    func testCannotChompItemNotInScope() async throws {
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

        let remoteApple = Item(
            id: "remoteApple",
            .name("remote apple"),
            .description("An apple in another room."),
            .isEdible,
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteApple
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("chomp apple")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > chomp apple
            You can't see any such thing.
            """)
    }

    @Test("Requires light to chomp on items")
    func testRequiresLight() async throws {
        // Given: Dark room with an edible item
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let apple = Item(
            id: "apple",
            .name("red apple"),
            .description("A juicy red apple."),
            .isEdible,
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: apple
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("chomp apple")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > chomp apple
            It is pitch black. You can't see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Chomp without object gives general response")
    func testChompWithoutObject() async throws {
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
        try await engine.execute("chomp")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > chomp
            You chomp thoughtfully on nothing.
            """)
    }

    @Test("Chomp on edible item")
    func testChompOnEdibleItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let cookie = Item(
            id: "cookie",
            .name("chocolate cookie"),
            .description("A delicious chocolate cookie."),
            .isEdible,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: cookie
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("chomp cookie")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > chomp cookie
            You chomp on a chocolate cookie. It's quite tasty!
            """)

        let finalState = try await engine.item("cookie")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Chomp on character")
    func testChompOnCharacter() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let castleGuard = Item(
            id: "guard",
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
        try await engine.execute("chomp guard")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > chomp guard
            I don't think the castle guard would appreciate that.
            """)

        let finalState = try await engine.item("castleGuard")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Chomp on regular item")
    func testChompOnRegularItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rock = Item(
            id: "rock",
            .name("smooth rock"),
            .description("A smooth, round rock."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("chomp rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > chomp rock
            You gnaw on the smooth rock, but it's not very satisfying.
            """)

        let finalState = try await engine.item("rock")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = ChompActionHandler()
        // ChompActionHandler doesn't specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = ChompActionHandler()
        #expect(handler.verbs.contains(.chomp))
        #expect(handler.verbs.contains(.bite))
        #expect(handler.verbs.contains(.chew))
        #expect(handler.verbs.count == 3)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = ChompActionHandler()
        #expect(handler.requiresLight == true)
    }
}
