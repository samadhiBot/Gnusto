import CustomDump
import Testing

@testable import GnustoEngine

@Suite("HelpActionHandler Tests")
struct HelpActionHandlerTests {

    @Test("Help displays help text")
    func testHelpDisplaysHelpText() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test()

        // When
        try await engine.execute("help")

        // Then
        let output = await mockIO.flush()
        #expect(output.contains("This is an interactive fiction game"))
        #expect(output.contains("Common commands:"))
        #expect(output.contains("LOOK"))
        #expect(output.contains("TAKE"))
        #expect(output.contains("INVENTORY"))
    }

    @Test("Help command integration")
    func testHelpCommand() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("help")

        // Assert
        let output = await mockIO.flush()
        #expect(output.contains("> help"))
        #expect(output.contains("This is an interactive fiction game"))
    }
}
