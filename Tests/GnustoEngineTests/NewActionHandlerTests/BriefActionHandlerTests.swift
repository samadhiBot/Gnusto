import Testing
import CustomDump
@testable import GnustoEngine

@Suite("BriefActionHandler Tests")
struct BriefActionHandlerTests {

    @Test("BRIEF command enables brief mode")
    func testBriefCommand() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Ensure verbose mode is on initially for a clear test
        _ = await engine.setGlobal(.isVerboseMode, to: true)
        #expect(await engine.hasGlobal(.isVerboseMode) == true)

        // When
        try await engine.execute("brief")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > brief
            Brief mode is now on. Location descriptions will be
            shown only when you first enter a location.
            """)

        // Verify state change
        #expect(await engine.hasGlobal(.isBriefMode) == true)
        #expect(await engine.hasGlobal(.isVerboseMode) == false)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = BriefActionHandler()
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = BriefActionHandler()
        #expect(handler.verbs.contains(.brief))
        #expect(handler.verbs.count == 1)
    }

    @Test("Handler does not require light")
    func testRequiresLightProperty() async throws {
        let handler = BriefActionHandler()
        #expect(handler.requiresLight == false)
    }
}
