import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("YellActionHandler Tests")
struct YellActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("YELL syntax works")
    func testYellSyntax() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("yell")

        // Then
        await mockIO.expectOutput(
            """
            > yell
            Your voice tears through the silence like a blade.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Yell works in dark rooms")
    func testYellWorksInDarkRooms() async throws {
        // Given: Dark room (no light required for yelling)
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("yell")

        // Then
        await mockIO.expectOutput(
            """
            > yell
            Your voice tears through the silence like a blade.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = YellActionHandler()
        expectNoDifference(handler.synonyms, [.yell, .shout, .scream, .shriek, .holler])
    }

    @Test("Handler does not require light")
    func testDoesNotRequireLight() async throws {
        let handler = YellActionHandler()
        #expect(handler.requiresLight == false)
    }
}
