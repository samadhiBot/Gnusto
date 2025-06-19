import CustomDump
import Testing

@testable import GnustoEngine

/// Tests for the ChompActionHandler.
@Suite("ChompActionHandler Tests")
struct ChompActionHandlerTests {

    // MARK: - Test Setup

    func createTestEngine() async -> (GameEngine, MockIOHandler) {
        let (engine, mockIO) = await GameEngine.test()
        return (engine, mockIO)
    }

    // MARK: - Tests

    @Test("CHOMP without object")
    func testChompWithoutObject() async throws {
        let (engine, mockIO) = await createTestEngine()

        // Act
        try await engine.execute("chomp")

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > chomp
            You chomp at the air for everyone to see.
            """)
    }

    @Test("CHOMP with object")
    func testChompWithObject() async throws {
        let (engine, mockIO) = await createTestEngine()

        // Act
        try await engine.execute("chomp the pebble")

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > chomp the pebble
            You bite the pebble. Your teeth don’t make much of an
            impression.
            """)
    }
}
