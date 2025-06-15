import CustomDump
import Testing

@testable import GnustoEngine

/// Tests for the ChompActionHandler.
@Suite("ChompActionHandler Tests")
struct ChompActionHandlerTests {

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

    @Test("CHOMP without object")
    func testChompWithoutObject() async throws {
        let (engine, mockIO) = await createTestEngine()
        let command = Command(verb: .chomp, rawInput: "chomp")

        // Act
        await engine.execute(command: command)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, "You chomp your teeth together menacingly.")
    }

    @Test("CHOMP with object")
    func testChompWithObject() async throws {
        let (engine, mockIO) = await createTestEngine()

        let command = Command(
            verb: .chomp,
            directObject: .item(.startItem),
            rawInput: "chomp the pebble"
        )

        // Act
        await engine.execute(command: command)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            You give the pebble a tentative nibble. It tastes terrible.
            """)
    }

    @Test("CHOMP validation passes without object")
    func testChompValidationWithoutObject() async throws {
        let (engine, mockIO) = await createTestEngine()
        let command = Command(verb: .chomp, rawInput: "chomp")

        // Act
        await engine.execute(command: command)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, "You chomp your teeth together menacingly.")
    }
}
