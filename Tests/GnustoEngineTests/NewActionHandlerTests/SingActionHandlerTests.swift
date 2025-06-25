import CustomDump
import Testing

@testable import GnustoEngine

@Suite
struct SingActionHandlerTests {
    // MARK: - Syntax Rule Testing

    @Test("Syntax rule accepts 'sing'")
    func testSyntaxRule() async throws {
        let handler = SingActionHandler()
        let syntax = try handler.syntax.primary.parse("sing")
        #expect(syntax.verb == .sing)
        #expect(isNil(syntax.directObject))
    }

    // MARK: - Validation Testing

    @Test("Validation is not required")
    func testValidation() async throws {
        // SingActionHandler has no validation logic.
        // This test exists to confirm that fact.
    }

    // MARK: - Processing Testing

    @Test("Processing 'sing' returns a message")
    func testProcessSingReturnsMessage() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())

        // When
        try await engine.execute("sing")

        // Then
        let output = await mockIO.flush()
        #expect(!output.isEmpty)
    }

    // MARK: - ActionID Testing

    @Test("Handler has correct action ID")
    func testActionID() {
        #expect(SingActionHandler().actionID == .sing)
    }
}
