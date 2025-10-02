import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("HelpActionHandler Tests")
struct HelpActionHandlerTests {

    // MARK: - Syntax Rule Testing

    let helpResponse = """
        > help
        This is an interactive fiction game. You control the story by
        typing commands.

        Common commands:
        - LOOK or L - Look around your current location
        - EXAMINE <object> or X <object> - Look at something closely
        - TAKE <object> or GET <object> - Pick up an item
        - DROP <object> - Put down an item you're carrying
        - INVENTORY or I - See what you're carrying
        - GO <direction> or just <direction> - Move in a direction (N,
          S, E, W, etc.)
        - OPEN <object> - Open doors, containers, etc.
        - CLOSE <object> - Close doors, containers, etc.
        - PUT <object> IN <container> - Put something in a container
        - PUT <object> ON <surface> - Put something on a surface
        - SAVE - Save your game
        - RESTORE - Restore a saved game
        - QUIT - End the game

        You can use multiple objects with some commands (TAKE ALL, DROP
        SWORD AND SHIELD).

        Try different things--experimentation is part of the fun!
        """

    @Test("HELP syntax works")
    func testHelpSyntax() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("help")

        // Then
        await mockIO.expectOutput(helpResponse)
    }

    // MARK: - Validation Testing

    @Test("Help works in any condition")
    func testHelpWorksInAnyCondition() async throws {
        // Given: Dark room (help should still work)
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")
            // Note: No .inherentlyLit property

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("help")

        // Then
        await mockIO.expectOutput(helpResponse)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = HelpActionHandler()
        #expect(handler.synonyms.contains(.help))
        #expect(handler.synonyms.count == 1)
    }

    @Test("Handler does not require light")
    func testRequiresLightProperty() async throws {
        let handler = HelpActionHandler()
        #expect(handler.requiresLight == false)
    }
}
