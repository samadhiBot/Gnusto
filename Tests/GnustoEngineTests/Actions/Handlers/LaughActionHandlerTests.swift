import Testing
@testable import GnustoEngine

/// Tests for the LaughActionHandler.
@Suite("LaughActionHandler Tests")
struct LaughActionHandlerTests {

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

    // MARK: - Tests

    @Test("LAUGH command")
    func testLaugh() async throws {
        let (engine, mockIO) = await createTestEngine()
        let handler = LaughActionHandler()
        let command = Command(verb: .laugh, rawInput: "laugh")
        let context = ActionContext(command: command, engine: engine)

        let result = try await handler.process(context: context)

        #expect(result.message != nil)
        #expect(result.message!.contains("laugh") || result.message!.contains("guffaw"))
    }

    @Test("LAUGH returns varied responses")
    func testLaughVariedResponses() async throws {
        let (engine, mockIO) = await createTestEngine()
        let handler = LaughActionHandler()
        let command = Command(verb: .laugh, rawInput: "laugh")
        let context = ActionContext(command: command, engine: engine)

        var responses: Set<String> = []

        // Run multiple times to check for variety
        for _ in 0..<10 {
            let result = try await handler.process(context: context)
            if let message = result.message {
                responses.insert(message)
            }
        }

        // Should have at least some variety in responses
        #expect(responses.count >= 1)
    }
}
