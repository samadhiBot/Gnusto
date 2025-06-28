import CustomDump
import Testing

@testable import GnustoEngine

@Suite("ChompActionHandler Tests")
struct ChompActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("CHOMP DIRECTOBJECT syntax works with disambiguation")
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

        // When: CHOMP on edible item should ask for disambiguation
        try await engine.execute("chomp apple")

        // Then: Should ask whether to eat it
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > chomp apple
            Do you mean you want to eat the red apple?
            """)

        // Verify question is pending
        let hasPending = await ConversationManager.hasPendingQuestion(engine: engine)
        #expect(hasPending == true)
    }

    @Test("CHOMP disambiguation - YES response eats the item")
    func testChompDisambiguationYes() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
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

        // When: CHOMP then YES
        try await engine.execute("chomp apple", "yes")

        // Then: Should eat the apple (delegate to EatActionHandler)
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > chomp apple
            Do you mean you want to eat the red apple?

            > yes
            You eat the red apple. It’s quite satisfying.
            """)

        // Apple should be gone (moved to .nowhere)
        let finalState = try await engine.item("apple")
        #expect(finalState.parent == .nowhere)
    }

    @Test("CHOMP disambiguation - NO response just takes a bite")
    func testChompDisambiguationNo() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
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

        // When: CHOMP then NO
        try await engine.execute("chomp apple", "no")

        // Then: Should just decline
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > chomp apple
            Do you mean you want to eat the red apple?

            > no
            Okay, never mind.
            """)

        // Apple should still be in the room
        let finalState = try await engine.item("apple")
        #expect(finalState.parent == .location("testRoom"))
    }

    @Test("BITE syntax works with disambiguation")
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

        // Then: Should ask for disambiguation
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > bite bread
            Do you mean you want to eat the piece of bread?
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
        expectNoDifference(
            output,
            """
            > chew
            Your molars meet in a tragic tale of unrequited mastication.
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
        expectNoDifference(
            output,
            """
            > chomp apple
            You can’t see any such thing.
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
        expectNoDifference(
            output,
            """
            > chomp apple
            It is pitch black. You can’t see a thing.
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
        expectNoDifference(
            output,
            """
            > chomp
            Your molars meet in a tragic tale of unrequited mastication.
            """)
    }

    @Test("Chomp on edible item asks for disambiguation")
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

        // Then: Should ask for disambiguation
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > chomp cookie
            Do you mean you want to eat the chocolate cookie?
            """)

        // Verify question is pending
        let hasPending = await ConversationManager.hasPendingQuestion(engine: engine)
        #expect(hasPending == true)
    }

    @Test("Chomp on character gives humorous response")
    func testChompOnCharacter() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let castleGuard = Item(
            id: "castleGuard",
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

        // Then: Should give humorous response directly (no disambiguation)
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > chomp guard
            You sink your teeth into the castle guard and immediately
            regret skipping lunch.
            """)

        let finalState = try await engine.item("castleGuard")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Chomp on regular item gives humorous response")
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

        // Then: Should give humorous response directly (no disambiguation)
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > chomp rock
            You gnaw the smooth rock with the enthusiasm of the
            nutritionally confused.
            """)

        let finalState = try await engine.item("rock")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Conversation recovery - non-response clears question")
    func testConversationRecovery() async throws {
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

        // When: CHOMP creates question, then do something else
        try await engine.execute("chomp apple", "look")

        // Then: Question should be automatically cleared
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > chomp apple
            Do you mean you want to eat the red apple?

            > look
            — Test Room —

            A room for testing.

            There is a red apple here.
            """)

        // Verify question is cleared
        let hasPending = await ConversationManager.hasPendingQuestion(engine: engine)
        #expect(hasPending == false)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Intents")
    func testIntents() async throws {
        let handler = ChompActionHandler()
        // ChompActionHandler doesn't specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
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
