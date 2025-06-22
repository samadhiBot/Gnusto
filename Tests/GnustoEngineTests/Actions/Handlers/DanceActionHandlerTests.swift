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
            You dance with an interpretive boldness that transcends
            conventional movement.

            > dance
            You dance with admirable commitment to the full spectrum of
            human motion.

            > dance
            You dance with the natural grace of one unencumbered by
            traditional technique.
            """)
    }
}
