import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("SingActionHandler Tests")
struct SingActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("SING syntax works")
    func testSingSyntax() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("sing")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > sing
            Your voice rises in what you generously call song.
            """
        )
    }

    @Test("SERENADE DIRECTOBJECT syntax works")
    func testSerenadeDirectObjectSyntax() async throws {
        // Given
        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A simple wooden box."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("serenade the wooden box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > serenade the wooden box
            The wooden box remains unmoved by your musical offering,
            lacking the capacity for appreciation.
            """
        )
    }

    @Test("SING TO CHARACTER syntax works")
    func testSingToCharacterSyntax() async throws {
        // Given
        let wizard = Item(
            id: "wizard",
            .name("old wizard"),
            .description("A wise old wizard with a long beard."),
            .characterSheet(.wise),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: wizard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("sing to the old wizard")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > sing to the old wizard
            Your song draws a smile from the old wizard, though whether
            from joy or pity remains unclear.
            """
        )
    }

    @Test("SING TO ENEMY syntax works")
    func testSingToEnemySyntax() async throws {
        // Given
        let game = MinimalGame(
            items: Lab.troll
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("sing to the hideous troll")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > sing to the hideous troll
            You can't see any hideous troll here.
            """
        )
    }

    // MARK: - Processing Testing

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
        expectNoDifference(
            output,
            """
            > sing
            Your voice rises in what you generously call song.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = SingActionHandler()
        #expect(handler.synonyms.contains(.sing))
        #expect(handler.synonyms.contains(.hum))
        #expect(handler.synonyms.count == 2)
    }

    @Test("Handler does not require light")
    func testDoesNotRequireLight() async throws {
        let handler = SingActionHandler()
        #expect(handler.requiresLight == false)
    }
}
