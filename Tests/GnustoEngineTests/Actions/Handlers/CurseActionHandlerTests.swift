import Testing
import CustomDump
@testable import GnustoEngine

@Suite("CurseActionHandler Tests")
struct CurseActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("CURSE syntax works")
    func testCurseSyntax() async throws {
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
        try await engine.execute("curse")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > curse
            You let loose a string of expletives that reveals an impressive
            technical proficiency.
            """)
    }

    @Test("DAMN syntax works")
    func testDamnSyntax() async throws {
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
        try await engine.execute("damn")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > damn
            You let loose a string of expletives that reveals an impressive
            technical proficiency.
            """)
    }

    @Test("FUCK syntax works")
    func testFuckSyntax() async throws {
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
        try await engine.execute("fuck")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > fuck
            You let loose a string of expletives that reveals an impressive
            technical proficiency.
            """)
    }

    @Test("SHIT syntax works")
    func testShitSyntax() async throws {
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
        try await engine.execute("shit")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > shit
            You let loose a string of expletives that reveals an impressive
            technical proficiency.
            """)
    }

    // MARK: - Processing Testing

    @Test("Curse provides varied atmospheric responses")
    func testCurseAtmosphericResponse() async throws {
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
        try await engine.execute("curse", times: 3)

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > curse
            You let loose a string of expletives that reveals an impressive
            technical proficiency.
            """)
    }

    @Test("Curse works in dark rooms")
    func testCurseWorksInDarkRooms() async throws {
        // Given: Dark room (no light required for cursing)
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
        try await engine.execute("curse")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > curse
            You let loose a string of expletives that reveals an impressive
            technical proficiency.
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = CurseActionHandler()
        // CurseActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = CurseActionHandler()
        #expect(handler.verbs.contains(.curse))
        #expect(handler.verbs.contains(.damn))
        #expect(handler.verbs.contains(.fuck))
        #expect(handler.verbs.contains(.shit))
        #expect(handler.verbs.count == 4)
    }

    @Test("Handler does not require light")
    func testDoesNotRequireLight() async throws {
        let handler = CurseActionHandler()
        #expect(handler.requiresLight == false)
    }
}
