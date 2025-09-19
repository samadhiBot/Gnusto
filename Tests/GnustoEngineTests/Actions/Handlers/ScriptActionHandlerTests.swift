import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("ScriptActionHandler Tests")
struct ScriptActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("SCRIPT syntax works")
    func testScriptSyntax() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("script")

        // Then
        let output = await mockIO.flush()
        #expect(
            output.contains(
                """
                > script
                Transcript recording started at
                '~/Gnusto/MinimalGame/transcript-
                """
            )
        )

        let path = await mockIO.transcriptRecorder?.transcriptURL.gnustoPath ?? ""
        let pathRegex = /~\/Gnusto\/MinimalGame\/transcript-\d{4}\.\d{2}\.\d{2}-\d{2}\.\d{2}\.md/
        #expect(path.wholeMatch(of: pathRegex) != nil)
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
        #expect(
            output.contains(
                """
                > script
                Transcript recording started at
                '~/Gnusto/MinimalGame/transcript-
                """
            )
        )
    }

    @Test("Cannot start script when already scripting")
    func testCannotStartScriptWhenAlreadyScripting() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up: scripting is already active
        try await engine.apply(
            engine.setGlobal(.isScripting, to: true)
        )

        // When
        try await engine.execute("script")

        // Then
        let output = await mockIO.flush()
        #expect(
            output.contains(
                """
                > script
                Transcript recording is already active at
                '~/Gnusto/MinimalGame/transcript-
                """
            )
        )
    }

    @Test("SCRIPT works with no items or special conditions")
    func testScriptWorksUnconditionally() async throws {
        // Given: Minimal game state
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("script")

        // Then: Should always succeed when not already scripting
        let output = await mockIO.flush()
        #expect(
            output.contains(
                """
                > script
                Transcript recording started at
                '~/Gnusto/MinimalGame/transcript-
                """
            )
        )
    }

    // MARK: - Processing Testing

    @Test("SCRIPT command sets scripting flag")
    func testScriptSetsFlag() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("script")

        // Then: Verify the scripting flag was set
        let isScripting = await engine.hasFlag(.isScripting)
        #expect(isScripting == true)

        // Also verify the message
        let output = await mockIO.flush()
        #expect(
            output.contains(
                """
                > script
                Transcript recording started at
                '~/Gnusto/MinimalGame/transcript-
                """
            )
        )
    }

    @Test("SCRIPT works regardless of game state")
    func testScriptWorksInAnyGameState() async throws {
        // Given: Complex game state with items, flags, etc.
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

        // Set up complex game state
        try await engine.apply(
            lamp.proxy(engine).setFlag(.isOn),
            engine.player.updateScore(by: 100)
        )

        // When: SCRIPT should still work
        try await engine.execute("script")

        // Then: Should succeed regardless of state
        let output = await mockIO.flush()
        #expect(
            output.contains(
                """
                > script
                Transcript recording started at
                '~/Gnusto/MinimalGame/transcript-
                """
            )
        )

        let isScripting = await engine.hasFlag(.isScripting)
        #expect(isScripting == true)
    }

    @Test("SCRIPT preserves other game state")
    func testScriptPreservesGameState() async throws {
        // Given
        let book = Item(
            id: "book",
            .name("leather book"),
            .description("A bound leather book."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Record initial state
        let initialBook = await engine.item("book")
        let initialScore = await engine.player.score
        let initialTurnCount = await engine.player.moves

        // When
        try await engine.execute("script")

        // Then: Game state should remain unchanged (except for scripting flag)
        let finalBook = await engine.item("book")
        let finalScore = await engine.player.score
        let finalTurnCount = await engine.player.moves

        #expect(await finalBook.parent == initialBook.parent)
        #expect(await finalBook.hasFlag(.isTouched) == initialBook.hasFlag(.isTouched))
        #expect(finalScore == initialScore)
        #expect(finalTurnCount == initialTurnCount)

        // But scripting flag should be set
        let isScripting = await engine.hasFlag(.isScripting)
        #expect(isScripting == true)

        let output = await mockIO.flush()
        #expect(
            output.contains(
                """
                > script
                Transcript recording started at
                '~/Gnusto/MinimalGame/transcript-
                """
            )
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = ScriptActionHandler()
        #expect(handler.synonyms.contains(.script))
        #expect(handler.synonyms.count == 1)
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
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)
        let handler = ScriptActionHandler()

        let command = Command(
            verb: .script
        )

        // When/Then: Should not throw
        _ = try await handler.process(context: ActionContext(command, engine))
    }

    @Test("Handler validation fails when already scripting")
    func testHandlerValidationFailsWhenScripting() async throws {
        // Given
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)
        let handler = ScriptActionHandler()

        // Set up: scripting is already active
        try await engine.apply(
            engine.setGlobal(.isScripting, to: true)
        )

        let command = Command(
            verb: .script
        )

        // When/Then: Should throw
        await #expect(throws: ActionResponse.self) {
            _ = try await handler.process(context: ActionContext(command, engine))
        }
    }

    @Test("Handler process returns correct result")
    func testHandlerProcess() async throws {
        // Given
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)
        let handler = ScriptActionHandler()

        let command = Command(
            verb: .script
        )

        // When
        let result = try await handler.process(context: ActionContext(command, engine))

        // Then
        #expect(
            result.message!.contains(
                "Transcript recording started at '~/Gnusto/MinimalGame/transcript-"
            )
        )
        #expect(result.changes.count == 1)
    }

    // MARK: - Integration Testing

    @Test("SCRIPT and UNSCRIPT work together")
    func testScriptUnscriptIntegration() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Start scripting
        try await engine.execute("script")

        // Then: Scripting should be active
        let isScriptingAfterStart = await engine.hasFlag(.isScripting)
        #expect(isScriptingAfterStart == true)

        try await engine.execute("wait")

        // When: Stop scripting
        try await engine.execute("unscript")

        // Then: Scripting should be inactive
        let isScriptingAfterStop = await engine.hasFlag(.isScripting)
        #expect(isScriptingAfterStop == false)

        let output = await mockIO.flush()
        #expect(
            output.contains(
                """
                > script
                Transcript recording started at
                '~/Gnusto/MinimalGame/transcript-
                """
            )
        )
        #expect(
            output.contains(
                """
                > wait
                Time flows onward, indifferent to your concerns.
                """
            )
        )
        #expect(
            output.contains(
                """
                > unscript
                Transcript recording ended at
                '~/Gnusto/MinimalGame/transcript-
                """
            )
        )
    }

    // MARK: - State Management Testing

    @Test("SCRIPT command correctly modifies global state")
    func testScriptModifiesGlobalState() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Verify initial state
        let initialScripting = await engine.hasFlag(.isScripting)
        #expect(initialScripting == false)

        // When
        try await engine.execute("script")

        // Then: Global state should be modified
        let finalScripting = await engine.hasFlag(.isScripting)
        #expect(finalScripting == true)

        let output = await mockIO.flush()
        #expect(
            output.contains(
                """
                > script
                Transcript recording started at
                '~/Gnusto/MinimalGame/transcript-
                """
            )
        )
    }
}
