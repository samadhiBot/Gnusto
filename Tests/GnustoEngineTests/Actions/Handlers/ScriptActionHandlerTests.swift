import CustomDump
import Testing

@testable import GnustoEngine

@Suite("ScriptActionHandler Tests")
struct ScriptActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("SCRIPT syntax works")
    func testScriptSyntax() async throws {
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
        try await engine.execute("script")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > script
            🤡 Enter a file name.
            Default is "transcript":
            [Transcript recording started]
            """)
    }

    // MARK: - Validation Testing

    @Test("SCRIPT requires no light")
    func testScriptRequiresNoLight() async throws {
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

        // When: SCRIPT should work even in darkness
        try await engine.execute("script")

        // Then: Should succeed even without light
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > script
            🤡 Enter a file name.
            Default is "transcript":
            [Transcript recording started]
            """)
    }

    @Test("Cannot start script when already scripting")
    func testCannotStartScriptWhenAlreadyScripting() async throws {
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

        // Set up: scripting is already active
        try await engine.apply(
            engine.setGlobal(.isScripting, to: true)
        )

        // When
        try await engine.execute("script")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > script
            Scripting is already on.
            """)
    }

    @Test("SCRIPT works with no items or special conditions")
    func testScriptWorksUnconditionally() async throws {
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
        try await engine.execute("script")

        // Then: Should always succeed when not already scripting
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > script
            🤡 Enter a file name.
            Default is "transcript":
            [Transcript recording started]
            """)
    }

    // MARK: - Processing Testing

    @Test("SCRIPT command sets scripting flag")
    func testScriptSetsFlag() async throws {
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
        try await engine.execute("script")

        // Then: Verify the scripting flag was set
        let isScripting = await engine.hasGlobal(.isScripting)
        #expect(isScripting == true)

        // Also verify the message
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > script
            🤡 Enter a file name.
            Default is "transcript":
            [Transcript recording started]
            """)
    }

    @Test("SCRIPT works regardless of game state")
    func testScriptWorksInAnyGameState() async throws {
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

        // When: SCRIPT should still work
        try await engine.execute("script")

        // Then: Should succeed regardless of state
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > script
            🤡 Enter a file name.
            Default is "transcript":
            [Transcript recording started]
            """)

        let isScripting = await engine.hasGlobal(.isScripting)
        #expect(isScripting == true)
    }

    @Test("SCRIPT preserves other game state")
    func testScriptPreservesGameState() async throws {
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
        try await engine.execute("script")

        // Then: Game state should remain unchanged (except for scripting flag)
        let finalBook = try await engine.item("book")
        let finalScore = await engine.playerScore
        let finalTurnCount = await engine.playerMoves

        #expect(finalBook.parent == initialBook.parent)
        #expect(finalBook.hasFlag(.isTouched) == initialBook.hasFlag(.isTouched))
        #expect(finalScore == initialScore)
        #expect(finalTurnCount == initialTurnCount)

        // But scripting flag should be set
        let isScripting = await engine.hasGlobal(.isScripting)
        #expect(isScripting == true)

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > script
            🤡 Enter a file name.
            Default is "transcript":
            [Transcript recording started]
            """)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Intents")
    func testIntents() async throws {
        let handler = ScriptActionHandler()
        // ScriptActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = ScriptActionHandler()
        #expect(handler.verbs.contains(.script))
        #expect(handler.verbs.count == 1)
    }

    @Test("Handler does not require light")
    func testRequiresLightProperty() async throws {
        let handler = ScriptActionHandler()
        #expect(handler.requiresLight == false)
    }

    // MARK: - Direct Handler Testing

    @Test("Handler validation succeeds when not scripting")
    func testHandlerValidationSuccess() async throws {
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
        let handler = ScriptActionHandler()

        let command = Command(
            verb: .script,
            rawInput: "script"
        )

        // When/Then: Should not throw
        let result = try await handler.process(command: command, engine: engine)
    }

    @Test("Handler validation fails when already scripting")
    func testHandlerValidationFailsWhenScripting() async throws {
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
        let handler = ScriptActionHandler()

        // Set up: scripting is already active
        try await engine.apply(
            engine.setGlobal(.isScripting, to: true)
        )

        let command = Command(
            verb: .script,
            rawInput: "script"
        )

        // When/Then: Should throw
        await #expect(throws: ActionResponse.self) {
            let result = try await handler.process(command: command, engine: engine)
        }
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
        let handler = ScriptActionHandler()

        let command = Command(
            verb: .script,
            rawInput: "script"
        )

        // When
        let result = try await handler.process(command: command, engine: engine)

        // Then
        expectNoDifference(result.message, "")
//        #expect(result.message.contains("Enter a file name"))
//        #expect(result.message.contains("[Transcript recording started]"))
        #expect(result.changes.count == 1)
    }

    // MARK: - Integration Testing

    @Test("SCRIPT and UNSCRIPT work together")
    func testScriptUnscriptIntegration() async throws {
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

        // When: Start scripting
        try await engine.execute("script")

        // Then: Scripting should be active
        let isScriptingAfterStart = await engine.hasGlobal(.isScripting)
        #expect(isScriptingAfterStart == true)

        // When: Stop scripting
        try await engine.execute("unscript")

        // Then: Scripting should be inactive
        let isScriptingAfterStop = await engine.hasGlobal(.isScripting)
        #expect(isScriptingAfterStop == false)

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > script
            🤡 Enter a file name.
            Default is "transcript":
            [Transcript recording started]
            > unscript
            [Transcript recording ended]
            """)
    }

    // MARK: - State Management Testing

    @Test("SCRIPT command correctly modifies global state")
    func testScriptModifiesGlobalState() async throws {
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

        // Verify initial state
        let initialScripting = await engine.hasGlobal(.isScripting)
        #expect(initialScripting == false)

        // When
        try await engine.execute("script")

        // Then: Global state should be modified
        let finalScripting = await engine.hasGlobal(.isScripting)
        #expect(finalScripting == true)

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > script
            🤡 Enter a file name.
            Default is "transcript":
            [Transcript recording started]
            """)
    }
}
