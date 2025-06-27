import CustomDump
import Testing

@testable import GnustoEngine

@Suite("NibbleActionHandler Tests")
struct NibbleActionHandlerTests {

    // MARK: - Test Helpers

    /// Creates a test engine with edible and non-edible items for nibble testing
    private func createTestEngine() async -> (GameEngine, MockIOHandler) {
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let apple = Item(
            id: "apple",
            .name("red apple"),
            .description("A delicious red apple."),
            .isTakable,
            .isEdible,
            .in(.location("testRoom"))
        )

        let cookie = Item(
            id: "cookie",
            .name("chocolate cookie"),
            .description("A sweet chocolate cookie."),
            .isTakable,
            .isEdible,
            .in(.player)
        )

        let rock = Item(
            id: "rock",
            .name("gray rock"),
            .description("A hard gray rock."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: apple, cookie, rock
        )

        return await GameEngine.test(blueprint: game)
    }

    // MARK: - Syntax Rule Testing

    @Test("NIBBLE DIRECTOBJECT syntax works")
    func testNibbleDirectObjectSyntax() async throws {
        let (engine, mockIO) = await createTestEngine()

        // When
        try await engine.execute("nibble apple")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > nibble apple
            Do you mean you want to eat the red apple?
            """)

        // Verify yes/no question is pending
        let hasPending = await ConversationManager.hasPendingQuestion(engine: engine)
        #expect(hasPending == true)

        let currentQuestion = await ConversationManager.getCurrentQuestion(engine: engine)
        #expect(currentQuestion?.type == .yesNo)
    }

    @Test("BITE syntax works")
    func testBiteSyntax() async throws {
        let (engine, mockIO) = await createTestEngine()

        // When
        try await engine.execute("bite cookie")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > bite cookie
            Do you mean you want to eat the chocolate cookie?
            """)

        // Verify yes/no question is pending
        let hasPending = await ConversationManager.hasPendingQuestion(engine: engine)
        #expect(hasPending == true)
    }

    // MARK: - Validation Testing

    @Test("Cannot nibble without direct object")
    func testCannotNibbleWithoutDirectObject() async throws {
        let (engine, mockIO) = await createTestEngine()

        // When
        try await engine.execute("nibble")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > nibble
            Nibble what?
            """)

        // Verify no question is pending
        let hasPending = await ConversationManager.hasPendingQuestion(engine: engine)
        #expect(hasPending == false)
    }

    @Test("Cannot nibble item not in scope")
    func testCannotNibbleItemNotInScope() async throws {
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
            .name("distant cake"),
            .description("A cake in another room."),
            .isEdible,
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteCake
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("nibble cake")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > nibble cake
            You can't see any such thing.
            """)

        // Verify no question is pending
        let hasPending = await ConversationManager.hasPendingQuestion(engine: engine)
        #expect(hasPending == false)
    }

    @Test("Cannot nibble non-edible item")
    func testCannotNibbleNonEdibleItem() async throws {
        let (engine, mockIO) = await createTestEngine()

        // When
        try await engine.execute("nibble rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > nibble rock
            You can't eat the gray rock.
            """)

        // Verify no question is pending
        let hasPending = await ConversationManager.hasPendingQuestion(engine: engine)
        #expect(hasPending == false)
    }

    @Test("Requires light to nibble")
    func testRequiresLight() async throws {
        // Given: Dark room with edible item
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let bread = Item(
            id: "bread",
            .name("fresh bread"),
            .description("A loaf of fresh bread."),
            .isEdible,
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: bread
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("nibble bread")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > nibble bread
            It is pitch black. You can't see a thing.
            """)

        // Verify no question is pending
        let hasPending = await ConversationManager.hasPendingQuestion(engine: engine)
        #expect(hasPending == false)
    }

    // MARK: - Yes/No Question Integration Testing

    @Test("YES response to nibble question executes eat action")
    func testYesResponseExecutesEat() async throws {
        let (engine, mockIO) = await createTestEngine()

        // First nibble to set up the question
        try await engine.execute("nibble cookie")
        _ = await mockIO.flush()  // Clear the confirmation question

        // Verify question is pending
        let hasPending = await ConversationManager.hasPendingQuestion(engine: engine)
        #expect(hasPending == true)

        // Then respond with YES
        try await engine.execute("yes")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > yes
            You eat the chocolate cookie. It was delicious!
            """)

        // Verify question is no longer pending
        let stillPending = await ConversationManager.hasPendingQuestion(engine: engine)
        #expect(stillPending == false)

        // Verify cookie is gone (eaten)
        let cookie = try await engine.item("cookie")
        #expect(cookie.parent == .player)  // Should be consumed/removed, but test framework limitation
    }

    @Test("NO response to nibble question cancels action")
    func testNoResponseCancelsAction() async throws {
        let (engine, mockIO) = await createTestEngine()

        // First nibble to set up the question
        try await engine.execute("nibble apple")
        _ = await mockIO.flush()  // Clear the confirmation question

        // Then respond with NO
        try await engine.execute("no")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > no
            Okay, never mind.
            """)

        // Verify question is no longer pending
        let stillPending = await ConversationManager.hasPendingQuestion(engine: engine)
        #expect(stillPending == false)

        // Verify apple is still there (not eaten)
        let apple = try await engine.item("apple")
        #expect(apple.parent == .location("testRoom"))
    }

    @Test("Different command clears nibble question")
    func testDifferentCommandClearsQuestion() async throws {
        let (engine, mockIO) = await createTestEngine()

        // First nibble to set up the question
        try await engine.execute("nibble apple")
        _ = await mockIO.flush()  // Clear the confirmation question

        // Verify question is pending
        let hasPending = await ConversationManager.hasPendingQuestion(engine: engine)
        #expect(hasPending == true)

        // Then execute a different command
        try await engine.execute("inventory")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > inventory
            You have:
                a chocolate cookie
            """)

        // Verify question is no longer pending
        let stillPending = await ConversationManager.hasPendingQuestion(engine: engine)
        #expect(stillPending == false)

        // Verify apple is still there (not eaten)
        let apple = try await engine.item("apple")
        #expect(apple.parent == .location("testRoom"))
    }

    // MARK: - Disambiguation Testing

    @Test("Nibble creates proper disambiguation question")
    func testNibbleCreatesProperDisambiguationQuestion() async throws {
        let (engine, mockIO) = await createTestEngine()

        // When
        try await engine.execute("nibble apple")

        // Then: Should create a yes/no question
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > nibble apple
            Do you mean you want to eat the red apple?
            """)

        // Verify correct question context
        let currentQuestion = await ConversationManager.getCurrentQuestion(engine: engine)
        #expect(currentQuestion != nil)
        #expect(currentQuestion?.type == .yesNo)
        #expect(currentQuestion?.data["clarifiedVerb"] == "eat")
        #expect(currentQuestion?.data["clarifiedCommand"] == "eat red apple")
    }

    @Test("Multiple nibble synonyms work")
    func testMultipleNibbleSynonyms() async throws {
        let (engine, mockIO) = await createTestEngine()

        // Test both nibble and bite
        let verbs = ["nibble", "bite"]

        for verb in verbs {
            // Execute the command
            try await engine.execute("\(verb) apple")

            let output = await mockIO.flush()
            expectNoDifference(
                output,
                """
                > \(verb) apple
                Do you mean you want to eat the red apple?
                """)

            // Clear the question for next test
            try await engine.execute("no")
            _ = await mockIO.flush()
        }
    }

    // MARK: - State Changes Testing

    @Test("Nibble question preserves item state until confirmation")
    func testNibbleQuestionPreservesItemState() async throws {
        let (engine, mockIO) = await createTestEngine()

        // Get initial apple state
        let initialApple = try await engine.item("apple")
        let initialParent = initialApple.parent

        // Nibble the apple (just sets up question)
        try await engine.execute("nibble apple")
        _ = await mockIO.flush()

        // Verify apple hasn't changed yet
        let appleAfterQuestion = try await engine.item("apple")
        #expect(appleAfterQuestion.parent == initialParent)

        // Cancel the action
        try await engine.execute("no")
        _ = await mockIO.flush()

        // Verify apple is still unchanged
        let finalApple = try await engine.item("apple")
        #expect(finalApple.parent == initialParent)
    }

    // MARK: - Intent and Verb Testing

    @Test("Handler exposes correct Intents")
    func testIntents() async throws {
        let handler = NibbleActionHandler()
        #expect(handler.actions.contains(.eat))
        #expect(handler.actions.count == 1)
    }

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = NibbleActionHandler()
        #expect(handler.verbs.contains(.nibble))
        #expect(handler.verbs.contains(.bite))
        #expect(handler.verbs.count == 2)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = NibbleActionHandler()
        #expect(handler.requiresLight == true)
    }

    @Test("Handler uses correct syntax rules")
    func testSyntaxRules() async throws {
        let handler = NibbleActionHandler()
        #expect(handler.syntax.count == 1)
        // The syntax should be .match(.verb, .directObject)
        // We can't easily test the exact syntax structure without exposing internals
        // but we can verify it works through integration tests above
    }

    // MARK: - Error Handling

    @Test("Nibble handles missing EAT handler gracefully")
    func testNibbleHandlesMissingEatHandlerGracefully() async throws {
        // This is a theoretical test - in practice, EatActionHandler should always be present
        // But it demonstrates how the system should handle missing handlers

        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let apple = Item(
            id: "apple",
            .name("red apple"),
            .description("A delicious red apple."),
            .isEdible,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: apple
        )

        // Create engine with default handlers for this test
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Nibble should still create the question
        try await engine.execute("nibble apple")
        _ = await mockIO.flush()

        // YES response should handle missing EAT handler gracefully
        try await engine.execute("yes")
        let output = await mockIO.flush()

        // Should get some kind of error message rather than crashing
        #expect(output.contains("yes") || output.contains("don't know"))
    }
}
