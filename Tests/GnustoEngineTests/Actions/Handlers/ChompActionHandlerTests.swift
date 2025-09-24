import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("ChompActionHandler Tests")
struct ChompActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("CHOMP DIRECTOBJECT syntax works with disambiguation")
    func testChompDirectObjectSyntax() async throws {
        // Given
        let apple = Item(
            id: "apple",
            .name("red apple"),
            .description("A juicy red apple."),
            .isEdible,
            .in(.startRoom)
        )

        let game = MinimalGame(
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
            """
        )

        // Verify question is pending
        let hasPending = await engine.conversationManager.hasPendingQuestion
        #expect(hasPending == true)
    }

    @Test("CHOMP disambiguation - YES response eats the item")
    func testChompDisambiguationYes() async throws {
        // Given
        let apple = Item(
            id: "apple",
            .name("red apple"),
            .description("A juicy red apple."),
            .isEdible,
            .in(.startRoom)
        )

        let game = MinimalGame(
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
            Taken.

            The red apple remains tantalizingly out of reach of your
            digestive ambitions.
            """
        )

        // Apple should remain
        let finalState = await engine.item("apple")
        #expect(await finalState.parent == .player)
    }

    @Test("CHOMP disambiguation - NO response just takes a bite")
    func testChompDisambiguationNo() async throws {
        // Given
        let apple = Item(
            id: "apple",
            .name("red apple"),
            .description("A juicy red apple."),
            .isEdible,
            .in(.startRoom)
        )

        let game = MinimalGame(
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
            You decide against biting anything.
            """
        )

        // Apple should still be in the room
        let finalState = await engine.item("apple").parent
        let startRoom = await engine.location(.startRoom)
        #expect(finalState == .location(startRoom))
    }

    @Test("BITE syntax works with disambiguation")
    func testBiteSyntax() async throws {
        // Given
        let bread = Item(
            id: "bread",
            .name("piece of bread"),
            .description("A piece of fresh bread."),
            .isEdible,
            .in(.startRoom)
        )

        let game = MinimalGame(
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
            """
        )
    }

    @Test("CHEW syntax works")
    func testChewSyntax() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("chew")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > chew
            Your teeth clack together in a display of purposeless
            aggression.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot chomp item not in scope")
    func testCannotChompItemNotInScope() async throws {
        // Given
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
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
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
            Any such thing lurks beyond your reach.
            """
        )
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
            .in("darkRoom")
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
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Chomp without object gives general response")
    func testChompWithoutObject() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("chomp")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > chomp
            Your teeth clack together in a display of purposeless
            aggression.
            """
        )
    }

    @Test("Chomp on edible item asks for disambiguation")
    func testChompOnEdibleItem() async throws {
        // Given
        let cookie = Item(
            id: "cookie",
            .name("chocolate cookie"),
            .description("A delicious chocolate cookie."),
            .isEdible,
            .in(.startRoom)
        )

        let game = MinimalGame(
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
            """
        )

        // Verify question is pending
        let hasPending = await engine.conversationManager.hasPendingQuestion
        #expect(hasPending == true)
    }

    @Test("Chomp on character gives humorous response")
    func testChompOnCharacter() async throws {
        // Given
        let castleGuard = Item(
            id: "castleGuard",
            .name("castle guard"),
            .description("A stern castle guard."),
            .characterSheet(.strong),
            .in(.startRoom)
        )

        let game = MinimalGame(
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
            Your dental assault on the castle guard would likely end your
            relationship, and possibly your teeth.
            """
        )

        let finalState = await engine.item("castleGuard")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Chomp on regular item gives humorous response")
    func testChompOnRegularItem() async throws {
        // Given
        let rock = Item(
            id: "rock",
            .name("smooth rock"),
            .description("A smooth, round rock."),
            .in(.startRoom)
        )

        let game = MinimalGame(
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
            Your teeth are no match for the smooth rock.
            """
        )

        let finalState = await engine.item("rock")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Conversation recovery - non-response clears question")
    func testConversationRecovery() async throws {
        // Given
        let apple = Item(
            id: "apple",
            .name("red apple"),
            .description("A juicy red apple."),
            .isEdible,
            .in(.startRoom)
        )

        let game = MinimalGame(
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
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.

            There is a red apple here.
            """
        )

        // Verify question is cleared
        let hasPending = await engine.conversationManager.hasPendingQuestion
        #expect(hasPending == false)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = ChompActionHandler()
        #expect(handler.synonyms.contains(.chomp))
        #expect(handler.synonyms.contains(.bite))
        #expect(handler.synonyms.contains(.chew))
        #expect(handler.synonyms.count == 3)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = ChompActionHandler()
        #expect(handler.requiresLight == true)
    }
}
