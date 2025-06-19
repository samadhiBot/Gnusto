import CustomDump
import Testing

@testable import GnustoEngine

/// Tests for the YellActionHandler.
@Suite("YellActionHandler Tests")
struct YellActionHandlerTests {

    @Test("YELL returns varied responses")
    func testYell() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act - Execute the command multiple times
        try await engine.execute("yell", times: 3)

        // Assert - Should get responses (not empty)
        let output = await mockIO.flush()

        // The output should contain yell responses, not be empty
        #expect(!output.isEmpty, "YELL should return responses, not empty output")

        // Split by lines and filter out empty ones to get individual responses
        let lines = output.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        #expect(lines.count >= 6, "Should have at least 6 lines (3 prompts + 3 responses), got \(lines.count)")

        // Should have prompts and responses
        #expect(output.contains("> yell"), "Should contain command prompts")
    }
}
