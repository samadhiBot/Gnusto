import Testing
@testable import GnustoEngine

/// Tests for the DanceActionHandler.
@Suite("DanceActionHandler Tests")
struct DanceActionHandlerTests {

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

    @Test("DANCE command")
    func testDance() async throws {
        let (engine, mockIO) = await createTestEngine()
        let handler = DanceActionHandler()
        let command = Command(verb: .dance, rawInput: "dance")
        let context = ActionContext(command: command, engine: engine)

        let result = try await handler.process(context: context)

        #expect(result.message != nil)
        #expect(result.message!.contains("danc") || result.message!.contains("forbidden"))
    }

    @Test("DANCE includes classic ZIL response")
    func testDanceClassicResponse() async throws {
        let (engine, mockIO) = await createTestEngine()
        let handler = DanceActionHandler()
        let command = Command(verb: .dance, rawInput: "dance")
        let context = ActionContext(command: command, engine: engine)

        var foundClassicResponse = false

        // Run multiple times to check if classic response appears
        for _ in 0..<20 {
            let result = try await handler.process(context: context)
            if let message = result.message, message.contains("Dancing is forbidden") {
                foundClassicResponse = true
                break
            }
        }

        // The classic response should appear at least once in 20 tries
        #expect(foundClassicResponse, "Should include the classic 'Dancing is forbidden' response")
    }
}
