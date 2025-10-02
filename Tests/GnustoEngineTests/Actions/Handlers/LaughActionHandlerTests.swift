import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("LaughActionHandler Tests")
struct LaughActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("LAUGH syntax works")
    func testLaughSyntax() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("laugh")

        // Then
        await mockIO.expect(
            """
            > laugh
            Laughter bubbles up from somewhere deep within.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Laugh works in dark rooms")
    func testLaughWorksInDarkRooms() async throws {
        // Given: Dark room (no light required for laughing)
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("laugh")

        // Then
        await mockIO.expect(
            """
            > laugh
            Laughter bubbles up from somewhere deep within.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = LaughActionHandler()
        expectNoDifference(handler.synonyms, [.laugh, .chuckle, .giggle, .snicker, .chortle])
    }

    @Test("Handler does not require light")
    func testDoesNotRequireLight() async throws {
        let handler = LaughActionHandler()
        #expect(handler.requiresLight == false)
    }
}
