import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("WaitActionHandler Tests")
struct WaitActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("WAIT syntax works")
    func testWaitSyntax() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wait")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wait
            Moments slip away like sand through fingers.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Wait works in dark rooms")
    func testWaitWorksInDarkRooms() async throws {
        // Given: Dark room
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
        try await engine.execute("wait")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wait
            Moments slip away like sand through fingers.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testCorrectVerbs() async throws {
        // Given
        let handler = WaitActionHandler()

        // When
        let verbIDs = handler.synonyms

        // Then
        #expect(verbIDs.contains(.wait))
        #expect(verbIDs.contains("z"))
    }

    @Test("Handler does not require light")
    func testHandlerDoesNotRequireLight() async throws {
        // Given
        let handler = WaitActionHandler()

        // When & Then
        #expect(handler.requiresLight == false)
    }
}
