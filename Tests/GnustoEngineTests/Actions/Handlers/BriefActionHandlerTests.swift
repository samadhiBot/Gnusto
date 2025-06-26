import Testing
import CustomDump
@testable import GnustoEngine

@Suite("BriefActionHandler Tests")
struct BriefActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("BRIEF syntax works")
    func testBriefSyntax() async throws {
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
        try await engine.execute("brief")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > brief
            Brief mode is now on. Location descriptions will be shown only
            when you first enter a location.
            """)
    }

    // MARK: - Processing Testing

    @Test("Brief command sets brief mode")
    func testBriefCommandSetsBriefMode() async throws {
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

        // Ensure we start in verbose mode
        try await engine.apply(
            engine.setGlobal(.isVerboseMode, to: true)
        )

        // When
        try await engine.execute("brief")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > brief
            Brief mode is now on. Location descriptions will be shown only
            when you first enter a location.
            """)

        // Verify state changes
        let isBriefMode = await engine.hasGlobal(.isBriefMode)
        let isVerboseMode = await engine.hasGlobal(.isVerboseMode)
        #expect(isBriefMode == true)
        #expect(isVerboseMode == false)
    }

    @Test("Brief command clears verbose mode")
    func testBriefCommandClearsVerboseMode() async throws {
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

        let (engine, _) = await GameEngine.test(blueprint: game)

        // Start with verbose mode enabled
        try await engine.apply(
            engine.setGlobal(.isVerboseMode, to: true)
        )
        let isVerboseBeforeBrief = await engine.hasGlobal(.isVerboseMode)
        #expect(isVerboseBeforeBrief == true)

        // When
        try await engine.execute("brief")

        // Then
        let isBriefMode = await engine.hasGlobal(.isBriefMode)
        let isVerboseMode = await engine.hasGlobal(.isVerboseMode)
        #expect(isBriefMode == true)
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
        expectNoDifference(output, """
            > brief
            Brief mode is now on. Location descriptions will be shown only
            when you first enter a location.
            """)

        // Verify state change occurred
        let isBriefMode = await engine.hasGlobal(.isBriefMode)
        #expect(isBriefMode == true)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Intents")
    func testIntents() async throws {
        let handler = BriefActionHandler()
        // BriefActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = BriefActionHandler()
        #expect(handler.verbs.contains(.brief))
        #expect(handler.verbs.count == 1)
    }

    @Test("Handler does not require light")
    func testDoesNotRequireLight() async throws {
        let handler = BriefActionHandler()
        #expect(handler.requiresLight == false)
    }
}
