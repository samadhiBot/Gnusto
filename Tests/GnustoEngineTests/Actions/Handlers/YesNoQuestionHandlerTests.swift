import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("YesNoQuestionHandler Tests")
struct YesNoQuestionHandlerTests {

    // MARK: - Basic Processing Tests

    @Test("YES with no pending question returns yesWhat message")
    func testYesWithNoPendingQuestion() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When - execute YES with no pending question
        try await engine.execute("yes")

        // Then
        await mockIO.expectOutput(
            """
            > yes
            Your affirmation lacks context. Yes to what, exactly?
            """
        )

        let hasPending = await engine.conversationManager.hasPendingQuestion
        #expect(hasPending == false)
    }

    @Test("NO with no pending question returns noWhat message")
    func testNoWithNoPendingQuestion() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When - execute NO with no pending question
        try await engine.execute("no")

        // Then
        await mockIO.expectOutput(
            """
            > no
            No what?
            """
        )

        let hasPending = await engine.conversationManager.hasPendingQuestion
        #expect(hasPending == false)
    }

    @Test("YES with pending question delegates to ConversationManager")
    func testYesWithPendingQuestion() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up a pending question
        _ = await engine.conversationManager.askYesNo(
            question: "Do you want to continue?",
            noMessage: "Okay, stopping."
        )

        // When - execute YES with pending question
        try await engine.execute("yes")

        // Then - should get the response from ConversationManager
        await mockIO.expectOutput(
            """
            > yes
            Okay.
            """
        )

        let hasPending = await engine.conversationManager.hasPendingQuestion
        #expect(hasPending == false)
    }

    @Test("NO with pending question delegates to ConversationManager")
    func testNoWithPendingQuestion() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up a pending question
        _ = await engine.conversationManager.askYesNo(
            question: "Do you want to continue?",
            noMessage: "Okay, stopping."
        )

        // When - execute NO with pending question
        try await engine.execute("no")

        // Then - should get the custom no message
        await mockIO.expectOutput(
            """
            > no
            Okay, stopping.
            """
        )

        let hasPending = await engine.conversationManager.hasPendingQuestion
        #expect(hasPending == false)
    }

    @Test("YES with pending command question executes command")
    func testYesWithCommandQuestion() async throws {
        // Given
        let apple = Item(
            id: "apple",
            .name("red apple"),
            .description("A delicious red apple."),
            .isTakable,
            .isEdible,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: apple
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up a command question
        let appleProxy = await engine.item("apple")
        let eatCommand = Command(
            verb: .eat,
            directObject: .item(appleProxy),
            rawInput: "eat apple"
        )

        _ = await engine.conversationManager.askYesNo(
            question: "Do you want to eat the apple?",
            yesCommand: eatCommand,
            noMessage: "Okay, never mind."
        )

        // When - execute YES
        try await engine.execute("yes")

        // Then - should execute the eat command
        await mockIO.expectOutput(
            """
            > yes
            Taken.

            The red apple remains tantalizingly out of reach of your
            digestive ambitions.
            """
        )

        let hasPending = await engine.conversationManager.hasPendingQuestion
        #expect(hasPending == false)
    }

    // MARK: - Synonym Testing

    @Test("Various YES synonyms work correctly")
    func testYesSynonyms() async throws {
        let yesSynonyms = ["yes", "y", "sure", "ok", "okay", "yep", "yeah", "aye"]

        for synonym in yesSynonyms {
            // Given - fresh engine for each test
            let game = MinimalGame()
            let (engine, mockIO) = await GameEngine.test(blueprint: game)

            // Set up pending question
            _ = await engine.conversationManager.askYesNo(
                question: "Continue?",
                noMessage: "Stopped."
            )

            // When - execute the synonym
            try await engine.execute(synonym)

            // Then
            await mockIO.expectOutput(
                """
                > \(synonym)
                Okay.
                """)

            let hasPending = await engine.conversationManager.hasPendingQuestion
            #expect(hasPending == false)
        }
    }

    @Test("Various NO synonyms work correctly")
    func testNoSynonyms() async throws {
        let noSynonyms = ["no", "n", "nope", "nah", "never", "negative"]

        for synonym in noSynonyms {
            // Given - fresh engine for each test
            let game = MinimalGame()
            let (engine, mockIO) = await GameEngine.test(blueprint: game)

            // Set up pending question
            _ = await engine.conversationManager.askYesNo(
                question: "Continue?",
                noMessage: "Custom no message."
            )

            // When - execute the synonym
            try await engine.execute(synonym)

            // Then
            await mockIO.expectOutput(
                """
                > \(synonym)
                Custom no message.
                """)

            let hasPending = await engine.conversationManager.hasPendingQuestion
            #expect(hasPending == false)
        }
    }

    // MARK: - Static Utility Method Tests

    @Test("askConfirmation creates proper confirmation dialog")
    func testAskConfirmation() async throws {
        // Given
        let apple = Item(
            id: "apple",
            .name("red apple"),
            .description("A delicious red apple."),
            .isTakable,
            .isEdible,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: apple
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let appleProxy = await engine.item("apple")
        let eatCommand = Command(
            verb: .eat,
            directObject: .item(appleProxy),
            rawInput: "eat apple"
        )

        let dummyCommand = Command(verb: .look, rawInput: "look")
        let context = ActionContext(dummyCommand, engine)

        // When
        let result = await YesNoQuestionHandler.askConfirmation(
            question: "Do you really want to eat the apple?",
            yesCommand: eatCommand,
            noMessage: "Okay, you changed your mind.",
            sourceID: ItemID("player"),
            context: context
        )

        // Then
        #expect(result.message == "Do you really want to eat the apple?")

        let hasPending = await engine.conversationManager.hasPendingQuestion
        #expect(hasPending == true)

        let currentPrompt = await engine.conversationManager.currentQuestionPrompt
        #expect(currentPrompt == "Do you really want to eat the apple?")
    }

    @Test("askToConfirmAction creates confirmation for original command")
    func testAskToConfirmAction() async throws {
        // Given
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)

        let lookCommand = Command(verb: .look, rawInput: "look")
        let context = ActionContext(lookCommand, engine)

        // When
        let result = await YesNoQuestionHandler.askToConfirmAction(
            question: "Are you sure you want to look?",
            context: context
        )

        // Then
        #expect(result.message == "Are you sure you want to look?")

        let hasPending = await engine.conversationManager.hasPendingQuestion
        #expect(hasPending == true)

        let currentPrompt = await engine.conversationManager.currentQuestionPrompt
        #expect(currentPrompt == "Are you sure you want to look?")
    }

    @Test("askToDisambiguate creates disambiguation dialog")
    func testAskToDisambiguate() async throws {
        // Given
        let redApple = Item(
            id: "redApple",
            .name("red apple"),
            .description("A red apple."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: redApple
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let redAppleProxy = await engine.item("redApple")
        let clarifiedCommand = Command(
            verb: .take,
            directObject: .item(redAppleProxy),
            rawInput: "take red apple"
        )

        let originalCommand = Command(verb: .take, rawInput: "take apple")
        let context = ActionContext(originalCommand, engine)

        // When
        let result = await YesNoQuestionHandler.askToDisambiguate(
            question: "Do you mean the red apple?",
            clarifiedCommand: clarifiedCommand,
            context: context
        )

        // Then
        #expect(result.message == "Do you mean the red apple?")

        let hasPending = await engine.conversationManager.hasPendingQuestion
        #expect(hasPending == true)

        let currentPrompt = await engine.conversationManager.currentQuestionPrompt
        #expect(currentPrompt == "Do you mean the red apple?")
    }

    // MARK: - Integration Tests

    @Test("Full disambiguation flow with YES response")
    func testFullDisambiguationFlowYes() async throws {
        // Given
        let redApple = Item(
            id: "redApple",
            .name("red apple"),
            .description("A red apple."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: redApple
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up disambiguation question manually (simulating what parser would do)
        let redAppleProxy = await engine.item("redApple")
        let clarifiedCommand = Command(
            verb: .take,
            directObject: .item(redAppleProxy),
            rawInput: "take red apple"
        )

        let originalCommand = Command(verb: .take, rawInput: "take apple")
        let context = ActionContext(originalCommand, engine)

        _ = await YesNoQuestionHandler.askToDisambiguate(
            question: "Do you mean the red apple?",
            clarifiedCommand: clarifiedCommand,
            context: context
        )

        // When - respond YES
        try await engine.execute("yes")

        // Then - should execute the clarified command
        await mockIO.expectOutput(
            """
            > yes
            Taken.
            """
        )

        // Verify apple was taken
        let apple = await engine.item("redApple")
        #expect(await apple.parent == .player)

        let hasPending = await engine.conversationManager.hasPendingQuestion
        #expect(hasPending == false)
    }

    @Test("Full disambiguation flow with NO response")
    func testFullDisambiguationFlowNo() async throws {
        // Given
        let redApple = Item(
            id: "redApple",
            .name("red apple"),
            .description("A red apple."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: redApple
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up disambiguation question manually
        let redAppleProxy = await engine.item("redApple")
        let clarifiedCommand = Command(
            verb: .take,
            directObject: .item(redAppleProxy),
            rawInput: "take red apple"
        )

        let originalCommand = Command(verb: .take, rawInput: "take apple")
        let context = ActionContext(originalCommand, engine)

        _ = await YesNoQuestionHandler.askToDisambiguate(
            question: "Do you mean the red apple?",
            clarifiedCommand: clarifiedCommand,
            context: context
        )

        // When - respond NO
        try await engine.execute("no")

        // Then - should get disambiguation cancellation message
        await mockIO.expectOutput(
            """
            > no
            What would you like to do next?
            """
        )

        // Verify apple was NOT taken
        let apple = await engine.item("redApple")
        let roomProxy = await engine.location(.startRoom)
        #expect(await apple.parent == .location(roomProxy))

        let hasPending = await engine.conversationManager.hasPendingQuestion
        #expect(hasPending == false)
    }

    // MARK: - Edge Cases and Error Handling

    @Test("Ambiguous response with pending question falls back to responseNotUnderstood")
    func testAmbiguousResponseWithPendingQuestion() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up pending question
        _ = await engine.conversationManager.askYesNo(
            question: "Continue?",
            noMessage: "Stopped."
        )

        // When - execute ambiguous response that ConversationManager doesn't handle
        try await engine.execute("maybe")

        // Then - should get responseNotUnderstood message
        await mockIO.expectOutput(
            """
            > maybe
            The art of maybe-ing remains a mystery to me.
            """
        )

        // Question should be cleared after unhandled response
        let hasPending = await engine.conversationManager.hasPendingQuestion
        #expect(hasPending == false)
    }

    @Test("Handler processes commands with direct objects correctly")
    func testHandlerWithDirectObjects() async throws {
        // Given
        let thing = Item(
            id: "thing",
            .name("thing"),
            .description("A thing."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: thing
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When - execute YES with a direct object (which should be ignored for yes/no)
        try await engine.execute("yes thing")

        // Then - should treat as plain YES
        await mockIO.expectOutput(
            """
            > yes thing
            Your affirmation lacks context. Yes to what, exactly?
            """
        )
    }

    @Test("ConversationManager error handling in YesNoQuestionHandler")
    func testConversationManagerErrorHandling() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up a question with a command that might fail (ask without character)
        let invalidCommand = Command(
            verb: .ask,
            rawInput: "ask"
        )

        _ = await engine.conversationManager.askYesNo(
            question: "Execute invalid command?",
            yesCommand: invalidCommand,
            noMessage: "Good choice."
        )

        // When - respond YES to execute the invalid command
        // This should throw an ActionResponse.feedback
        do {
            try await engine.execute("yes")

            // If we get here, the command succeeded unexpectedly
            await mockIO.expectOutput(
                """
                > yes
                Ask whom?
                """)

            let hasPending = await engine.conversationManager.hasPendingQuestion
            #expect(hasPending == false)
        } catch let error as ActionResponse {
            // Expected - the ask command without a character should throw feedback
            if case .feedback(let message) = error {
                #expect(message == "Ask whom?")

                // The question is still pending since the ConversationManager
                // doesn't clear questions when commands throw exceptions
                let hasPending = await engine.conversationManager.hasPendingQuestion
                #expect(hasPending == true)
            } else {
                throw error
            }
        }
    }

    // MARK: - Syntax and Handler Configuration Tests

    @Test("Handler has correct syntax configuration")
    func testHandlerSyntax() async throws {
        // Given
        let handler = YesNoQuestionHandler()

        // Then
        #expect(handler.syntax.count == 2)
        #expect(handler.syntax.contains(.match(.verb)))
        #expect(handler.syntax.contains(.match(.verb, .directObject)))
    }

    @Test("Handler has correct synonyms")
    func testHandlerSynonyms() async throws {
        // Given
        let handler = YesNoQuestionHandler()

        // Then
        #expect(handler.synonyms.count == 2)
        #expect(handler.synonyms.contains(.yes))
        #expect(handler.synonyms.contains(.no))
    }

    @Test("Handler does not require light")
    func testHandlerLightRequirement() async throws {
        // Given
        let handler = YesNoQuestionHandler()

        // Then
        #expect(handler.requiresLight == false)
    }
}
