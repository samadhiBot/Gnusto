import Testing
import CustomDump
@testable import GnustoEngine

@Suite("LaughActionHandler Tests")
struct LaughActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("LAUGH syntax works")
    func testLaughSyntax() async throws {
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
        try await engine.execute("laugh")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > laugh
            You laugh heartily.
            """)
    }

    @Test("GIGGLE syntax works")
    func testGiggleSyntax() async throws {
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

        // When
        try await engine.execute("giggle")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > giggle
            You laugh heartily.
            """)
    }

    // MARK: - Processing Testing

    @Test("Laugh provides atmospheric response")
    func testLaughAtmosphericResponse() async throws {
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

        // When
        try await engine.execute("laugh")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > laugh
            You laugh heartily.
            """)
    }

    @Test("Laugh works in dark rooms")
    func testLaughWorksInDarkRooms() async throws {
        // Given: Dark room (no light required for laughing)
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
        try await engine.execute("laugh")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > laugh
            You laugh heartily.
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = LaughActionHandler()
        // LaughActionHandler doesn't specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = LaughActionHandler()
        #expect(handler.verbs.contains(.laugh))
        #expect(handler.verbs.contains(.giggle))
        #expect(handler.verbs.count == 2)
    }

    @Test("Handler does not require light")
    func testDoesNotRequireLight() async throws {
        let handler = LaughActionHandler()
        #expect(handler.requiresLight == false)
    }
}
