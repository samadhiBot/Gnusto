import CustomDump
import GnustoTestSupport
import Testing

@testable import GnustoEngine

@Suite("ConversationManager Detailed Tests")
struct ConversationManagerTests {

    // MARK: - Yes/No Question Tests

    @Test("askYesNo creates question and returns prompt")
    func testAskYesNoBasic() async throws {
        // Given
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let result = await engine.conversationManager.askYesNo(
            question: "Do you want to continue?",
            noMessage: "Okay, stopping."
        )

        // Then
        #expect(result.message == "Do you want to continue?")
        #expect(await engine.conversationManager.hasPendingQuestion == true)
        #expect(
            await engine.conversationManager.currentQuestionPrompt == "Do you want to continue?")
    }

    @Test("askYesNo with command executes command on yes")
    func testAskYesNoWithCommand() async throws {
        // Given
        let apple = Item("apple")
            .name("red apple")
            .description("A delicious red apple.")
            .isTakable
            .isEdible
            .in(.startRoom)

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

        // When - ask question with command
        let questionResult = await engine.conversationManager.askYesNo(
            question: "Do you want to eat the apple?",
            yesCommand: eatCommand,
            noMessage: "Okay, never mind."
        )

        #expect(questionResult.message == "Do you want to eat the apple?")
        #expect(await engine.conversationManager.hasPendingQuestion == true)

        // When - respond yes
        let yesResult = try await engine.conversationManager.processResponse("yes", with: engine)

        // Then
        #expect(yesResult != nil)
        #expect(await engine.conversationManager.hasPendingQuestion == false)

        // The eat command should have been executed
        #expect(yesResult?.message != nil)
    }

    @Test("processResponse handles various yes responses")
    func testYesResponseVariations() async throws {
        let game = MinimalGame()

        let yesVariations = ["yes", "y", "sure", "ok", "okay", "yep", "yeah", "aye"]

        for yesResponse in yesVariations {
            // Given - fresh engine for each test
            let (engine, _) = await GameEngine.test(blueprint: game)

            _ = await engine.conversationManager.askYesNo(
                question: "Continue?",
                noMessage: "Stopped."
            )

            // When
            let result = try await engine.conversationManager.processResponse(
                yesResponse, with: engine)

            // Then
            #expect(result != nil, "'\(yesResponse)' should be recognized as yes")
            #expect(result?.message == "Okay.")
            #expect(await engine.conversationManager.hasPendingQuestion == false)
        }
    }

    @Test("processResponse handles various no responses")
    func testNoResponseVariations() async throws {
        let game = MinimalGame()

        let noVariations = ["no", "n", "nope", "nah", "never", "negative"]

        for noResponse in noVariations {
            // Given - fresh engine for each test
            let (engine, _) = await GameEngine.test(blueprint: game)

            _ = await engine.conversationManager.askYesNo(
                question: "Continue?",
                noMessage: "Custom no message."
            )

            // When
            let result = try await engine.conversationManager.processResponse(
                noResponse, with: engine)

            // Then
            #expect(result != nil, "'\(noResponse)' should be recognized as no")
            #expect(result?.message == "Custom no message.")
            #expect(await engine.conversationManager.hasPendingQuestion == false)
        }
    }

    @Test("processResponse returns nil for ambiguous responses")
    func testAmbiguousResponses() async throws {
        // Given
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)

        _ = await engine.conversationManager.askYesNo(
            question: "Continue?",
            noMessage: "Stopped."
        )

        let ambiguousResponses = ["maybe", "perhaps", "hmm", "what", "I don't know", "unclear"]

        for ambiguousResponse in ambiguousResponses {
            // When
            let result = try await engine.conversationManager.processResponse(
                ambiguousResponse, with: engine)

            // Then
            #expect(result == nil, "'\(ambiguousResponse)' should not be handled as yes/no")
            #expect(
                await engine.conversationManager.hasPendingQuestion == true,
                "Question should still be pending")
        }
    }

    @Test("processResponse with no pending question returns nil")
    func testProcessResponseNoPendingQuestion() async throws {
        // Given
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)

        // No question asked

        // When
        let result = try await engine.conversationManager.processResponse("yes", with: engine)

        // Then
        #expect(result == nil)
        #expect(await engine.conversationManager.hasPendingQuestion == false)
    }

    // MARK: - Topic Question Tests

    @Test("askForTopic creates topic question")
    func testAskForTopic() async throws {
        // Given
        let wizard = Item("wizard")
            .name("old wizard")
            .description("A wise old wizard.")
            .in(.startRoom)

        let game = MinimalGame(
            items: wizard
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let dummyCommand = Command(verb: .ask, rawInput: "ask wizard")
        let context = ActionContext(dummyCommand, engine)

        // When
        let result = await engine.conversationManager.askForTopic(
            question: "What do you want to ask about?",
            characterID: ItemID("wizard"),
            context: context
        )

        // Then
        #expect(result.message == "What do you want to ask about?")
        #expect(await engine.conversationManager.hasPendingQuestion == true)
        #expect(
            await engine.conversationManager.currentQuestionPrompt
                == "What do you want to ask about?")
    }

    @Test("processTopicResponse creates ask command for known topics")
    func testProcessTopicResponse() async throws {
        // Given
        let wizard = Item("wizard")
            .name("old wizard")
            .description("A wise old wizard.")
            .in(.startRoom)

        let magic = Item("magic")
            .name("magic")
            .description("The art of magic.")
            .in(.startRoom)

        let game = MinimalGame(
            items: wizard, magic
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let dummyCommand = Command(verb: .ask, rawInput: "ask wizard")
        let context = ActionContext(dummyCommand, engine)

        // Set up topic question
        _ = await engine.conversationManager.askForTopic(
            question: "What do you want to ask about?",
            characterID: ItemID("wizard"),
            context: context
        )

        // When - respond with a topic that exists as an item
        let result = try await engine.conversationManager.processResponse("magic", with: engine)

        // Then
        #expect(result != nil)
        #expect(await engine.conversationManager.hasPendingQuestion == false)
    }

    @Test("processTopicResponse returns nil for unknown topics")
    func testProcessTopicResponseUnknown() async throws {
        // Given
        let wizard = Item("wizard")
            .name("old wizard")
            .description("A wise old wizard.")
            .in(.startRoom)

        let game = MinimalGame(
            items: wizard
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let dummyCommand = Command(verb: .ask, rawInput: "ask wizard")
        let context = ActionContext(dummyCommand, engine)

        // Set up topic question
        _ = await engine.conversationManager.askForTopic(
            question: "What do you want to ask about?",
            characterID: ItemID("wizard"),
            context: context
        )

        // When - respond with unknown topic
        let result = try await engine.conversationManager.processResponse(
            "unknowntopic", with: engine)

        // Then - should return nil to let engine process normally
        #expect(result == nil)
        #expect(await engine.conversationManager.hasPendingQuestion == true)
    }

    // MARK: - Choice Question Tests

    @Test("askChoice creates choice question")
    func testAskChoice() async throws {
        // Given
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)

        let lookCommand = Command(verb: .look, rawInput: "look")
        let inventoryCommand = Command(verb: .inventory, rawInput: "inventory")

        let choices = [
            "look": lookCommand,
            "inventory": inventoryCommand,
        ]

        // When
        let result = await engine.conversationManager.askChoice(
            question: "What would you like to do?",
            choices: choices
        )

        // Then
        #expect(result.message == "What would you like to do?")
        #expect(await engine.conversationManager.hasPendingQuestion == true)
        #expect(
            await engine.conversationManager.currentQuestionPrompt == "What would you like to do?")
    }

    @Test("processChoiceResponse executes matching command")
    func testProcessChoiceResponse() async throws {
        // Given
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)

        let lookCommand = Command(verb: .look, rawInput: "look")
        let inventoryCommand = Command(verb: .inventory, rawInput: "inventory")

        let choices = [
            "look": lookCommand,
            "inventory": inventoryCommand,
        ]

        // Set up choice question
        _ = await engine.conversationManager.askChoice(
            question: "What would you like to do?",
            choices: choices
        )

        // When - respond with exact choice
        let result = try await engine.conversationManager.processResponse("look", with: engine)

        // Then
        #expect(result != nil)
        #expect(await engine.conversationManager.hasPendingQuestion == false)
    }

    @Test("processChoiceResponse handles case insensitive matching")
    func testProcessChoiceResponseCaseInsensitive() async throws {
        // Given
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)

        let lookCommand = Command(verb: .look, rawInput: "look")
        let choices = ["Look": lookCommand]

        // Set up choice question
        _ = await engine.conversationManager.askChoice(
            question: "What would you like to do?",
            choices: choices
        )

        // When - respond with different case
        let result = try await engine.conversationManager.processResponse("look", with: engine)

        // Then
        #expect(result != nil)
        #expect(await engine.conversationManager.hasPendingQuestion == false)
    }

    @Test("processChoiceResponse returns nil for invalid choice")
    func testProcessChoiceResponseInvalid() async throws {
        // Given
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)

        let lookCommand = Command(verb: .look, rawInput: "look")
        let choices = ["look": lookCommand]

        // Set up choice question
        _ = await engine.conversationManager.askChoice(
            question: "What would you like to do?",
            choices: choices
        )

        // When - respond with invalid choice
        let result = try await engine.conversationManager.processResponse("invalid", with: engine)

        // Then
        #expect(result == nil)
        #expect(await engine.conversationManager.hasPendingQuestion == true)
    }

    // MARK: - Question State Management Tests

    @Test("clearQuestion removes pending question")
    func testClearQuestion() async throws {
        // Given
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)

        // Set up question
        _ = await engine.conversationManager.askYesNo(
            question: "Continue?",
            noMessage: "Stopped."
        )

        #expect(await engine.conversationManager.hasPendingQuestion == true)

        // When
        await engine.conversationManager.clearQuestion()

        // Then
        #expect(await engine.conversationManager.hasPendingQuestion == false)
        #expect(await engine.conversationManager.currentQuestionPrompt == nil)
    }

    @Test("multiple questions in sequence work correctly")
    func testMultipleQuestionsSequence() async throws {
        // Given
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)

        // First question
        let result1 = await engine.conversationManager.askYesNo(
            question: "First question?",
            noMessage: "First no."
        )

        #expect(result1.message == "First question?")
        #expect(await engine.conversationManager.currentQuestionPrompt == "First question?")

        // Answer first question
        let response1 = try await engine.conversationManager.processResponse("no", with: engine)
        #expect(response1?.message == "First no.")
        #expect(await engine.conversationManager.hasPendingQuestion == false)

        // Second question
        let result2 = await engine.conversationManager.askYesNo(
            question: "Second question?",
            noMessage: "Second no."
        )

        #expect(result2.message == "Second question?")
        #expect(await engine.conversationManager.currentQuestionPrompt == "Second question?")

        // Answer second question
        let response2 = try await engine.conversationManager.processResponse("yes", with: engine)
        #expect(response2?.message == "Okay.")
        #expect(await engine.conversationManager.hasPendingQuestion == false)
    }

    // MARK: - Convenience Method Tests

    @Test("askToConfirm uses default no message")
    func testAskToConfirm() async throws {
        // Given
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)

        let dummyCommand = Command(verb: .look, rawInput: "look")
        let context = ActionContext(dummyCommand, engine)

        // When
        let result = await engine.conversationManager.askToConfirm(
            question: "Are you sure?",
            command: dummyCommand,
            context: context
        )

        // Then
        #expect(result.message == "Are you sure?")
        #expect(await engine.conversationManager.hasPendingQuestion == true)

        // Test no response gets default message
        let noResponse = try await engine.conversationManager.processResponse("no", with: engine)
        #expect(noResponse != nil)
        #expect(await engine.conversationManager.hasPendingQuestion == false)
    }

    @Test("askToDisambiguate sets up disambiguation properly")
    func testAskToDisambiguate() async throws {
        // Given
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)

        let clarifiedCommand = Command(verb: .look, rawInput: "look")
        let context = ActionContext(clarifiedCommand, engine)

        // When
        let result = await engine.conversationManager.askToDisambiguate(
            question: "Do you mean the red one?",
            clarifiedCommand: clarifiedCommand,
            context: context
        )

        // Then
        #expect(result.message == "Do you mean the red one?")
        #expect(await engine.conversationManager.hasPendingQuestion == true)

        // Test yes response executes clarified command
        let yesResponse = try await engine.conversationManager.processResponse("yes", with: engine)
        #expect(yesResponse != nil)
        #expect(await engine.conversationManager.hasPendingQuestion == false)
    }

    // MARK: - Edge Cases and Error Handling

    @Test("response processing handles whitespace and case")
    func testResponseProcessingWhitespaceAndCase() async throws {
        // Given
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)

        _ = await engine.conversationManager.askYesNo(
            question: "Continue?",
            noMessage: "Stopped."
        )

        let testCases = [
            "  YES  ",  // whitespace
            "Yes",  // mixed case
            "YES",  // upper case
            "\tno\n",  // tabs and newlines
            "  No  ",  // whitespace with no
        ]

        for (index, testCase) in testCases.enumerated() {
            // Reset question for each test
            if index > 0 {
                _ = await engine.conversationManager.askYesNo(
                    question: "Continue?",
                    noMessage: "Stopped."
                )
            }

            // When
            let result = try await engine.conversationManager.processResponse(
                testCase, with: engine)

            // Then
            #expect(result != nil, "'\(testCase)' should be recognized")
            #expect(await engine.conversationManager.hasPendingQuestion == false)
        }
    }

    @Test("askYesNo with empty question still works")
    func testAskYesNoEmptyQuestion() async throws {
        // Given
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let result = await engine.conversationManager.askYesNo(
            question: "",
            noMessage: "No message."
        )

        // Then
        #expect(result.message == nil)
        #expect(await engine.conversationManager.hasPendingQuestion == true)
        #expect(await engine.conversationManager.currentQuestionPrompt == "")
    }

    @Test("processResponse handles empty and whitespace-only input")
    func testProcessResponseEmptyInput() async throws {
        // Given
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)

        _ = await engine.conversationManager.askYesNo(
            question: "Continue?",
            noMessage: "Stopped."
        )

        let emptyInputs = ["", "   ", "\t", "\n", "  \t  \n  "]

        for emptyInput in emptyInputs {
            // When
            let result = try await engine.conversationManager.processResponse(
                emptyInput, with: engine)

            // Then
            #expect(result == nil, "Empty input '\(emptyInput)' should not be handled")
            #expect(await engine.conversationManager.hasPendingQuestion == true)
        }
    }
}
