import CustomDump
import Testing

@testable import GnustoEngine

@Suite("QuitActionHandler Tests")
struct QuitActionHandlerTests {
    @Test("DEBUG: Verify quit handler is available")
    func testQuitHandlerAvailable() async throws {
        // Check if QuitActionHandler is in default handlers
        let defaultHandlers = GameEngine.defaultActionHandlers
        let hasQuitHandler = defaultHandlers[.quit] != nil
        print("Default handlers has quit: \(hasQuitHandler)")
        print("Default handlers count: \(defaultHandlers.count)")
        print("Quit handler type: \(type(of: defaultHandlers[.quit]))")

        #expect(hasQuitHandler, "QuitActionHandler should be in default handlers")
    }

    @Test("DEBUG: Test if other action handlers work")
    func testOtherHandlersWork() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test()

        print("=== Testing inventory command ===")
        try await engine.execute("inventory")
        let inventoryOutput = await mockIO.flush()
        print("Inventory output: '\(inventoryOutput)'")

        print("=== Testing look command ===")
        try await engine.execute("look")
        let lookOutput = await mockIO.flush()
        print("Look output: '\(lookOutput)'")

        print("=== Testing score command ===")
        try await engine.execute("score")
        let scoreOutput = await mockIO.flush()
        print("Score output: '\(scoreOutput)'")

        // Check that these commands produced some output
        #expect(!inventoryOutput.isEmpty, "Inventory should produce output")
        #expect(!lookOutput.isEmpty, "Look should produce output")
        #expect(!scoreOutput.isEmpty, "Score should produce output")
    }

    @Test("QUIT command produces the expected message")
    func testQuitBasicFunctionality() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act: Use engine.execute for full pipeline
        try await engine.execute("quit")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > quit
            Your score is 0 (total of 10 points), in 0 moves. Do you wish
            to leave the game? (Y is affirmative):> 
            Goodbye!
            """)
    }

    @Test("QUIT produces correct ActionResult")
    func testQuitActionResult() async throws {
        let handler = QuitActionHandler()
        let (engine, _) = await GameEngine.test()

        let command = Command(
            verb: .quit,
            rawInput: "quit"
        )
        let context = ActionContext(
            command: command,
            engine: engine
        )

        // Process the command directly
        let result = try await handler.process(context: context)

        // Verify result
        #expect(result.message == "Goodbye!")
        #expect(result.changes.isEmpty) // QUIT should not modify state directly
        #expect(result.effects.isEmpty) // QUIT should not have side effects
    }

    @Test("QUIT validation always succeeds")
    func testQuitValidationSucceeds() async throws {
        let handler = QuitActionHandler()
        let (engine, _) = await GameEngine.test()

        let command = Command(
            verb: .quit,
            rawInput: "quit"
        )
        let context = ActionContext(
            command: command,
            engine: engine
        )

        // Should not throw - QUIT has no validation requirements
        try await handler.validate(context: context)
    }

    @Test("QUIT requests engine to quit")
    func testQuitRequestsEngineQuit() async throws {
        let handler = QuitActionHandler()
        let (engine, _) = await GameEngine.test()

        let command = Command(
            verb: .quit,
            rawInput: "quit"
        )
        let context = ActionContext(
            command: command,
            engine: engine
        )

        // Initially should not be quitting
        #expect(await !engine.shouldQuit)

        // Process QUIT command
        let _ = try await handler.process(context: context)

        // Engine should now be marked to quit
        #expect(await engine.shouldQuit)
    }

    @Test("Q alias works the same as QUIT")
    func testQAliasWorks() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act: Use engine.execute for full pipeline
        try await engine.execute("q")

        // Assert Output - should be the same as QUIT
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > q
            Your score is 0 (total of 10 points), in 0 moves. Do you wish
            to leave the game? (Y is affirmative):> 
            Goodbye!
            """)

        // Should also request quit
        #expect(await engine.shouldQuit)
    }

    @Test("QUIT full workflow integration test")
    func testQuitFullWorkflow() async throws {
        let handler = QuitActionHandler()
        let (engine, _) = await GameEngine.test()

        let command = Command(
            verb: .quit,
            rawInput: "quit"
        )
        let context = ActionContext(
            command: command,
            engine: engine
        )

        // Validate
        try await handler.validate(context: context)

        // Process
        let result = try await handler.process(context: context)

        // Verify complete workflow
        #expect(result.message == "Goodbye!")
        #expect(result.changes.isEmpty)
        #expect(result.effects.isEmpty)
        #expect(await engine.shouldQuit)
    }

    @Test("QUIT works regardless of game state")
    func testQuitWorksInDifferentStates() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Modify game state
        try await engine.apply(
            engine.updatePlayerScore(by: 100)
        )

        // Act: QUIT should work the same regardless of game state
        try await engine.execute("quit")

        // Assert Output is unchanged
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > quit
            Your score is 100 (total of 10 points), in 0 moves. Do you wish
            to leave the game? (Y is affirmative):> 
            Goodbye!
            """)

        // Should still request quit
        #expect(await engine.shouldQuit)
    }

    @Test("QUIT does not modify game state")
    func testQuitDoesNotModifyGameState() async throws {
        let (engine, _) = await GameEngine.test()

        // Capture initial state
        let initialState = await engine.gameState
        let initialScore = initialState.player.score
        let initialMoves = initialState.player.moves
        let initialLocation = initialState.player.currentLocationID

        // Execute QUIT
        try await engine.execute("quit")

        // Verify game state hasn't changed (except for quit flag)
        let finalState = await engine.gameState
        #expect(finalState.player.score == initialScore)
        #expect(finalState.player.moves == initialMoves)
        #expect(finalState.player.currentLocationID == initialLocation)
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("QUIT with extra parameters still works")
    func testQuitWithExtraParameters() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act: Use engine.execute for full pipeline
        try await engine.execute("quit game now")

        // Assert Output - should work the same way
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > quit game now
            Goodbye!
            """)

        // Should request quit
        #expect(await engine.shouldQuit)
    }

    @Test("Multiple QUIT commands maintain quit state")
    func testMultipleQuitCommands() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Execute QUIT multiple times
        try await engine.execute("quit")
        #expect(await engine.shouldQuit)
        let firstOutput = await mockIO.flush()

        try await engine.execute("quit")
        #expect(await engine.shouldQuit) // Should still be quitting
        let secondOutput = await mockIO.flush()

        // Both outputs should be identical
        expectNoDifference(firstOutput, """
            > quit
            Your score is 0 (total of 10 points), in 0 moves. Do you wish
            to leave the game? (Y is affirmative):> 
            Goodbye!
            """)
        expectNoDifference(secondOutput, """
            > quit
            Your score is 0 (total of 10 points), in 0 moves. Do you wish
            to leave the game? (Y is affirmative):> 
            Goodbye!
            """)
    }

    @Test("DEBUG: Check if quit verb is in vocabulary")
    func testDebugQuitVocabulary() async throws {
        // Given
        let (engine, _) = await GameEngine.test()

        // Check if quit verb is in vocabulary
        let vocabulary = await engine.gameState.vocabulary
        let quitVerbs = vocabulary.verbSynonyms["quit"]
        print("Quit verbs in vocabulary: \(quitVerbs)")

        // Check if parser recognizes quit
        let parseResult = await engine.parser.parse(
            input: "quit",
            vocabulary: vocabulary,
            gameState: await engine.gameState
        )

        switch parseResult {
        case .success(let command):
            print("Parser successfully recognized quit: \(command)")
            #expect(command.verb == .quit)
        case .failure(let error):
            print("Parser failed to recognize quit: \(error)")
            Issue.record("Parser should recognize quit but failed with error: \(error)")
        }
    }

    @Test("DEBUG: What happens when we execute quit")
    func testDebugQuitExecution() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test()
        await mockIO.enqueueInput("y")

        print("=== Before execute ===")
        print("Should quit: \(await engine.shouldQuit)")

        // When
        try await engine.execute("quit")

        print("=== After execute ===")
        print("Should quit: \(await engine.shouldQuit)")

        // Then
        let output = await mockIO.flush()
        print("Output: '\(output)'")

        // Just check that something happened
        #expect(!output.isEmpty)
    }

    @Test("QUIT displays score and confirms with Y")
    func testQuitConfirmsWithY() async throws {
        // Given
        let game = MinimalGame(
            player: Player(in: .startRoom, moves: 13, score: 35)
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Queue Y as response to confirmation
        await mockIO.enqueueInput("y")

        // When
        try await engine.execute("quit")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > quit
            Your score is 35 (total of 10 points), in 13 moves. Do you wish
            to leave the game? (Y is affirmative):
            Goodbye!
            """)

        #expect(await engine.shouldQuit)
    }

    @Test("QUIT displays score and cancels with N")
    func testQuitCancelsWithN() async throws {
        // Given
        let game = MinimalGame(
            player: Player(in: .startRoom, moves: 5, score: 20)
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Queue N as response to confirmation
        await mockIO.enqueueInput("n")

        // When
        try await engine.execute("quit")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > quit
            Your score is 20 (total of 10 points), in 5 moves. Do you wish
            to leave the game? (Y is affirmative): n
            OK, continuing the game.
            """)

        #expect(await !engine.shouldQuit)
    }

    @Test("QUIT accepts 'yes' and 'no' as well as Y/N")
    func testQuitAcceptsFullWords() async throws {
        // Given
        let game = MinimalGame(
            player: Player(in: .startRoom, moves: 8, score: 42)
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Queue "yes" as response to confirmation
        await mockIO.enqueueInput("yes")

        // When
        try await engine.execute("quit")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > quit
            Your score is 42 (total of 10 points), in 8 moves. Do you wish
            to leave the game? (Y is affirmative): yes
            Goodbye!
            """)

        #expect(await engine.shouldQuit)
    }

    @Test("QUIT handles invalid responses and retries")
    func testQuitHandlesInvalidResponses() async throws {
        // Given
        let game = MinimalGame(
            player: Player(in: .startRoom, moves: 1, score: 0)
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Queue invalid responses followed by valid one
        await mockIO.enqueueInput("maybe", "perhaps", "y")

        // When
        try await engine.execute("quit")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > quit
            Your score is 0 (total of 10 points), in 1 moves. Do you wish
            to leave the game? (Y is affirmative): maybe
            Please answer yes or no. perhaps
            Please answer yes or no. y
            Goodbye!
            """)

        #expect(await engine.shouldQuit)
    }

    @Test("QUIT handles EOF as confirmation")
    func testQuitHandlesEOF() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test()

        // Don't queue any input - readLine will return nil (EOF)

        // When
        try await engine.execute("quit")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > quit
            Your score is 0 (total of 10 points), in 0 moves. Do you wish
            to leave the game? (Y is affirmative):
            Goodbye!
            """)

        #expect(await engine.shouldQuit)
    }

    @Test("QUIT works with different score values")
    func testQuitWithDifferentScores() async throws {
        // Given
        let game = MinimalGame(
            player: Player(in: .startRoom, moves: 100, score: 999)
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        await mockIO.enqueueInput("no")

        // When
        try await engine.execute("quit")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > quit
            Your score is 999 (total of 10 points), in 100 moves. Do you wish
            to leave the game? (Y is affirmative): no
            OK, continuing the game.
            """)

        #expect(await !engine.shouldQuit)
    }

    @Test("QUIT with extra text is parsed correctly")
    func testQuitWithExtraText() async throws {
        let (engine, mockIO) = await GameEngine.test()
        await mockIO.enqueueInput("y")

        try await engine.execute("quit game now")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > quit game now
            Your score is 0 (total of 10 points), in 0 moves. Do you wish
            to leave the game? (Y is affirmative): y
            Goodbye!
            """)

        #expect(await engine.shouldQuit)
    }

    @Test("QUIT handler works directly")
    func testQuitHandlerDirect() async throws {
        // Given
        let handler = QuitActionHandler()
        let game = MinimalGame(
            player: Player(in: .startRoom, moves: 13, score: 35)
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Queue Y as response to confirmation
        await mockIO.enqueueInput("y")

        let command = Command(
            verb: .quit,
            rawInput: "quit"
        )
        let context = ActionContext(
            command: command,
            engine: engine
        )

        // When
        let result = try await handler.process(context: context)

        // Then
        print("Result message: \(result.message)")
        print("Should quit: \(await engine.shouldQuit)")

        let output = await mockIO.flush()
        print("Output: '\(output)'")

        #expect(await engine.shouldQuit)
        #expect(result.message == "Goodbye!")
    }
}
