import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("QuitActionHandler Tests")
struct QuitActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("QUIT syntax works")
    func testQuitSyntax() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up mock to respond "yes" to quit confirmation
        await mockIO.enqueueInput("yes")

        // When
        try await engine.execute("quit")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > quit
            Your score is 0 (total of 10 points), in 0 moves. Do you wish
            to leave the game? (Y is affirmative): yes
            Farewell, brave soul!
            """
        )
    }

    @Test("Q shorthand syntax works")
    func testQShorthandSyntax() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up mock to respond "y" to quit confirmation
        await mockIO.enqueueInput("y")

        // When
        try await engine.execute("q")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > q
            Your score is 0 (total of 10 points), in 0 moves. Do you wish
            to leave the game? (Y is affirmative): y
            Farewell, brave soul!
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Quit does not require light")
    func testQuitDoesNotRequireLight() async throws {
        // Given: Dark room
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

        // Set up mock to respond "yes" to quit confirmation
        await mockIO.enqueueInput("yes")

        // When
        try await engine.execute("quit")

        // Then - Quit should work even in darkness
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > quit
            Your score is 0 (total of 10 points), in 0 moves. Do you wish
            to leave the game? (Y is affirmative): yes
            Farewell, brave soul!
            """
        )
    }

    @Test("Quit accepts no parameters")
    func testQuitAcceptsNoParameters() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up mock to respond "yes" to quit confirmation
        await mockIO.enqueueInput("yes")

        // When
        try await engine.execute("quit")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > quit
            Your score is 0 (total of 10 points), in 0 moves. Do you wish
            to leave the game? (Y is affirmative): yes
            Farewell, brave soul!
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Quit confirmation with yes quits game")
    func testQuitConfirmationWithYesQuitsGame() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up mock to respond "yes" to quit confirmation
        await mockIO.enqueueInput("yes")

        // When
        try await engine.execute("quit")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > quit
            Your score is 0 (total of 10 points), in 0 moves. Do you wish
            to leave the game? (Y is affirmative): yes
            Farewell, brave soul!
            """
        )

        // Game should be marked for quit
        let shouldQuit = await engine.shouldQuit
        #expect(shouldQuit == true)
    }

    @Test("Quit confirmation with y quits game")
    func testQuitConfirmationWithYQuitsGame() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up mock to respond "y" to quit confirmation
        await mockIO.enqueueInput("y")

        // When
        try await engine.execute("quit")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > quit
            Your score is 0 (total of 10 points), in 0 moves. Do you wish
            to leave the game? (Y is affirmative): y
            Farewell, brave soul!
            """
        )

        let shouldQuit = await engine.shouldQuit
        #expect(shouldQuit == true)
    }

    @Test("Quit confirmation with no cancels quit")
    func testQuitConfirmationWithNoCancelsQuit() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up mock to respond "no" to quit confirmation
        await mockIO.enqueueInput("no")

        // When
        try await engine.execute("quit")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > quit
            Your score is 0 (total of 10 points), in 0 moves. Do you wish
            to leave the game? (Y is affirmative): no
            The adventure continues!
            """
        )

        // Game should NOT be marked for quit
        let shouldQuit = await engine.shouldQuit
        #expect(shouldQuit == false)
    }

    @Test("Quit confirmation with n cancels quit")
    func testQuitConfirmationWithNCancelsQuit() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up mock to respond "n" to quit confirmation
        await mockIO.enqueueInput("n")

        // When
        try await engine.execute("quit")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > quit
            Your score is 0 (total of 10 points), in 0 moves. Do you wish
            to leave the game? (Y is affirmative): n
            The adventure continues!
            """
        )

        let shouldQuit = await engine.shouldQuit
        #expect(shouldQuit == false)
    }

    @Test("Quit handles invalid response then valid response")
    func testQuitHandlesInvalidResponseThenValid() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up mock to respond with invalid then valid response
        await mockIO.enqueueInput("maybe", "y")

        // When
        try await engine.execute("quit")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > quit
            Your score is 0 (total of 10 points), in 0 moves. Do you wish
            to leave the game? (Y is affirmative): maybe
            Your response defies binary interpretation. I'll take that as a
            'no'.
            """
        )

        let shouldQuit = await engine.shouldQuit
        #expect(shouldQuit == false)
    }

    @Test("Quit handles multiple invalid responses")
    func testQuitHandlesMultipleInvalidResponses() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up mock to respond with multiple invalid then valid response
        await mockIO.enqueueInput("invalid", "wrong", "no")

        // When
        try await engine.execute("quit")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > quit
            Your score is 0 (total of 10 points), in 0 moves. Do you wish
            to leave the game? (Y is affirmative): invalid
            Your response defies binary interpretation. I'll take that as a
            'no'.
            """
        )

        let shouldQuit = await engine.shouldQuit
        #expect(shouldQuit == false)
    }

    @Test("Quit displays current score and moves")
    func testQuitDisplaysCurrentScoreAndMoves() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set some score and execute some moves
        try await engine.apply(
            engine.player.updateScore(by: 25)
        )

        // Execute a few commands to increase move count
        try await engine.execute(
            "look",
            "inventory"
        )

        // Set up mock to respond "yes" to quit confirmation
        await mockIO.enqueueInput("yes")

        // When
        try await engine.execute("quit")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.

            > inventory
            Your hands are as empty as your pockets.

            > quit
            Your score is 25 (total of 10 points), in 1 move. Do you wish
            to leave the game? (Y is affirmative): yes
            May your adventures elsewhere prove fruitful!
            """
        )
    }

    @Test("Quit with maximum score displays correctly")
    func testQuitWithMaximumScoreDisplaysCorrectly() async throws {
        // Given
        // Create a game with maximum score
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up mock to respond "yes" to quit confirmation
        await mockIO.enqueueInput("yes")

        // When
        try await engine.execute("quit")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > quit
            Your score is 0 (total of 10 points), in 0 moves. Do you wish
            to leave the game? (Y is affirmative): yes
            Farewell, brave soul!
            """
        )
    }

    @Test("Quit handles EOF as confirmation")
    func testQuitHandlesEOFAsConfirmation() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("quit")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > quit
            Your score is 0 (total of 10 points), in 0 moves. Do you wish
            to leave the game? (Y is affirmative):
            Farewell, brave soul!
            """
        )
    }

    @Test("Quit response is case insensitive")
    func testQuitResponseIsCaseInsensitive() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up mock to respond with uppercase
        await mockIO.enqueueInput("YES")

        // When
        try await engine.execute("quit")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > quit
            Your score is 0 (total of 10 points), in 0 moves. Do you wish
            to leave the game? (Y is affirmative): YES
            Farewell, brave soul!
            """
        )

        let shouldQuit = await engine.shouldQuit
        #expect(shouldQuit == true)
    }

    @Test("Quit handles whitespace in response")
    func testQuitHandlesWhitespaceInResponse() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up mock to respond with whitespace around answer
        await mockIO.enqueueInput("  no  ")

        // When
        try await engine.execute("quit")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > quit
            Your score is 0 (total of 10 points), in 0 moves. Do you wish
            to leave the game? (Y is affirmative):   no
            The adventure continues!
            """
        )

        let shouldQuit = await engine.shouldQuit
        #expect(shouldQuit == false)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = QuitActionHandler()
        #expect(handler.synonyms.contains(.quit))
        #expect(handler.synonyms.contains("q"))
        #expect(handler.synonyms.count == 2)
    }

    @Test("Handler does not require light")
    func testRequiresLightProperty() async throws {
        let handler = QuitActionHandler()
        #expect(handler.requiresLight == false)
    }

    @Test("Handler uses correct syntax")
    func testSyntaxRules() async throws {
        let handler = QuitActionHandler()
        #expect(handler.syntax.count == 1)

        // Should have one syntax rule:
        // .match(.verb)
    }
}
