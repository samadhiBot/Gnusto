import CustomDump
import Testing

@testable import GnustoEngine

@Suite("CryActionHandler Tests")
struct CryActionHandlerTests {
    @Test("CRY command")
    func testCry() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("cry")

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > cry
            You bawl your eyes out, which is somewhat cathartic.
            """)
    }

    @Test("CRY returns varied responses")
    func testCryVariedResponses() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("cry", times: 3)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > cry
            You bawl your eyes out, which is somewhat cathartic.

            > cry
            You sob dramatically, and feel a little better.

            > cry
            You weep bitter tears.
            """)
    }
}
