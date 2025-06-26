import Testing
import CustomDump
@testable import GnustoEngine

@Suite("SingActionHandler Tests")
struct SingActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("SING syntax works")
    func testSingSyntax() async throws {
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
        try await engine.execute("sing")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > sing
            You sing a little tune.
            """)
    }

    @Test("HUM syntax works")
    func testHumSyntax() async throws {
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
        try await engine.execute("hum")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > hum
            You sing a little tune.
            """)
    }

    // MARK: - Processing Testing

    @Test("Sing provides atmospheric response")
    func testSingAtmosphericResponse() async throws {
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
        try await engine.execute("sing")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > sing
            You sing a little tune.
            """)
    }

    @Test("Sing works in dark rooms")
    func testSingWorksInDarkRooms() async throws {
        // Given: Dark room (no light required for singing)
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
        try await engine.execute("sing")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > sing
            You sing a little tune.
            """)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Intents")
    func testIntents() async throws {
        let handler = SingActionHandler()
        // SingActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = SingActionHandler()
        #expect(handler.verbs.contains(.sing))
        #expect(handler.verbs.contains(.hum))
        #expect(handler.verbs.count == 2)
    }

    @Test("Handler does not require light")
    func testDoesNotRequireLight() async throws {
        let handler = SingActionHandler()
        #expect(handler.requiresLight == false)
    }
}
