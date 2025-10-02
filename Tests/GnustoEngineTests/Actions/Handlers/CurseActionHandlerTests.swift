import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("CurseActionHandler Tests")
struct CurseActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("CURSE syntax works")
    func testCurseSyntax() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("curse")

        // Then
        await mockIO.expectOutput(
            """
            > curse
            You unleash a cascade of inventive profanity.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Curse works in dark rooms")
    func testCurseWorksInDarkRooms() async throws {
        // Given: Dark room (no light required for cursing)
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("curse")

        // Then
        await mockIO.expectOutput(
            """
            > curse
            You unleash a cascade of inventive profanity.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = CurseActionHandler()
        expectNoDifference(
            handler.synonyms,
            [
                .curse,
                .swear,
                .shit,
                .fuck,
                .damn,
            ])
    }

    @Test("Handler does not require light")
    func testDoesNotRequireLight() async throws {
        let handler = CurseActionHandler()
        #expect(handler.requiresLight == false)
    }
}
