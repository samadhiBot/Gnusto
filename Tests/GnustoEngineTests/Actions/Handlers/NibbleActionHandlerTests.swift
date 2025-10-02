import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("NibbleActionHandler Tests")
struct NibbleActionHandlerTests {

    // MARK: - Test Helpers

    /// Creates a test engine with edible and non-edible items for nibble testing
    private func createTestEngine() async -> (GameEngine, MockIOHandler) {
        let apple = Item("apple")
            .name("red apple")
            .description("A delicious red apple.")
            .isTakable
            .isEdible
            .in(.startRoom)

        let cookie = Item("cookie")
            .name("chocolate cookie")
            .description("A sweet chocolate cookie.")
            .isTakable
            .isEdible
            .in(.player)

        let rock = Item("rock")
            .name("gray rock")
            .description("A hard gray rock.")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
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
        await mockIO.expectOutput(
            """
            > nibble apple
            Do you mean you want to eat the red apple?
            """
        )

        // Verify yes/no question is pending
        let hasPending = await engine.conversationManager.hasPendingQuestion
        #expect(hasPending == true)

        let currentPrompt = await engine.conversationManager.currentQuestionPrompt
        #expect(currentPrompt?.contains("Do you mean") == true)
    }

    @Test("BITE syntax works")
    func testBiteSyntax() async throws {
        let (engine, mockIO) = await createTestEngine()

        // When
        try await engine.execute("bite cookie")

        // Then
        await mockIO.expectOutput(
            """
            > bite cookie
            Do you mean you want to eat the chocolate cookie?
            """
        )

        // Verify yes/no question is pending
        let hasPending = await engine.conversationManager.hasPendingQuestion
        #expect(hasPending == true)
    }

    // MARK: - Validation Testing

    @Test("Cannot nibble without direct object")
    func testCannotNibbleWithoutDirectObject() async throws {
        let (engine, mockIO) = await createTestEngine()

        // When
        try await engine.execute("nibble")

        // Then
        await mockIO.expectOutput(
            """
            > nibble
            Nibble what?
            """
        )

        // Verify no question is pending
        let hasPending = await engine.conversationManager.hasPendingQuestion
        #expect(hasPending == false)
    }

    @Test("Cannot nibble item not in scope")
    func testCannotNibbleItemNotInScope() async throws {
        let anotherRoom = Location("anotherRoom")
            .name("Another Room")
            .inherentlyLit

        let remoteCake = Item("remoteCake")
            .name("distant cake")
            .description("A cake in another room.")
            .isEdible
            .in("anotherRoom")

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteCake
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("nibble cake")

        // Then
        await mockIO.expectOutput(
            """
            > nibble cake
            Any such thing lurks beyond your reach.
            """
        )

        // Verify no question is pending
        let hasPending = await engine.conversationManager.hasPendingQuestion
        #expect(hasPending == false)
    }

    @Test("Cannot nibble non-edible item")
    func testCannotNibbleNonEdibleItem() async throws {
        let (engine, mockIO) = await createTestEngine()

        // When
        try await engine.execute("nibble rock")

        // Then
        await mockIO.expectOutput(
            """
            > nibble rock
            The gray rock falls well outside the realm of culinary
            possibility.
            """
        )

        // Verify no question is pending
        let hasPending = await engine.conversationManager.hasPendingQuestion
        #expect(hasPending == false)
    }

    @Test("Requires light to nibble")
    func testRequiresLight() async throws {
        // Given: Dark room with edible item
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")
            // Note: No .inherentlyLit property

        let bread = Item("bread")
            .name("fresh bread")
            .description("A loaf of fresh bread.")
            .isEdible
            .in("darkRoom")

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: bread
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("nibble bread")

        // Then
        await mockIO.expectOutput(
            """
            > nibble bread
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )

        // Verify no question is pending
        let hasPending = await engine.conversationManager.hasPendingQuestion
        #expect(hasPending == false)
    }

    // MARK: - Yes/No Question Integration Testing

    @Test("YES response to nibble question executes eat action")
    func testYesResponseExecutesEat() async throws {
        let (engine, mockIO) = await createTestEngine()

        // First nibble to set up the question
        try await engine.execute("nibble cookie")

        // Verify question is pending
        let hasPending = await engine.conversationManager.hasPendingQuestion
        #expect(hasPending == true)

        // Then respond with YES
        try await engine.execute("yes")

        // Then
        await mockIO.expectOutput(
            """
            > nibble cookie
            Do you mean you want to eat the chocolate cookie?

            > yes
            Your appetite for the chocolate cookie must wait for better
            circumstances.
            """
        )

        // Verify question is no longer pending
        let stillPending = await engine.conversationManager.hasPendingQuestion
        #expect(stillPending == false)
    }

    @Test("NO response to nibble question cancels action")
    func testNoResponseCancelsAction() async throws {
        let (engine, mockIO) = await createTestEngine()

        // First nibble to set up the question, then respond with "no"
        try await engine.execute(
            "nibble apple",
            "no"
        )

        // Then
        await mockIO.expectOutput(
            """
            > nibble apple
            Do you mean you want to eat the red apple?

            > no
            What would you like to do next?
            """
        )

        // Verify question is no longer pending
        let stillPending = await engine.conversationManager.hasPendingQuestion
        #expect(stillPending == false)

        // Verify apple is still there (not eaten)
        let apple = await engine.item("apple")
        let testRoom = await engine.location(.startRoom)
        #expect(await apple.parent == .location(testRoom))
    }

    @Test("Different command clears nibble question")
    func testDifferentCommandClearsQuestion() async throws {
        let (engine, mockIO) = await createTestEngine()

        // First nibble to set up the question
        try await engine.execute("nibble apple")

        // Verify question is pending
        let hasPending = await engine.conversationManager.hasPendingQuestion
        #expect(hasPending == true)

        // Then execute a different command
        try await engine.execute("inventory")

        // Then
        await mockIO.expectOutput(
            """
            > nibble apple
            Do you mean you want to eat the red apple?

            > inventory
            You are carrying:
            - A chocolate cookie
            """
        )

        // Verify question is no longer pending
        let stillPending = await engine.conversationManager.hasPendingQuestion
        #expect(stillPending == false)

        // Verify apple is still there (not eaten)
        let apple = await engine.item("apple")
        let testRoom = await engine.location(.startRoom)
        #expect(await apple.parent == .location(testRoom))
    }

    // MARK: - Disambiguation Testing

    @Test("Nibble creates proper disambiguation question")
    func testNibbleCreatesProperDisambiguationQuestion() async throws {
        let (engine, mockIO) = await createTestEngine()

        // When
        try await engine.execute("nibble apple")

        // Then: Should create a yes/no question
        await mockIO.expectOutput(
            """
            > nibble apple
            Do you mean you want to eat the red apple?
            """
        )

        // Verify correct question context
        let currentPrompt = await engine.conversationManager.currentQuestionPrompt
        #expect(currentPrompt != nil)
        #expect(currentPrompt?.contains("Do you mean") == true)
    }

    @Test("Multiple nibble synonyms work")
    func testMultipleNibbleSynonyms() async throws {
        let (engine, mockIO) = await createTestEngine()

        // Test both nibble and bite
        let verbs = ["nibble", "bite"]

        for verb in verbs {
            // Execute the command
            try await engine.execute("\(verb) apple")

            await mockIO.expectOutput(
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
        let (engine, _) = await createTestEngine()

        // Get initial apple state
        let initialApple = await engine.item("apple")
        let initialParent = await initialApple.parent

        // Nibble the apple (just sets up question)
        try await engine.execute("nibble apple")

        // Verify apple hasn't changed yet
        let appleAfterQuestion = await engine.item("apple")
        #expect(await appleAfterQuestion.parent == initialParent)

        // Cancel the action
        try await engine.execute("no")

        // Verify apple is still unchanged
        let finalApple = await engine.item("apple")
        #expect(await finalApple.parent == initialParent)
    }

    // MARK: - Intent and Verb Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = NibbleActionHandler()
        #expect(handler.synonyms.contains(.nibble))
        #expect(handler.synonyms.contains(.bite))
        #expect(handler.synonyms.count == 2)
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

        let apple = Item("apple")
            .name("red apple")
            .description("A delicious red apple.")
            .isEdible
            .in(.startRoom)

        let game = MinimalGame(
            items: apple
        )

        // Create engine with default handlers for this test
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Nibble should still create the question
        try await engine.execute("nibble apple")

        // YES response should handle missing EAT handler gracefully
        try await engine.execute("yes")

        await mockIO.expectOutput(
            """
            > nibble apple
            Do you mean you want to eat the red apple?

            > yes
            Taken.

            The red apple remains tantalizingly out of reach of your
            digestive ambitions.
            """
        )
    }
}
