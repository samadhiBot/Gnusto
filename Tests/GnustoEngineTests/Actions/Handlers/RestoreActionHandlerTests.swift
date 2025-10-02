import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("RestoreActionHandler Tests")
struct RestoreActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("RESTORE syntax works with YES confirmation")
    func testRestoreSyntaxWithYes() async throws {
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

        try await engine.execute("save")

        // Verify sword is NOT in inventory at save, an zero moves
        #expect(await engine.item("sword").playerIsHolding == false)
        #expect(await engine.player.moves == 0)

        // Take the sword to change game state
        try await engine.execute("take sword")

        // Verify sword is in inventory before restore, and one move
        #expect(await engine.item("sword").playerIsHolding == true)
        #expect(await engine.player.moves == 1)

        // Set up mock to respond "y" to restore confirmation
        await mockIO.enqueueInput("y")

        // When: Execute restore command
        try await engine.execute("restore")

        // Then
        await mockIO.expectOutput(
            """
            > save
            Game saved.

            > take sword
            Taken.

            > restore
            If you restore your saved game now you will lose any unsaved
            progress. Are you sure you want to restore? (Y is affirmative): y
            Game restored.
            """
        )

        // Verify sword is NOT in inventory after restore, and back to zero moves
        #expect(await engine.item("sword").playerIsHolding == false)
        #expect(await engine.player.moves == 0)
    }

    @Test("LOAD syntax works with YES confirmation")
    func testLoadSyntaxWithYes() async throws {
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

        try await engine.execute("save")

        // Verify sword is NOT in inventory at save, an zero moves
        #expect(await engine.item("sword").playerIsHolding == false)
        #expect(await engine.player.moves == 0)

        // Take the sword to change game state
        try await engine.execute("take sword")

        // Verify sword is in inventory before restore, and one move
        #expect(await engine.item("sword").playerIsHolding == true)
        #expect(await engine.player.moves == 1)

        // Set up mock to respond "y" to restore confirmation
        await mockIO.enqueueInput("y")

        // When: Execute restore command
        try await engine.execute("load")

        // Then
        await mockIO.expectOutput(
            """
            > save
            Game saved.

            > take sword
            Taken.

            > load
            If you restore your saved game now you will lose any unsaved
            progress. Are you sure you want to restore? (Y is affirmative): y
            Game restored.
            """
        )

        // Verify sword is NOT in inventory after restore, and back to zero moves
        #expect(await engine.item("sword").playerIsHolding == false)
        #expect(await engine.player.moves == 0)
    }

    @Test("RESTORE syntax works with NO cancellation")
    func testRestoreSyntaxWithNo() async throws {
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

        // Verify sword is in inventory before restore attempt
        let swordBefore = await engine.item("sword")
        #expect(await swordBefore.playerIsHolding)

        // Set up mock to respond "n" to restore confirmation
        await mockIO.enqueueInput("n")

        // When: Execute restore command
        try await engine.execute("restore")

        // Then
        await mockIO.expectOutput(
            """
            > restore
            If you restore your saved game now you will lose any unsaved
            progress. Are you sure you want to restore? (Y is affirmative): n
            Restore cancelled.
            """
        )

        // Verify game state was not reset
        let swordAfter = await engine.item("sword")
        #expect(await swordAfter.playerIsHolding)
    }

    @Test("RESTORE handles invalid responses")
    func testRestoreHandlesInvalidResponses() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up mock to respond with invalid then valid response
        await mockIO.enqueueInput("maybe", "no")

        // When: Execute restore command
        try await engine.execute("restore")

        // Then
        await mockIO.expectOutput(
            """
            > restore
            If you restore your saved game now you will lose any unsaved
            progress. Are you sure you want to restore? (Y is affirmative): maybe
            Your response defies binary interpretation. I'll take that as a
            'no'.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("RESTORE requires no validation")
    func testRestoreRequiresNoValidation() async throws {
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

        // Set up mock to respond "n" to restore confirmation
        await mockIO.enqueueInput("n")

        // When: RESTORE should work even in darkness
        try await engine.execute("restore")

        // Then: Should succeed even without light
        await mockIO.expectOutput(
            """
            > restore
            If you restore your saved game now you will lose any unsaved
            progress. Are you sure you want to restore? (Y is affirmative): n
            Restore cancelled.
            """
        )
    }

    // MARK: - Handler Properties Testing

    @Test("Handler does not require light")
    func testRequiresLightProperty() async throws {
        let handler = RestoreActionHandler()
        #expect(handler.requiresLight == false)
    }

    @Test("Handler uses correct syntax rules")
    func testSyntaxRules() async throws {
        let handler = RestoreActionHandler()
        #expect(handler.syntax.count == 1)
        #expect(handler.synonyms.contains(.restore))
    }
}
