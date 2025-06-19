import CustomDump
import GnustoEngine
import Testing

/// Tests for the GiggleActionHandler.
@Suite("GiggleActionHandler Tests")
struct GiggleActionHandlerTests {
    @Test("GIGGLE command")
    func testGiggle() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("giggle")

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > giggle
            You giggle uncontrollably. How embarrassing!
            """)
    }

    @Test("GIGGLE returns varied responses")
    func testGiggleVariedResponses() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("giggle", times: 3)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > giggle
            You giggle uncontrollably. How embarrassing!

            > giggle
            You snicker quietly. How mischievous!

            > giggle
            You chortle with delight.
            """)
    }
}
