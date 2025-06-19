import CustomDump
import Testing

@testable import GnustoEngine

/// Tests for the DanceActionHandler.
@Suite("DanceActionHandler Tests")
struct DanceActionHandlerTests {
    @Test("DANCE command")
    func testDance() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("dance", times: 3)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > dance
            You cut a rug with style and panache.

            > dance
            You perform a modern interpretive dance.

            > dance
            You break into spontaneous choreography.
            """)
    }
}
