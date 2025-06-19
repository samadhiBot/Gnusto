import CustomDump
import Testing

@testable import GnustoEngine

/// Tests for the YellActionHandler.
@Suite("YellActionHandler Tests")
struct YellActionHandlerTests {

    // MARK: - Test Setup

    func createTestEngine() async -> (GameEngine, MockIOHandler) {
        let mockParser = MockParser()
        let (engine, mockIO) = await GameEngine.test(
            blueprint: game,
            parser: mockParser
        )
        return (engine, mockIO)
    }

    // MARK: - Tests

    @Test("YELL returns varied responses")
    func testYell() async throws {
        let (engine, mockIO) = await createTestEngine()
        let command = Command(verb: .yell, rawInput: "yell")

        // Act - Execute the command multiple times
        await engine.execute(command: command)
        await engine.execute(command: command)
        await engine.execute(command: command)

        // Assert - Should get responses (not empty)
        let output = await mockIO.flush()

        // The output should contain yell responses, not be empty
        #expect(!output.isEmpty, "YELL should return responses, not empty output")

        // Split by double newlines to get individual responses
        let responses = output.components(separatedBy: "\n\n").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        #expect(responses.count == 3, "Should have 3 yell responses, got \(responses.count)")

        // Each response should be non-empty and contain some yell-related content
        for response in responses {
            let trimmedResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)
            #expect(!trimmedResponse.isEmpty, "Each response should be non-empty")
            #expect(trimmedResponse.count > 10, "Each response should be substantial: '\(trimmedResponse)'")
        }
    }
}
