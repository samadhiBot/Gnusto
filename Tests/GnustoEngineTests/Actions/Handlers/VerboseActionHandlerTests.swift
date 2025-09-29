import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("VerboseActionHandler Tests")
struct VerboseActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("VERBOSE syntax works")
    func testVerboseSyntax() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("verbose")

        // Then
        await mockIO.expectOutput(
            """
            > verbose
            Maximum verbosity. Full location descriptions will be shown
            every time you enter a location.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Verbose command sets verbose mode")
    func testVerboseCommandSetsVerboseMode() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Ensure we start in brief mode
        try await engine.apply(
            engine.clearFlag(.isVerboseMode)
        )

        // When
        try await engine.execute("verbose")

        // Then
        await mockIO.expectOutput(
            """
            > verbose
            Maximum verbosity. Full location descriptions will be shown
            every time you enter a location.
            """
        )

        // Verify state changes
        let isVerboseMode = await engine.hasFlag(.isVerboseMode)
        #expect(isVerboseMode == true)
    }

    @Test("Verbose command clears brief mode")
    func testVerboseCommandClearsBriefMode() async throws {
        // Given
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)

        // Start with brief mode enabled
        try await engine.apply(
            engine.clearFlag(.isVerboseMode)
        )

        // When
        try await engine.execute("verbose")

        // Then
        let isVerboseMode = await engine.hasFlag(.isVerboseMode)
        #expect(isVerboseMode == true)
    }

    @Test("Verbose works in dark rooms")
    func testVerboseWorksInDarkRooms() async throws {
        // Given: Dark room (no light required for verbose command)
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
        try await engine.execute("verbose")

        // Then
        await mockIO.expectOutput(
            """
            > verbose
            Maximum verbosity. Full location descriptions will be shown
            every time you enter a location.
            """
        )

        // Verify state change occurred
        let isVerboseMode = await engine.hasFlag(.isVerboseMode)
        #expect(isVerboseMode == true)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = VerboseActionHandler()
        #expect(handler.synonyms.contains(.verbose))
        #expect(handler.synonyms.count == 1)
    }

    @Test("Handler does not require light")
    func testDoesNotRequireLight() async throws {
        let handler = VerboseActionHandler()
        #expect(handler.requiresLight == false)
    }
}
