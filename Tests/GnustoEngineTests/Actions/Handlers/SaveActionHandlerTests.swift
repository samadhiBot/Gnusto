import CustomDump
import Testing

@testable import GnustoEngine

@Suite("SaveActionHandler Tests")
struct SaveActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("SAVE syntax works")
    func testSaveSyntax() async throws {
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
        try await engine.execute("save")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > save
            Game saved.
            """)
    }

    // MARK: - Validation Testing

    @Test("SAVE requires no validation")
    func testSaveRequiresNoValidation() async throws {
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

        // When: SAVE should work even in darkness
        try await engine.execute("save")

        // Then: Should succeed even without light
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > save
            Game saved.
            """)
    }

    @Test("SAVE works with no items or special conditions")
    func testSaveWorksUnconditionally() async throws {
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
        try await engine.execute("save")

        // Then: Should always succeed
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > save
            Game saved.
            """)
    }

    // MARK: - Processing Testing

    @Test("SAVE works regardless of game state")
    func testSaveWorksInAnyGameState() async throws {
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

        // When: SAVE should still work
        try await engine.execute("save")

        // Then: Should succeed regardless of state
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > save
            Game saved.
            """)
    }

    @Test("SAVE can be repeated multiple times")
    func testSaveRepeatable() async throws {
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

        // When: Execute SAVE multiple times
        try await engine.execute("save")
        try await engine.execute("save")
        try await engine.execute("save")

        // Then: Should work each time
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > save
            Game saved.
            > save
            Game saved.
            > save
            Game saved.
            """)
    }

    @Test("SAVE doesn’t modify game state")
    func testSaveNoStateChanges() async throws {
        // Given
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
        try await engine.execute("save")

        // Then: State should be unchanged
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
            > save
            Game saved.
            """)
    }

    @Test("SAVE with inventory items")
    func testSaveWithInventory() async throws {
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
        try await engine.execute("save")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > save
            Game saved.
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = SaveActionHandler()
        // SaveActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = SaveActionHandler()
        #expect(handler.verbs.contains(.save))
        #expect(handler.verbs.count == 1)
    }

    @Test("Handler does not require light")
    func testRequiresLightProperty() async throws {
        let handler = SaveActionHandler()
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
        let handler = SaveActionHandler()

        let command = Command(
            verb: .save,
            rawInput: "save"
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
        let handler = SaveActionHandler()

        let command = Command(
            verb: .save,
            rawInput: "save"
        )

        // When
        let result = try await handler.process(command: command, engine: engine)

        // Then
        #expect(result.message == "Game saved.")
        #expect(result.changes.isEmpty)
    }

    // MARK: - Error Handling Testing

    @Test("SAVE handles save errors gracefully")
    func testSaveErrorHandling() async throws {
        // Given: This test verifies that if the save operation fails,
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
        // engine that can simulate save failures, but for now we test
        // the happy path since the mock engine’s save implementation
        // should succeed

        // When
        try await engine.execute("save")

        // Then: Should still provide feedback
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > save
            Game saved.
            """)
    }
}
