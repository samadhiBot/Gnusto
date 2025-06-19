import CustomDump
import Testing

@testable import GnustoEngine

/// Tests for the ScreamActionHandler.
@Suite("ScreamActionHandler Tests")
struct ScreamActionHandlerTests {
    @Test("SCREAM returns varied responses")
    func testScreamVariedResponses() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("scream", times: 3)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > scream
            You howl like a wounded animal.

            > scream
            You let out a blood-curdling scream.

            > scream
            You let loose a scream that would wake the dead.
            """)
    }

    @Test("SCREAM at an object")
    func testScreamAtObject() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("scream at the pebble")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > scream at the pebble
            You howl like a wounded animal.
            """)
    }
}
