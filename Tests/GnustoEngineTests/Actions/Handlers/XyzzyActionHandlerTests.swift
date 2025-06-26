import CustomDump
import Testing

@testable import GnustoEngine

@Suite("XyzzyActionHandler Tests")
struct XyzzyActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("XYZZY syntax works")
    func testXyzzySyntax() async throws {
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
        try await engine.execute("xyzzy")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > xyzzy
            Nothing happens.
            """)
    }

    // MARK: - Validation Testing

    @Test("XYZZY requires no validation")
    func testXyzzyRequiresNoValidation() async throws {
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

        // When: XYZZY should work even in darkness
        try await engine.execute("xyzzy")

        // Then: Should succeed even without light
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > xyzzy
            Nothing happens.
            """)
    }

    @Test("XYZZY works with no items or special conditions")
    func testXyzzyWorksUnconditionally() async throws {
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
        try await engine.execute("xyzzy")

        // Then: Should always succeed
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > xyzzy
            Nothing happens.
            """)
    }

    @Test("XYZZY works in any game state")
    func testXyzzyWorksInAnyGameState() async throws {
        // Given: Complex game state
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

        // Set up complex game state
        try await engine.apply(
            engine.setGlobal(.isBriefMode, to: true),
            engine.updatePlayerScore(by: 42)
        )

        // When: XYZZY should still work
        try await engine.execute("xyzzy")

        // Then: Should succeed regardless of state
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > xyzzy
            Nothing happens.
            """)
    }

    // MARK: - Processing Testing

    @Test("XYZZY produces classic easter egg response")
    func testXyzzyEasterEggResponse() async throws {
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

        // When
        try await engine.execute("xyzzy")

        // Then: Should produce the classic response
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > xyzzy
            Nothing happens.
            """)
    }

    @Test("XYZZY can be repeated multiple times")
    func testXyzzyRepeatable() async throws {
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

        // When: Execute XYZZY multiple times
        try await engine.execute("xyzzy")
        try await engine.execute("xyzzy")
        try await engine.execute("xyzzy")

        // Then: Should work each time
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > xyzzy
            Nothing happens.
            > xyzzy
            Nothing happens.
            > xyzzy
            Nothing happens.
            """)
    }

    @Test("XYZZY doesn’t modify game state")
    func testXyzzyNoStateChanges() async throws {
        // Given
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

        // Record initial state
        let initialLamp = try await engine.item("lamp")
        let initialScore = await engine.playerScore
        let initialTurnCount = await engine.playerMoves

        // When
        try await engine.execute("xyzzy")

        // Then: State should be unchanged
        let finalLamp = try await engine.item("lamp")
        let finalScore = await engine.playerScore
        let finalTurnCount = await engine.playerMoves

        #expect(finalLamp.parent == initialLamp.parent)
        #expect(finalLamp.hasFlag(.isTouched) == initialLamp.hasFlag(.isTouched))
        #expect(finalScore == initialScore)
        #expect(finalTurnCount == initialTurnCount)

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > xyzzy
            Nothing happens.
            """)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Intents")
    func testIntents() async throws {
        let handler = XyzzyActionHandler()
        // XyzzyActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = XyzzyActionHandler()
        #expect(handler.verbs.contains(.xyzzy))
        #expect(handler.verbs.count == 1)
    }

    @Test("Handler does not require light")
    func testRequiresLightProperty() async throws {
        let handler = XyzzyActionHandler()
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
        let handler = XyzzyActionHandler()

        let command = Command(
            verb: .xyzzy,
            rawInput: "xyzzy"
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

        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        let handler = XyzzyActionHandler()

        let command = Command(
            verb: .xyzzy,
            rawInput: "xyzzy"
        )

        // When
        let result = try await handler.process(command: command, engine: engine)

        // Then
        #expect(result.message == "Nothing happens.")
        #expect(result.changes.isEmpty)
    }

    // MARK: - Easter Egg Behavior Testing

    @Test("XYZZY maintains classic adventure game tradition")
    func testClassicTradition() async throws {
        // Given: This test verifies that XYZZY maintains its role as a classic
        // adventure game easter egg that does nothing but acknowledge the command
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
        try await engine.execute("xyzzy")

        // Then: Should maintain the classic "Nothing happens" response
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > xyzzy
            Nothing happens.
            """)
    }
}
