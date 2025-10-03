import CustomDump
import GnustoTestSupport
import Testing

@testable import GnustoEngine

@Suite("RestartActionHandler Tests")
struct RestartActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("RESTART syntax works with YES confirmation")
    func testRestartSyntaxWithYes() async throws {
        // Given
        let sword = Item("sword")
            .name("magic sword")
            .description("A gleaming magic sword.")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: sword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Take the sword to change game state
        try await engine.execute("take sword")
        _ = await mockIO.flush()  // Clear output buffer

        // Verify sword is in inventory before restart
        let swordBeforeRestart = await engine.item("sword")
        #expect(await swordBeforeRestart.playerIsHolding)

        // Set up mock to respond "y" to restart confirmation
        await mockIO.enqueueInput("y")

        // When: Execute restart command
        try await engine.execute("restart")

        // Then
        await mockIO.expect(
            """
            > restart
            If you restart now you will lose any unsaved progress. Are you
            sure you want to restart? (Y is affirmative): y
            """
        )

        // Verify restart was requested
        let shouldRestart = await engine.shouldRestart
        #expect(shouldRestart == true)
    }

    @Test("RESTART syntax works with NO cancellation")
    func testRestartSyntaxWithNo() async throws {
        // Given
        let sword = Item("sword")
            .name("magic sword")
            .description("A gleaming magic sword.")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: sword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Take the sword to change game state
        try await engine.execute("take sword")
        _ = await mockIO.flush()  // Clear output buffer

        // Verify sword is in inventory before restart attempt
        let swordBefore = await engine.item("sword")
        #expect(await swordBefore.playerIsHolding)

        // Set up mock to respond "n" to restart confirmation
        await mockIO.enqueueInput("n")

        // When: Execute restart command
        try await engine.execute("restart")

        // Then
        await mockIO.expect(
            """
            > restart
            If you restart now you will lose any unsaved progress. Are you
            sure you want to restart? (Y is affirmative): n
            Restart cancelled.
            """
        )

        // Verify restart was NOT requested
        let shouldRestart = await engine.shouldRestart
        #expect(shouldRestart == false)

        // Verify game state was not reset
        let swordAfter = await engine.item("sword")
        #expect(await swordAfter.playerIsHolding)
    }

    @Test("RESTART handles invalid responses")
    func testRestartHandlesInvalidResponses() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up mock to respond with invalid then valid response
        await mockIO.enqueueInput("maybe", "no")

        // When: Execute restart command
        try await engine.execute("restart")

        // Then
        await mockIO.expect(
            """
            > restart
            If you restart now you will lose any unsaved progress. Are you
            sure you want to restart? (Y is affirmative): maybe
            Your response defies binary interpretation. I'll take that as a
            'no'.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("RESTART requires no validation")
    func testRestartRequiresNoValidation() async throws {
        // Given: Dark room (to verify light is not required)
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")
            // Note: No .inherentlyLit property

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up mock to respond "n" to restart confirmation
        await mockIO.enqueueInput("n")

        // When: RESTART should work even in darkness
        try await engine.execute("restart")

        // Then: Should succeed even without light
        await mockIO.expect(
            """
            > restart
            If you restart now you will lose any unsaved progress. Are you
            sure you want to restart? (Y is affirmative): n
            Restart cancelled.
            """
        )
    }

    // MARK: - Handler Properties Testing

    @Test("Handler does not require light")
    func testRequiresLightProperty() async throws {
        let handler = RestartActionHandler()
        #expect(handler.requiresLight == false)
    }

    @Test("Handler uses correct syntax rules")
    func testSyntaxRules() async throws {
        let handler = RestartActionHandler()
        #expect(handler.syntax.count == 1)
        #expect(handler.synonyms.contains(.restart))
    }
}
