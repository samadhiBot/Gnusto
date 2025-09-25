import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("BriefActionHandler Tests")
struct BriefActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("BRIEF syntax works")
    func testBriefSyntax() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("brief")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > brief
            Brief mode is now on. Full location descriptions will be shown
            only when you first enter a location.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Brief command sets brief mode")
    func testBriefCommandSetsBriefMode() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Ensure we start in verbose mode
        try await engine.apply(
            engine.setFlag(.isVerboseMode)
        )

        // When
        try await engine.execute("brief")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > brief
            Brief mode is now on. Full location descriptions will be shown
            only when you first enter a location.
            """
        )

        // Verify state changes
        let isVerboseMode = await engine.hasFlag(.isVerboseMode)
        #expect(isVerboseMode == false)
    }

    @Test("Brief command clears verbose mode")
    func testBriefCommandClearsVerboseMode() async throws {
        // Given
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)

        // Start with verbose mode enabled
        try await engine.apply(
            engine.setFlag(.isVerboseMode)
        )
        let isVerboseBeforeBrief = await engine.hasFlag(.isVerboseMode)
        #expect(isVerboseBeforeBrief == true)

        // When
        try await engine.execute("brief")

        // Then
        let isVerboseMode = await engine.hasFlag(.isVerboseMode)
        #expect(isVerboseMode == false)
    }

    @Test("Brief works in dark rooms")
    func testBriefWorksInDarkRooms() async throws {
        // Given: Dark room (no light required for brief command)
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("brief")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > brief
            Brief mode is now on. Full location descriptions will be shown
            only when you first enter a location.
            """
        )

        // Verify state change occurred
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = BriefActionHandler()
        #expect(handler.synonyms.contains(.brief))
        #expect(handler.synonyms.count == 1)
    }

    @Test("Handler does not require light")
    func testDoesNotRequireLight() async throws {
        let handler = BriefActionHandler()
        #expect(handler.requiresLight == false)
    }
}
