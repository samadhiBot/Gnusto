import Testing
import CustomDump
@testable import GnustoEngine

@Suite("CryActionHandler Tests")
struct CryActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("CRY syntax works")
    func testCrySyntax() async throws {
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
        try await engine.execute("cry")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > cry
            You burst into tears.
            """)
    }

    @Test("WEEP syntax works")
    func testWeepSyntax() async throws {
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
        try await engine.execute("weep")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > weep
            You burst into tears.
            """)
    }

    @Test("SOB syntax works")
    func testSobSyntax() async throws {
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
        try await engine.execute("sob")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > sob
            You burst into tears.
            """)
    }

    // MARK: - Processing Testing

    @Test("Cry provides atmospheric response")
    func testCryAtmosphericResponse() async throws {
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
        try await engine.execute("cry")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > cry
            You burst into tears.
            """)
    }

    @Test("Cry works in dark rooms")
    func testCryWorksInDarkRooms() async throws {
        // Given: Dark room (no light required for crying)
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
        try await engine.execute("cry")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > cry
            You burst into tears.
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = CryActionHandler()
        // CryActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = CryActionHandler()
        #expect(handler.verbs.contains(.cry))
        #expect(handler.verbs.contains(.weep))
        #expect(handler.verbs.contains(.sob))
        #expect(handler.verbs.count == 3)
    }

    @Test("Handler does not require light")
    func testDoesNotRequireLight() async throws {
        let handler = CryActionHandler()
        #expect(handler.requiresLight == false)
    }
}
