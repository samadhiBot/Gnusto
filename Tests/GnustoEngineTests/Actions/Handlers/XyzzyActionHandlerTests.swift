import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("XyzzyActionHandler Tests")
struct XyzzyActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("XYZZY syntax works")
    func testXyzzySyntax() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("xyzzy")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > xyzzy
            The ancient magic fails to respond to your call.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("XYZZY works in dark rooms")
    func testXyzzyWorksInDarkRooms() async throws {
        // Given: Dark room (to verify light is not required)
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("xyzzy")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > xyzzy
            The ancient magic fails to respond to your call.
            """
        )
    }

    @Test("XYZZY doesn't modify game state")
    func testXyzzyNoStateChanges() async throws {
        // Given
        let lamp = Item(
            id: "lamp",
            .name("brass lamp"),
            .description("A shiny brass lamp."),
            .isLightSource,
            .isDevice,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Record initial state
        let initialLamp = await engine.item("lamp")
        let initialScore = await engine.player.score
        let initialTurnCount = await engine.player.moves

        // When
        try await engine.execute("xyzzy")

        // Then: State should be unchanged
        let finalLamp = await engine.item("lamp")
        let finalScore = await engine.player.score
        let finalTurnCount = await engine.player.moves

        #expect(await finalLamp.parent == initialLamp.parent)
        #expect(await finalLamp.hasFlag(.isTouched) == initialLamp.hasFlag(.isTouched))
        #expect(finalScore == initialScore)
        #expect(finalTurnCount == initialTurnCount + 1)

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > xyzzy
            The ancient magic fails to respond to your call.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = XyzzyActionHandler()
        #expect(handler.synonyms.contains(.xyzzy))
        #expect(handler.synonyms.count == 1)
    }

    @Test("Handler does not require light")
    func testRequiresLightProperty() async throws {
        let handler = XyzzyActionHandler()
        #expect(handler.requiresLight == false)
    }
}
