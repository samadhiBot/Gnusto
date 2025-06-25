import Testing
import CustomDump
@testable import GnustoEngine

@Suite("VerboseActionHandler Tests")
struct VerboseActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("VERBOSE syntax works")
    func testVerboseSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("verbose")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > verbose
            Verbose mode is now on. Location descriptions will be
            shown every time you enter a location.
            """)
    }

    // MARK: - Processing Testing

    @Test("Verbose command sets verbose mode")
    func testVerboseCommandSetsVerboseMode() async throws {
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

        // Ensure we start in brief mode
        try await engine.setGlobal(.isBriefMode, to: true)

        // When
        try await engine.execute("verbose")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > verbose
            Verbose mode is now on. Location descriptions will be
            shown every time you enter a location.
            """)

        // Verify state changes
        let isVerboseMode = await engine.hasGlobal(.isVerboseMode)
        let isBriefMode = await engine.hasGlobal(.isBriefMode)
        #expect(isVerboseMode == true)
        #expect(isBriefMode == false)
    }

    @Test("Verbose command clears brief mode")
    func testVerboseCommandClearsBriefMode() async throws {
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

        // Start with brief mode enabled
        try await engine.setGlobal(.isBriefMode, to: true)
        let isBriefBeforeVerbose = await engine.hasGlobal(.isBriefMode)
        #expect(isBriefBeforeVerbose == true)

        // When
        try await engine.execute("verbose")

        // Then
        let isVerboseMode = await engine.hasGlobal(.isVerboseMode)
        let isBriefMode = await engine.hasGlobal(.isBriefMode)
        #expect(isVerboseMode == true)
        #expect(isBriefMode == false)
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
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > verbose
            Verbose mode is now on. Location descriptions will be
            shown every time you enter a location.
            """)

        // Verify state change occurred
        let isVerboseMode = await engine.hasGlobal(.isVerboseMode)
        #expect(isVerboseMode == true)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = VerboseActionHandler()
        // VerboseActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = VerboseActionHandler()
        #expect(handler.verbs.contains(.verbose))
        #expect(handler.verbs.count == 1)
    }

    @Test("Handler does not require light")
    func testDoesNotRequireLight() async throws {
        let handler = VerboseActionHandler()
        #expect(handler.requiresLight == false)
    }
}
