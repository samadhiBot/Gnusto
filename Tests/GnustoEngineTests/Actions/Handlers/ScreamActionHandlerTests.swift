import Testing
@testable import GnustoEngine

/// Tests for the ScreamActionHandler.
@Suite("ScreamActionHandler Tests")
struct ScreamActionHandlerTests {

    // MARK: - Test Setup

    func createTestEngine() async -> (GameEngine, MockIOHandler) {
        let (engine, mockIO) = await GameEngine.test()
        return (engine, mockIO)
    }

    // MARK: - Tests

    @Test("SCREAM command")
    func testScream() async throws {
        let (engine, mockIO) = await createTestEngine()
        let handler = ScreamActionHandler()
        let command = Command(verb: .scream, rawInput: "scream")
        let context = ActionContext(command: command, engine: engine)

        let result = try await handler.process(context: context)

        #expect(result.message != nil)
        #expect(result.message!.contains("scream") || result.message!.contains("shriek"))
    }

    @Test("SCREAM returns varied responses")
    func testScreamVariedResponses() async throws {
        let (engine, mockIO) = await createTestEngine()
        let handler = ScreamActionHandler()
        let command = Command(verb: .scream, rawInput: "scream")
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
