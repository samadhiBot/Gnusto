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

    @Test("CHOMP command")
    func testChomp() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("chomp", times: 3)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > chomp
            You chomp with a conviction that makes reality itself
            seem negotiable.

            > chomp
            You chomp enthusiastically at the air, flexing your impressive
            jaw strength.

            > chomp
            You gnash your teeth with the passion of one who believes in
            their vision.
            """)
    }

    @Test("CHOMP without object")
    func testChompWithoutObject() async throws {
        let (engine, mockIO) = await createTestEngine()

        // Act
        try await engine.execute("chomp")

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > chomp
            You chomp with a conviction that makes reality itself
            seem negotiable.
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
            You chomp the pebble with the fearless innovation of someone
            unbound by convention.
            """)
    }
}
