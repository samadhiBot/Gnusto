import Testing
import CustomDump
@testable import GnustoEngine

@Suite("YellActionHandler Tests")
struct YellActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("YELL syntax works")
    func testYellSyntax() async throws {
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
        try await engine.execute("yell")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > yell
            You yell loudly.
            """)
    }

    @Test("SHOUT syntax works")
    func testShoutSyntax() async throws {
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
        try await engine.execute("shout")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > shout
            You yell loudly.
            """)
    }

    @Test("SCREAM syntax works")
    func testScreamSyntax() async throws {
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
        try await engine.execute("scream")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > scream
            You yell loudly.
            """)
    }

    // MARK: - Processing Testing

    @Test("Yell provides atmospheric response")
    func testYellAtmosphericResponse() async throws {
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
        try await engine.execute("yell")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > yell
            You yell loudly.
            """)
    }

    @Test("Yell works in dark rooms")
    func testYellWorksInDarkRooms() async throws {
        // Given: Dark room (no light required for yelling)
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
        try await engine.execute("yell")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > yell
            You yell loudly.
            """)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Intents")
    func testIntents() async throws {
        let handler = YellActionHandler()
        // YellActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = YellActionHandler()
        #expect(handler.verbs.contains(.yell))
        #expect(handler.verbs.contains(.shout))
        #expect(handler.verbs.contains(.scream))
        #expect(handler.verbs.count == 3)
    }

    @Test("Handler does not require light")
    func testDoesNotRequireLight() async throws {
        let handler = YellActionHandler()
        #expect(handler.requiresLight == false)
    }
}
