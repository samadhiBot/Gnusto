import CustomDump
import Testing

@testable import GnustoEngine

@Suite("RestartActionHandler Tests")
struct RestartActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("RESTART syntax works")
    func testRestartSyntax() async throws {
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
        try await engine.execute("restart")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > restart
            Are you sure you want to restart? This will lose your current progress.
            [Game will restart...]
            """)
    }

    // MARK: - Validation Testing

    @Test("RESTART requires no validation")
    func testRestartRequiresNoValidation() async throws {
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

        // When: RESTART should work even in darkness
        try await engine.execute("restart")

        // Then: Should succeed even without light
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > restart
            Are you sure you want to restart? This will lose your current progress.
            [Game will restart...]
            """)
    }

    @Test("RESTART works with no items or special conditions")
    func testRestartWorksUnconditionally() async throws {
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
        try await engine.execute("restart")

        // Then: Should always succeed
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > restart
            Are you sure you want to restart? This will lose your current progress.
            [Game will restart...]
            """)
    }

    // MARK: - Processing Testing

    @Test("RESTART command requests quit from engine")
    func testRestartRequestsQuit() async throws {
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
        try await engine.execute("restart")

        // Then: Verify the engine was asked to quit
        let shouldQuit = await engine.shouldQuit
        #expect(shouldQuit == true)

        // Also verify the message
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > restart
            Are you sure you want to restart? This will lose your current progress.
            [Game will restart...]
            """)
    }

    @Test("RESTART works regardless of game state")
    func testRestartWorksInAnyGameState() async throws {
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

        // When: RESTART should still work
        try await engine.execute("restart")

        // Then: Should succeed regardless of state
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > restart
            Are you sure you want to restart? This will lose your current progress.
            [Game will restart...]
            """)

        let shouldQuit = await engine.shouldQuit
        #expect(shouldQuit == true)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = RestartActionHandler()
        // RestartActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = RestartActionHandler()
        #expect(handler.verbs.contains(.restart))
        #expect(handler.verbs.count == 1)
    }

    @Test("Handler does not require light")
    func testRequiresLightProperty() async throws {
        let handler = RestartActionHandler()
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
        let handler = RestartActionHandler()

        let command = Command(
            verb: .restart,
            rawInput: "restart"
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
        let handler = RestartActionHandler()

        let command = Command(
            verb: .restart,
            rawInput: "restart"
        )

        // When
        let result = try await handler.process(command: command, engine: engine)

        // Then
        #expect(result.message?.contains("Are you sure you want to restart?") == true)
        #expect(result.message?.contains("[Game will restart...]") == true)

        // Verify engine was asked to quit
        let shouldQuit = await engine.shouldQuit
        #expect(shouldQuit == true)
    }
}
