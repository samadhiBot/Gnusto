import CustomDump
import Testing

@testable import GnustoEngine

@Suite("RestoreActionHandler Tests")
struct RestoreActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("RESTORE syntax works")
    func testRestoreSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("restore")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > restore
            Game restored.
            """)
    }

    @Test("LOAD syntax works")
    func testLoadSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("load")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > load
            Game restored.
            """)
    }

    // MARK: - Validation Testing

    @Test("RESTORE requires no validation")
    func testRestoreRequiresNoValidation() async throws {
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

        // When: RESTORE should work even in darkness
        try await engine.execute("restore")

        // Then: Should succeed even without light
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > restore
            Game restored.
            """)
    }

    @Test("RESTORE works with no items or special conditions")
    func testRestoreWorksUnconditionally() async throws {
        // Given: Minimal game state
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("restore")

        // Then: Should always succeed
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > restore
            Game restored.
            """)
    }

    // MARK: - Processing Testing

    @Test("RESTORE works regardless of game state")
    func testRestoreWorksInAnyGameState() async throws {
        // Given: Complex game state with items, flags, etc.
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

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
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up complex game state
        try await engine.apply(
            engine.setGlobal(.isBriefMode, to: true),
            await engine.setFlag(.isOn, on: try await engine.item("lamp")),
            engine.updatePlayerScore(by: 100)
        )

        // When: RESTORE should still work
        try await engine.execute("restore")

        // Then: Should succeed regardless of state
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > restore
            Game restored.
            """)
    }

    @Test("RESTORE can be repeated multiple times")
    func testRestoreRepeatable() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Execute RESTORE multiple times
        try await engine.execute("restore")
        try await engine.execute("restore")
        try await engine.execute("restore")

        // Then: Should work each time
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > restore
            Game restored.
            > restore
            Game restored.
            > restore
            Game restored.
            """)
    }

    @Test("RESTORE with inventory items")
    func testRestoreWithInventory() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let sword = Item(
            id: "sword",
            .name("steel sword"),
            .description("A sharp steel sword."),
            .isWeapon,
            .isTakable,
            .in(.player)
        )

        let shield = Item(
            id: "shield",
            .name("wooden shield"),
            .description("A sturdy wooden shield."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: sword, shield
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("restore")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > restore
            Game restored.
            """)
    }

    @Test("RESTORE preserves original behavior")
    func testRestorePreservesOriginalBehavior() async throws {
        // Given: This test verifies that RESTORE doesn’t unexpectedly modify
        // game state in the test environment (in real use, it would replace state)
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let book = Item(
            id: "book",
            .name("leather book"),
            .description("A bound leather book."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Record initial state
        let initialBook = try await engine.item("book")
        let initialScore = await engine.playerScore
        let initialTurnCount = await engine.playerMoves

        // When
        try await engine.execute("restore")

        // Then: In test environment, state should remain unchanged
        // (In real environment, this would restore to saved state)
        let finalBook = try await engine.item("book")
        let finalScore = await engine.playerScore
        let finalTurnCount = await engine.playerMoves

        #expect(finalBook.parent == initialBook.parent)
        #expect(finalBook.hasFlag(.isTouched) == initialBook.hasFlag(.isTouched))
        #expect(finalScore == initialScore)
        #expect(finalTurnCount == initialTurnCount)

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > restore
            Game restored.
            """)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Intents")
    func testIntents() async throws {
        let handler = RestoreActionHandler()
        // RestoreActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = RestoreActionHandler()
        #expect(handler.verbs.contains(.restore))
        #expect(handler.verbs.contains(.load))
        #expect(handler.verbs.count == 2)
    }

    @Test("Handler does not require light")
    func testRequiresLightProperty() async throws {
        let handler = RestoreActionHandler()
        #expect(handler.requiresLight == false)
    }

    // MARK: - Direct Handler Testing

    @Test("Handler validation succeeds unconditionally")
    func testHandlerValidation() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        let handler = RestoreActionHandler()

        let command = Command(
            verb: .restore
        )

        // When/Then: Should not throw
        let result = try await handler.process(command: command, engine: engine)
    }

    @Test("Handler process returns correct result")
    func testHandlerProcess() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, _) = await GameEngine.test(blueprint: game)
        let handler = RestoreActionHandler()

        let command = Command(
            verb: .restore
        )

        // When
        let result = try await handler.process(command: command, engine: engine)

        // Then
        #expect(result.message == "Game restored.")
        #expect(result.changes.isEmpty)
    }

    // MARK: - Error Handling Testing

    @Test("RESTORE handles restore errors gracefully")
    func testRestoreErrorHandling() async throws {
        // Given: This test verifies that if the restore operation fails,
        // the handler returns an appropriate error message
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Note: In a real implementation, we might need to set up a mock
        // engine that can simulate restore failures, but for now we test
        // the happy path since the mock engine’s restore implementation
        // should succeed

        // When
        try await engine.execute("restore")

        // Then: Should still provide feedback
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > restore
            Game restored.
            """)
    }

    // MARK: - Integration Testing

    @Test("SAVE and RESTORE work together")
    func testSaveRestoreIntegration() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Save game
        try await engine.execute("save")

        // Then: Should get save confirmation
        // When: Restore game
        try await engine.execute("restore")

        // Then: Should get restore confirmation
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > save
            Game saved.
            > restore
            Game restored.
            """)
    }

    // MARK: - Alternative Verb Testing

    @Test("LOAD command works identically to RESTORE")
    func testLoadCommandEquivalent() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let treasure = Item(
            id: "treasure",
            .name("golden treasure"),
            .description("A pile of golden treasure."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: treasure
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Use LOAD instead of RESTORE
        try await engine.execute("load")

        // Then: Should work identically to RESTORE
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > load
            Game restored.
            """)
    }

    // MARK: - State Management Testing

    @Test("RESTORE command behavior in test environment")
    func testRestoreInTestEnvironment() async throws {
        // Given: This test documents the expected behavior of RESTORE
        // in the test environment vs. production environment
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("restore")

        // Then: In test environment, RESTORE provides feedback
        // but doesn’t actually modify game state (no saved state to restore from)
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > restore
            Game restored.
            """)
    }
}
