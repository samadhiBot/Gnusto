import CustomDump
import Testing

import GnustoEngine

/// Tests for the LaughActionHandler.
@Suite("LaughActionHandler Tests")
struct LaughActionHandlerTests {
    @Test("LAUGH returns varied responses")
    func testLaughVariedResponses() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // When
        try await engine.execute("laugh", times: 3)

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > laugh
            You laugh heroically at your impossible circumstances.

            > laugh
            You laugh brazenly at your predicament.

            > laugh
            You let out a mirthless chuckle.
            """)
    }

    @Test("LAUGH at an object")
    func testLaugh() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // When
        try await engine.execute("laugh at the pebble")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > laugh at the pebble
            You laugh heroically at your impossible circumstances.
            """)
    }
}
