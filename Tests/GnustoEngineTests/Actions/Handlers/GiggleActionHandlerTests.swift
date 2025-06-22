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
            You chuckle with the fearless delight of someone who finds
            things funny that others do not.
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
            You chuckle with the fearless delight of someone who finds
            things funny that others do not.

            > giggle
            You chuckle with an appreciation for life’s subtle ironies.

            > giggle
            You snicker with the discerning wit of someone who sees the
            bigger picture.
            """)
    }
}
