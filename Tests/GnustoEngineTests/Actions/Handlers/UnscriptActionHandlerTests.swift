import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("UnscriptActionHandler Tests")
struct UnscriptActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("UNSCRIPT syntax works")
    func testUnscriptSyntax() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up: scripting is active
        try await engine.apply(
            engine.setFlag(.isScripting)
        )

        // When
        try await engine.execute("unscript")

        // Then
        let output = await mockIO.flush()
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

    // MARK: - Validation Testing

    @Test("UNSCRIPT requires no light")
    func testUnscriptRequiresNoLight() async throws {
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

        // Set up: scripting is active
        try await engine.apply(
            engine.setFlag(.isScripting)
        )

        // When: UNSCRIPT should work even in darkness
        try await engine.execute("unscript")

        // Then: Should succeed even without light
        let output = await mockIO.flush()
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

    @Test("Cannot stop script when not scripting")
    func testCannotStopScriptWhenNotScripting() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Note: scripting is not active (default state)

        // When
        try await engine.execute("unscript")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > unscript
            Scripting is not currently on.
            """
        )
    }

    @Test("UNSCRIPT works with complex game state")
    func testUnscriptWorksWithComplexState() async throws {
        // Given: Complex game state
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

        // Set up complex game state including scripting
        try await engine.apply(
            engine.setFlag(.isScripting),
            await lamp.proxy(engine).setFlag(.isOn),
            engine.player.updateScore(by: 100)
        )

        // When
        try await engine.execute("unscript")

        // Then: Should succeed regardless of other state
        let output = await mockIO.flush()
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

    // MARK: - Processing Testing

    @Test("UNSCRIPT command clears scripting flag")
    func testUnscriptClearsFlag() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up: scripting is active
        try await engine.apply(
            engine.setFlag(.isScripting)
        )

        // Verify initial state
        let initialScripting = await engine.hasFlag(.isScripting)
        #expect(initialScripting == true)

        // When
        try await engine.execute("unscript")

        // Then: Verify the scripting flag was cleared
        let isScripting = await engine.hasFlag(.isScripting)
        #expect(isScripting == false)

        // Also verify the message
        let output = await mockIO.flush()
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

    @Test("UNSCRIPT preserves other game state")
    func testUnscriptPreservesGameState() async throws {
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

        // Set up initial state including scripting
        try await engine.apply(
            engine.setFlag(.isScripting),
            engine.player.updateScore(by: 50)
        )

        // Record initial state
        let initialBook = await engine.item("book")
        let initialScore = await engine.player.score
        let initialTurnCount = await engine.player.moves

        // When
        try await engine.execute("unscript")

        // Then: Game state should remain unchanged (except for scripting flag)
        let finalBook = await engine.item("book")
        let finalScore = await engine.player.score
        let finalTurnCount = await engine.player.moves

        #expect(await finalBook.parent == initialBook.parent)
        #expect(await finalBook.hasFlag(.isTouched) == initialBook.hasFlag(.isTouched))
        #expect(finalScore == initialScore)
        #expect(finalTurnCount == initialTurnCount)

        // But scripting flag should be cleared
        let isScripting = await engine.hasFlag(.isScripting)
        #expect(isScripting == false)

        let output = await mockIO.flush()
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

    @Test("UNSCRIPT can be called after SCRIPT")
    func testUnscriptAfterScript() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Start scripting first
        try await engine.execute("script")

        // Verify scripting is active
        let isScriptingAfterStart = await engine.hasFlag(.isScripting)
        #expect(isScriptingAfterStart == true)

        try await engine.execute("look")

        // When: Stop scripting
        try await engine.execute("unscript")

        // Then: Scripting should be stopped
        let isScriptingAfterStop = await engine.hasFlag(.isScripting)
        #expect(isScriptingAfterStop == false)

        let output = await mockIO.flush()
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

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = UnscriptActionHandler()
        // UnscriptActionHandler uses .unscript in its syntax but doesn't expose verbs
        #expect(handler.synonyms.isEmpty)
    }

    @Test("Handler does not require light")
    func testRequiresLightProperty() async throws {
        let handler = UnscriptActionHandler()
        #expect(handler.requiresLight == false)
    }

    // MARK: - Direct Handler Testing

    @Test("Handler properties are correct")
    func testHandlerProperties() async throws {
        let handler = UnscriptActionHandler()
        #expect(handler.requiresLight == false)
        #expect(handler.synonyms.isEmpty)
    }

    // MARK: - Integration Testing

    @Test("SCRIPT and UNSCRIPT work together multiple times")
    func testScriptUnscriptCycle() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Start scripting
        try await engine.execute("script")
        let isScriptingAfterStart1 = await engine.hasFlag(.isScripting)
        #expect(isScriptingAfterStart1 == true)

        // Then: Stop scripting
        try await engine.execute("unscript")
        let isScriptingAfterStop1 = await engine.hasFlag(.isScripting)
        #expect(isScriptingAfterStop1 == false)

        // When: Start scripting again
        try await engine.execute("script")
        let isScriptingAfterStart2 = await engine.hasFlag(.isScripting)
        #expect(isScriptingAfterStart2 == true)

        // Then: Stop scripting again
        try await engine.execute("unscript")
        let isScriptingAfterStop2 = await engine.hasFlag(.isScripting)
        #expect(isScriptingAfterStop2 == false)

        let output = await mockIO.flush()
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

    @Test("UNSCRIPT command correctly modifies global state")
    func testUnscriptModifiesGlobalState() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up: scripting is active
        try await engine.apply(
            engine.setFlag(.isScripting)
        )

        // Verify initial state
        let initialScripting = await engine.hasFlag(.isScripting)
        #expect(initialScripting == true)

        // When
        try await engine.execute("unscript")

        // Then: Global state should be modified
        let finalScripting = await engine.hasFlag(.isScripting)
        #expect(finalScripting == false)

        let output = await mockIO.flush()
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

    // MARK: - Error Cases Testing

    @Test("Multiple UNSCRIPT calls when not scripting")
    func testMultipleUnscriptWhenNotScripting() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Note: scripting is not active (default state)

        // When: Try UNSCRIPT multiple times
        try await engine.execute(
            "unscript",
            "unscript"
        )

        // Then: Should fail each time
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > unscript
            Scripting is not currently on.

            > unscript
            Scripting is not currently on.
            """
        )
    }

    @Test("UNSCRIPT with other game activities")
    func testUnscriptWithOtherActivities() async throws {
        // Given
        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .description("A shiny gold coin."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: coin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up: scripting is active
        try await engine.apply(
            engine.setFlag(.isScripting)
        )

        // When: Perform other actions and then unscript
        try await engine.execute("take coin")
        try await engine.execute("inventory")
        try await engine.execute("unscript")

        // Then: UNSCRIPT should work normally
        let isScripting = await engine.hasFlag(.isScripting)
        #expect(isScripting == false)

        let output = await mockIO.flush()
        #expect(
            output.contains(
                """
                > take coin
                Taken.

                > inventory
                You are carrying:
                - A gold coin

                > unscript
                Transcript recording ended at
                '~/Gnusto/MinimalGame/transcript-
                """
            )
        )
    }
}
