import Testing
@testable import GnustoEngine

/// Integration tests for all humorous and atmospheric commands.
@Suite("Humorous Commands Integration Tests")
struct HumorousCommandsIntegrationTests {

    // MARK: - Test Setup

    func createTestEngine() async -> (GameEngine, MockIOHandler) {
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        return (engine, mockIO)
    }

    // MARK: - Integration Tests

    @Test("All humorous commands are registered in GameEngine")
    func testHumorousCommandsRegistered() async throws {
        let (engine, mockIO) = await createTestEngine()

        // Test that all humorous commands are available in the default handlers
        let defaultHandlers = GameEngine.defaultActionHandlers

        #expect(defaultHandlers[.chomp] != nil)
        #expect(defaultHandlers[.cry] != nil)
        #expect(defaultHandlers[.curse] != nil)
        #expect(defaultHandlers[.dance] != nil)
        #expect(defaultHandlers[.giggle] != nil)
        #expect(defaultHandlers[.laugh] != nil)
        #expect(defaultHandlers[.scream] != nil)
        #expect(defaultHandlers[.sing] != nil)
        #expect(defaultHandlers[.yell] != nil)
    }

    @Test("Humorous commands work in dark rooms")
    func testHumorousCommandsInDark() async throws {
        let (engine, mockIO) = await createTestEngine()

        // All humorous commands should work in dark rooms since they have requiresLight: false
        let vocabulary = await engine.gameState.vocabulary

        let humorousVerbs: [VerbID] = [.chomp, .cry, .curse, .dance, .giggle, .laugh, .scream, .sing, .yell]

        for verbID in humorousVerbs {
            if let verb = vocabulary.verbDefinitions[verbID] {
                #expect(verb.requiresLight == false, "Humorous command \(verbID) should not require light")
            }
        }
    }

    @Test("All humorous commands return messages")
    func testAllHumorousCommandsReturnMessages() async throws {
        let (engine, mockIO) = await createTestEngine()

        let handlers: [(VerbID, ActionHandler)] = [
            (.chomp, ChompActionHandler()),
            (.cry, CryActionHandler()),
            (.curse, CurseActionHandler()),
            (.dance, DanceActionHandler()),
            (.giggle, GiggleActionHandler()),
            (.laugh, LaughActionHandler()),
            (.scream, ScreamActionHandler()),
            (.sing, SingActionHandler()),
            (.yell, YellActionHandler())
        ]

        for (verbID, handler) in handlers {
            let command = Command(verb: verbID, rawInput: verbID.rawValue)
            let context = ActionContext(command: command, engine: engine)

            let result = try await handler.process(context: context)

            #expect(result.message != nil, "Handler for \(verbID) should return a message")
            #expect(!result.message!.isEmpty, "Handler for \(verbID) should return a non-empty message")
        }
    }
}
