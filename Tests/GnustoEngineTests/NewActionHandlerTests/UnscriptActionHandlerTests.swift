import CustomDump
import Testing

@testable import GnustoEngine

@Suite("UnscriptActionHandler Tests")
struct UnscriptActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("UNSCRIPT syntax works")
    func testUnscriptSyntax() async throws {
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

        // Set up: scripting is active
        try await engine.apply(
            engine.setGlobal(.isScripting, to: true)
        )

        // When
        try await engine.execute("unscript")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > unscript
            🤡 [Transcript recording ended]
            """)
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
            engine.setGlobal(.isScripting, to: true)
        )

        // When: UNSCRIPT should work even in darkness
        try await engine.execute("unscript")

        // Then: Should succeed even without light
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > unscript
            🤡 [Transcript recording ended]
            """)
    }

    @Test("Cannot stop script when not scripting")
    func testCannotStopScriptWhenNotScripting() async throws {
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
            """)
    }

    @Test("UNSCRIPT works with complex game state")
    func testUnscriptWorksWithComplexState() async throws {
        // Given: Complex game state
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

        // Set up complex game state including scripting
        try await engine.apply(
            engine.setGlobal(.isBriefMode, to: true),
            engine.setGlobal(.isScripting, to: true),
            await engine.setFlag(.isOn, on: try await engine.item("lamp")),
            engine.updatePlayerScore(by: 100)
        )

        // When
        try await engine.execute("unscript")

        // Then: Should succeed regardless of other state
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > unscript
            🤡 [Transcript recording ended]
            """)
    }

    // MARK: - Processing Testing

    @Test("UNSCRIPT command clears scripting flag")
    func testUnscriptClearsFlag() async throws {
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

        // Set up: scripting is active
        try await engine.apply(
            engine.setGlobal(.isScripting, to: true)
        )

        // Verify initial state
        let initialScripting = await engine.hasGlobal(.isScripting)
        #expect(initialScripting == true)

        // When
        try await engine.execute("unscript")

        // Then: Verify the scripting flag was cleared
        let isScripting = await engine.hasGlobal(.isScripting)
        #expect(isScripting == false)

        // Also verify the message
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > unscript
            🤡 [Transcript recording ended]
            """)
    }

    @Test("UNSCRIPT preserves other game state")
    func testUnscriptPreservesGameState() async throws {
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

        // Set up initial state including scripting
        try await engine.apply(
            engine.setGlobal(.isScripting, to: true),
            engine.updatePlayerScore(by: 50)
        )

        // Record initial state
        let initialBook = try await engine.item("book")
        let initialScore = await engine.playerScore
        let initialTurnCount = await engine.playerMoves

        // When
        try await engine.execute("unscript")

        // Then: Game state should remain unchanged (except for scripting flag)
        let finalBook = try await engine.item("book")
        let finalScore = await engine.playerScore
        let finalTurnCount = await engine.playerMoves

        #expect(finalBook.parent == initialBook.parent)
        #expect(finalBook.hasFlag(.isTouched) == initialBook.hasFlag(.isTouched))
        #expect(finalScore == initialScore)
        #expect(finalTurnCount == initialTurnCount)

        // But scripting flag should be cleared
        let isScripting = await engine.hasGlobal(.isScripting)
        #expect(isScripting == false)

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > unscript
            🤡 [Transcript recording ended]
            """)
    }

    @Test("UNSCRIPT can be called after SCRIPT")
    func testUnscriptAfterScript() async throws {
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

        // When: Start scripting first
        try await engine.execute("script")

        // Verify scripting is active
        let isScriptingAfterStart = await engine.hasGlobal(.isScripting)
        #expect(isScriptingAfterStart == true)

        // When: Stop scripting
        try await engine.execute("unscript")

        // Then: Scripting should be stopped
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
            🤡 [Transcript recording ended]
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = UnscriptActionHandler()
        // UnscriptActionHandler doesn't specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = UnscriptActionHandler()
        // UnscriptActionHandler uses .unscript in its syntax but doesn't expose verbs
        #expect(handler.verbs.isEmpty)
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
        #expect(handler.actions.isEmpty)
        #expect(handler.verbs.isEmpty)
    }

    // MARK: - Integration Testing

    @Test("SCRIPT and UNSCRIPT work together multiple times")
    func testScriptUnscriptCycle() async throws {
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
        let isScriptingAfterStart1 = await engine.hasGlobal(.isScripting)
        #expect(isScriptingAfterStart1 == true)

        // Then: Stop scripting
        try await engine.execute("unscript")
        let isScriptingAfterStop1 = await engine.hasGlobal(.isScripting)
        #expect(isScriptingAfterStop1 == false)

        // When: Start scripting again
        try await engine.execute("script")
        let isScriptingAfterStart2 = await engine.hasGlobal(.isScripting)
        #expect(isScriptingAfterStart2 == true)

        // Then: Stop scripting again
        try await engine.execute("unscript")
        let isScriptingAfterStop2 = await engine.hasGlobal(.isScripting)
        #expect(isScriptingAfterStop2 == false)

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > script
            🤡 Enter a file name.
            Default is "transcript":
            [Transcript recording started]
            > unscript
            🤡 [Transcript recording ended]
            > script
            🤡 Enter a file name.
            Default is "transcript":
            [Transcript recording started]
            > unscript
            🤡 [Transcript recording ended]
            """)
    }

    // MARK: - State Management Testing

    @Test("UNSCRIPT command correctly modifies global state")
    func testUnscriptModifiesGlobalState() async throws {
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

        // Set up: scripting is active
        try await engine.apply(
            engine.setGlobal(.isScripting, to: true)
        )

        // Verify initial state
        let initialScripting = await engine.hasGlobal(.isScripting)
        #expect(initialScripting == true)

        // When
        try await engine.execute("unscript")

        // Then: Global state should be modified
        let finalScripting = await engine.hasGlobal(.isScripting)
        #expect(finalScripting == false)

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > unscript
            🤡 [Transcript recording ended]
            """)
    }

    // MARK: - Error Cases Testing

    @Test("Multiple UNSCRIPT calls when not scripting")
    func testMultipleUnscriptWhenNotScripting() async throws {
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

        // Note: scripting is not active (default state)

        // When: Try UNSCRIPT multiple times
        try await engine.execute("unscript")
        try await engine.execute("unscript")

        // Then: Should fail each time
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > unscript
            Scripting is not currently on.
            > unscript
            Scripting is not currently on.
            """)
    }

    @Test("UNSCRIPT with other game activities")
    func testUnscriptWithOtherActivities() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .description("A shiny gold coin."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: coin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up: scripting is active
        try await engine.apply(
            engine.setGlobal(.isScripting, to: true)
        )

        // When: Perform other actions and then unscript
        try await engine.execute("take coin")
        try await engine.execute("inventory")
        try await engine.execute("unscript")

        // Then: UNSCRIPT should work normally
        let isScripting = await engine.hasGlobal(.isScripting)
        #expect(isScripting == false)

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take coin
            Taken.
            > inventory
            You are carrying:
              a gold coin
            > unscript
            🤡 [Transcript recording ended]
            """)
    }
}
