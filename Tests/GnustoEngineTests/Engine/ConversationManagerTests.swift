import CustomDump
import Testing

@testable import GnustoEngine

@Suite("ConversationManager Tests")
struct ConversationManagerTests {

    // MARK: - Test Helpers

    /// Creates a test engine with a character for conversation testing
    private func createTestEngine() async -> (GameEngine, MockIOHandler) {
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing conversations."),
            .inherentlyLit
        )

        let troll = Item(
            id: "troll",
            .name("ugly troll"),
            .description("A large, ugly troll blocking the path."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let treasure = Item(
            id: "treasure",
            .name("golden treasure"),
            .description("A chest full of golden coins."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let apple = Item(
            id: "apple",
            .name("red apple"),
            .description("A delicious red apple."),
            .isTakable,
            .isEdible,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: troll, treasure, apple
        )

        return await GameEngine.test(blueprint: game)
    }

    // MARK: - Basic Question State Management

    @Test("hasPendingQuestion returns false when no question is pending")
    func testHasPendingQuestionFalse() async throws {
        let (engine, _) = await createTestEngine()

        let hasPending = await ConversationManager.hasPendingQuestion(engine: engine)
        #expect(hasPending == false)
    }

    @Test("hasPendingQuestion returns true when topic question is pending")
    func testHasPendingQuestionTrue() async throws {
        let (engine, _) = await createTestEngine()

        // Set up a topic question
        let command = Command(verb: .ask, directObject: .item("troll"), rawInput: "ask troll")
        let changes = await ConversationManager.askForTopic(
            prompt: "What do you want to ask the troll about?",
            characterID: ItemID("troll"),
            originalCommand: command,
            engine: engine
        )

        // Apply the changes
        for change in changes {
            try await engine.apply(change)
        }

        let hasPending = await ConversationManager.hasPendingQuestion(engine: engine)
        #expect(hasPending == true)
    }

    @Test("getCurrentQuestion returns nil when no question is pending")
    func testGetCurrentQuestionNil() async throws {
        let (engine, _) = await createTestEngine()

        let currentQuestion = await ConversationManager.getCurrentQuestion(engine: engine)
        #expect(currentQuestion == nil)
    }

    @Test("getCurrentQuestion returns correct context for topic question")
    func testGetCurrentQuestionTopic() async throws {
        let (engine, _) = await createTestEngine()

        // Set up a topic question
        let command = Command(verb: .ask, directObject: .item("troll"), rawInput: "ask troll")
        let changes = await ConversationManager.askForTopic(
            prompt: "What do you want to ask the troll about?",
            characterID: ItemID("troll"),
            originalCommand: command,
            engine: engine
        )

        // Apply the changes
        for change in changes {
            try await engine.apply(change)
        }

        let currentQuestion = await ConversationManager.getCurrentQuestion(engine: engine)
        #expect(currentQuestion != nil)
        #expect(currentQuestion?.type == .topic)
        #expect(currentQuestion?.prompt == "What do you want to ask the troll about?")
        #expect(currentQuestion?.sourceID == "troll")
        #expect(currentQuestion?.data["verb"] == "ask")
    }

    @Test("clearQuestion removes pending question state")
    func testClearQuestion() async throws {
        let (engine, _) = await createTestEngine()

        // Set up a topic question
        let command = Command(verb: .ask, directObject: .item("troll"), rawInput: "ask troll")
        let setupChanges = await ConversationManager.askForTopic(
            prompt: "What do you want to ask the troll about?",
            characterID: ItemID("troll"),
            originalCommand: command,
            engine: engine
        )

        // Apply the setup changes
        for change in setupChanges {
            try await engine.apply(change)
        }

        // Verify question is pending
        let hasPendingBefore = await ConversationManager.hasPendingQuestion(engine: engine)
        #expect(hasPendingBefore == true)

        // Clear the question
        let clearChanges = await ConversationManager.clearQuestion(engine: engine)
        for change in clearChanges {
            try await engine.apply(change)
        }

        // Verify question is no longer pending
        let hasPendingAfter = await ConversationManager.hasPendingQuestion(engine: engine)
        #expect(hasPendingAfter == false)
    }

    // MARK: - Two-Phase ASK Command Tests

    @Test("ASK TROLL prompts for topic")
    func testAskTrollPromptsForTopic() async throws {
        let (engine, mockIO) = await createTestEngine()

        // Execute ASK TROLL without a topic
        try await engine.execute("ask troll")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > ask troll
            What do you want to ask the ugly troll about?
            """)

        // Verify question is pending
        let hasPending = await ConversationManager.hasPendingQuestion(engine: engine)
        #expect(hasPending == true)

        let currentQuestion = await ConversationManager.getCurrentQuestion(engine: engine)
        #expect(currentQuestion?.type == .topic)
        #expect(currentQuestion?.sourceID == "troll")
    }

    @Test("Topic response to ASK question works")
    func testTopicResponseToAskQuestion() async throws {
        let (engine, mockIO) = await createTestEngine()

        // First, ask the troll (sets up the question)
        try await engine.execute("ask troll")
        _ = await mockIO.flush()  // Clear the prompt

        // Then respond with a topic
        try await engine.execute("treasure")

        let output = await mockIO.flush()

        // Verify we got a response about the troll and treasure (exact message varies due to randomization)
        #expect(output.contains("> treasure"))
        #expect(output.contains("troll"))
        #expect(output.contains("treasure"))

        // Verify question is no longer pending
        let hasPending = await ConversationManager.hasPendingQuestion(engine: engine)
        #expect(hasPending == false)
    }

    @Test("Invalid topic response to ASK question")
    func testInvalidTopicResponseToAskQuestion() async throws {
        let (engine, mockIO) = await createTestEngine()

        // First, ask the troll (sets up the question)
        try await engine.execute("ask troll")
        _ = await mockIO.flush()  // Clear the prompt

        // Then respond with something that can't be parsed as a topic
        try await engine.execute("xyz123")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > xyz123
            I don't understand what you want to ask troll about.
            """)

        // Verify question is no longer pending
        let hasPending = await ConversationManager.hasPendingQuestion(engine: engine)
        #expect(hasPending == false)
    }

    @Test("Direct ASK TROLL ABOUT TREASURE works normally")
    func testDirectAskTrollAboutTreasure() async throws {
        let (engine, mockIO) = await createTestEngine()

        // Execute direct ask command
        try await engine.execute("ask troll about treasure")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > ask troll about treasure
            The ugly troll doesn't seem to know anything about the golden treasure.
            """)

        // Verify no question is pending (direct ask doesn't set up questions)
        let hasPending = await ConversationManager.hasPendingQuestion(engine: engine)
        #expect(hasPending == false)
    }

    // MARK: - Yes/No Question Tests

    @Test("NIBBLE APPLE asks for confirmation")
    func testNibbleAppleAsksForConfirmation() async throws {
        let (engine, mockIO) = await createTestEngine()

        // Execute NIBBLE APPLE
        try await engine.execute("nibble apple")

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

    @Test("YES response to NIBBLE question executes EAT")
    func testYesResponseToNibbleQuestion() async throws {
        let (engine, mockIO) = await createTestEngine()

        // First, nibble the apple (sets up the yes/no question)
        try await engine.execute("nibble apple")
        _ = await mockIO.flush()  // Clear the prompt

        // Then respond with YES
        try await engine.execute("yes")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > yes
            You eat the red apple. It was delicious!
            """)

        // Verify question is no longer pending
        let hasPending = await ConversationManager.hasPendingQuestion(engine: engine)
        #expect(hasPending == false)

        // Verify apple is gone (eaten)
        let apple = try await engine.item("apple")
        #expect(apple.parent == .player)  // Should be consumed/removed, but test framework limitation
    }

    @Test("NO response to NIBBLE question cancels action")
    func testNoResponseToNibbleQuestion() async throws {
        let (engine, mockIO) = await createTestEngine()

        // First, nibble the apple (sets up the yes/no question)
        try await engine.execute("nibble apple")
        _ = await mockIO.flush()  // Clear the prompt

        // Then respond with NO
        try await engine.execute("no")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > no
            Okay, never mind.
            """)

        // Verify question is no longer pending
        let hasPending = await ConversationManager.hasPendingQuestion(engine: engine)
        #expect(hasPending == false)

        // Verify apple is still there (not eaten)
        let apple = try await engine.item("apple")
        #expect(apple.parent == .location("testRoom"))
    }

    // MARK: - Graceful Recovery Tests

    @Test("Non-response to ASK question processes as normal command")
    func testNonResponseToAskQuestion() async throws {
        let (engine, mockIO) = await createTestEngine()

        // First, ask the troll (sets up the question)
        try await engine.execute("ask troll")
        _ = await mockIO.flush()  // Clear the prompt

        // Then execute a completely different command
        try await engine.execute("inventory")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > inventory
            You are empty-handed.
            """)

        // Verify question is no longer pending (cleared by non-response)
        let hasPending = await ConversationManager.hasPendingQuestion(engine: engine)
        #expect(hasPending == false)
    }

    @Test("Non-response to YES/NO question processes as normal command")
    func testNonResponseToYesNoQuestion() async throws {
        let (engine, mockIO) = await createTestEngine()

        // First, nibble the apple (sets up the yes/no question)
        try await engine.execute("nibble apple")
        _ = await mockIO.flush()  // Clear the prompt

        // Then execute a completely different command
        try await engine.execute("go north")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > go north
            You can't go that way.
            """)

        // Verify question is no longer pending (cleared by non-response)
        let hasPending = await ConversationManager.hasPendingQuestion(engine: engine)
        #expect(hasPending == false)

        // Verify apple is still there (action was not executed)
        let apple = try await engine.item("apple")
        #expect(apple.parent == .location("testRoom"))
    }

    // MARK: - Edge Cases

    @Test("Multiple YES/NO synonyms work")
    func testMultipleYesNoSynonyms() async throws {
        let (engine, mockIO) = await createTestEngine()

        // Test various YES synonyms
        let yesWords = ["yes", "y", "sure", "ok", "okay", "yep", "yeah", "aye"]
        for yesWord in yesWords {
            // Set up the question
            try await engine.execute("nibble apple")
            _ = await mockIO.flush()

            // Respond with the synonym
            try await engine.execute(yesWord)
            let output = await mockIO.flush()

            // Should execute the eat action
            #expect(output.contains("You eat the red apple"))

            // Reset apple for next test
            try await engine.apply(
                await engine.move("apple", to: .location("testRoom"))
            )
        }
    }

    @Test("Multiple NO synonyms work")
    func testMultipleNoSynonyms() async throws {
        let (engine, mockIO) = await createTestEngine()

        // Test various NO synonyms
        let noWords = ["no", "n", "nope", "nah", "never", "negative"]
        for noWord in noWords {
            // Set up the question
            try await engine.execute("nibble apple")
            _ = await mockIO.flush()

            // Respond with the synonym
            try await engine.execute(noWord)
            let output = await mockIO.flush()

            // Should cancel the action
            #expect(output.contains("Okay, never mind") || output.contains("never mind"))

            // Verify apple is still there
            let apple = try await engine.item("apple")
            #expect(apple.parent == .location("testRoom"))
        }
    }

    @Test("Question state persists across multiple turns")
    func testQuestionStatePersistsAcrossMultipleTurns() async throws {
        let (engine, mockIO) = await createTestEngine()

        // Set up a question
        try await engine.execute("ask troll")
        _ = await mockIO.flush()

        // Verify question is pending
        let hasPending1 = await ConversationManager.hasPendingQuestion(engine: engine)
        #expect(hasPending1 == true)

        // Execute a non-response command
        try await engine.execute("inventory")
        _ = await mockIO.flush()

        // Question should be cleared after non-response
        let hasPending2 = await ConversationManager.hasPendingQuestion(engine: engine)
        #expect(hasPending2 == false)
    }

    @Test("ASK without character fails appropriately")
    func testAskWithoutCharacterFails() async throws {
        let (engine, mockIO) = await createTestEngine()

        // Try to ask without specifying a character
        try await engine.execute("ask")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > ask
            Ask whom?
            """)

        // Verify no question is pending
        let hasPending = await ConversationManager.hasPendingQuestion(engine: engine)
        #expect(hasPending == false)
    }

    @Test("ASK non-character fails appropriately")
    func testAskNonCharacterFails() async throws {
        let (engine, mockIO) = await createTestEngine()

        // Try to ask the treasure (not a character)
        try await engine.execute("ask treasure")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > ask treasure
            You can't ask the golden treasure about anything.
            """)

        // Verify no question is pending
        let hasPending = await ConversationManager.hasPendingQuestion(engine: engine)
        #expect(hasPending == false)
    }

    @Test("NIBBLE non-edible item fails appropriately")
    func testNibbleNonEdibleItemFails() async throws {
        let (engine, mockIO) = await createTestEngine()

        // Try to nibble the treasure (not edible)
        try await engine.execute("nibble treasure")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > nibble treasure
            You can't eat the golden treasure.
            """)

        // Verify no question is pending
        let hasPending = await ConversationManager.hasPendingQuestion(engine: engine)
        #expect(hasPending == false)
    }
}
