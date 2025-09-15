import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("CryActionHandler Tests")
struct CryActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("CRY syntax works")
    func testCrySyntax() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("cry")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > cry
            A moment of melancholy overtakes you.
            """
        )
    }

    // MARK: - Processing Testing

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
        expectNoDifference(
            output,
            """
            > cry
            A moment of melancholy overtakes you.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = CryActionHandler()
        #expect(handler.synonyms.contains(.cry))
        #expect(handler.synonyms.contains(.weep))
        #expect(handler.synonyms.contains(.sob))
        #expect(handler.synonyms.count == 3)
    }

    @Test("Handler does not require light")
    func testDoesNotRequireLight() async throws {
        let handler = CryActionHandler()
        #expect(handler.requiresLight == false)
    }
}
