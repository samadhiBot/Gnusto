import CustomDump
import GnustoTestSupport
import Testing

@testable import GnustoEngine

@Suite("ConversationManager Architecture Test")
struct ConversationManagerArchitectureTest {

    @Test("ConversationManager is a proper GameEngine subsystem")
    func testConversationManagerAsEngineSubsystem() async throws {
        // Given: A minimal game setup
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

        // When: Accessing the conversation manager
        let conversationManager = await engine.conversationManager

        // Then: It should be a proper subsystem
        let hasPendingQuestion = await conversationManager.hasPendingQuestion
        #expect(hasPendingQuestion == false)

        let currentPrompt = await conversationManager.currentQuestionPrompt
        #expect(currentPrompt == nil)
    }

    @Test("ConversationManager stores strongly typed data")
    func testStronglyTypedData() async throws {
        // Given: A minimal game setup with an apple
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

        // When: Creating a clarified command and asking a yes/no question
        let appleProxy = await engine.item("apple")
        let eatCommand = Command(
            verb: .eat,
            directObject: .item(appleProxy),
            rawInput: "eat red apple"
        )

        let result = await engine.conversationManager.askYesNo(
            question: "Do you mean you want to eat the red apple?",
            yesCommand: eatCommand,
            noMessage: "Okay, never mind."
        )

        // Then: The question should be stored with strongly typed data
        #expect(result.message == "Do you mean you want to eat the red apple?")

        let hasPending = await engine.conversationManager.hasPendingQuestion
        #expect(hasPending == true)

        let currentPrompt = await engine.conversationManager.currentQuestionPrompt
        #expect(currentPrompt == "Do you mean you want to eat the red apple?")
    }

    @Test("ConversationManager provides clean API for response processing")
    func testCleanResponseProcessingAPI() async throws {
        // Given: A conversation manager with a pending yes/no question
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

        // Set up a yes/no question
        let appleProxy = await engine.item("apple")
        let eatCommand = Command(
            verb: .eat,
            directObject: .item(appleProxy),
            rawInput: "eat red apple"
        )

        _ = await engine.conversationManager.askYesNo(
            question: "Do you mean you want to eat the red apple?",
            yesCommand: eatCommand
        )

        // When: Processing a "yes" response
        let yesResponse = try await engine.conversationManager.processResponse("yes", with: engine)

        // Then: The response should be processed and question cleared
        #expect(yesResponse != nil)
        #expect(yesResponse?.message != nil)

        let stillPending = await engine.conversationManager.hasPendingQuestion
        #expect(stillPending == false)
    }

    @Test("ConversationManager handles no responses correctly")
    func testNoResponseHandling() async throws {
        // Given: A conversation manager with a pending yes/no question
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)

        _ = await engine.conversationManager.askYesNo(
            question: "Do you want to continue?",
            noMessage: "Okay, stopping."
        )

        // When: Processing a "no" response
        let noResponse = try await engine.conversationManager.processResponse("no", with: engine)

        // Then: The response should contain the no message
        #expect(noResponse?.message == "Okay, stopping.")

        let stillPending = await engine.conversationManager.hasPendingQuestion
        #expect(stillPending == false)
    }

    @Test("ConversationManager handles non-responses correctly")
    func testNonResponseHandling() async throws {
        // Given: A conversation manager with a pending question
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)

        _ = await engine.conversationManager.askYesNo(
            question: "Do you want to continue?"
        )

        // When: Processing a non-yes/no response
        let nonResponse = try await engine.conversationManager.processResponse("maybe", with: engine)

        // Then: The response should be nil (not handled)
        #expect(nonResponse == nil)

        // And the question should still be pending
        let stillPending = await engine.conversationManager.hasPendingQuestion
        #expect(stillPending == true)
    }

    @Test("ConversationManager can be cleared manually")
    func testManualClearQuestion() async throws {
        // Given: A conversation manager with a pending question
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)

        _ = await engine.conversationManager.askYesNo(
            question: "Do you want to continue?"
        )

        #expect(await engine.conversationManager.hasPendingQuestion == true)

        // When: Manually clearing the question
        await engine.conversationManager.clearQuestion()

        // Then: No question should be pending
        let stillPending = await engine.conversationManager.hasPendingQuestion
        #expect(stillPending == false)

        let currentPrompt = await engine.conversationManager.currentQuestionPrompt
        #expect(currentPrompt == nil)
    }

    @Test("ConversationManager convenience methods work correctly")
    func testConvenienceMethods() async throws {
        // Given: A minimal game setup
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

        // When: Using the askToConfirm convenience method
        let appleProxy = await engine.item("apple")
        let eatCommand = Command(
            verb: .eat,
            directObject: .item(appleProxy),
            rawInput: "eat red apple"
        )

        let result = await engine.conversationManager.askToConfirm(
            question: "Are you sure you want to eat the apple?",
            command: eatCommand,
            context: ActionContext(eatCommand, engine)
        )

        // Then: The question should be set up correctly
        #expect(result.message == "Are you sure you want to eat the apple?")

        let hasPending = await engine.conversationManager.hasPendingQuestion
        #expect(hasPending == true)

        let currentPrompt = await engine.conversationManager.currentQuestionPrompt
        #expect(currentPrompt == "Are you sure you want to eat the apple?")
    }
}
