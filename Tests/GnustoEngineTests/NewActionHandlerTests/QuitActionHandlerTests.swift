import CustomDump
import Testing

@testable import GnustoEngine

@Suite("QuitActionHandler Tests")
struct QuitActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("QUIT syntax works")
    func testQuitSyntax() async throws {
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

        // Set up mock to respond "yes" to quit confirmation
        await mockIO.setQueuedInputs(["yes"])

        // When
        try await engine.execute("quit")

        // Then
        let output = await mockIO.flush()
        let lines = output.components(separatedBy: "\n")

        // Should start with command echo
        #expect(lines.first == "> quit")

        // Should contain score information and goodbye message
        #expect(output.contains("score"))
        #expect(output.contains("moves"))
        #expect(output.contains("Goodbye"))
    }

    @Test("Q shorthand syntax works")
    func testQShorthandSyntax() async throws {
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

        // Set up mock to respond "y" to quit confirmation
        await mockIO.setQueuedInputs(["y"])

        // When
        try await engine.execute("q")

        // Then
        let output = await mockIO.flush()
        let lines = output.components(separatedBy: "\n")

        #expect(lines.first == "> q")
        #expect(output.contains("score"))
        #expect(output.contains("Goodbye"))
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
        await mockIO.setQueuedInputs(["yes"])

        // When
        try await engine.execute("quit")

        // Then - Quit should work even in darkness
        let output = await mockIO.flush()
        let lines = output.components(separatedBy: "\n")

        #expect(lines.first == "> quit")
        #expect(output.contains("Goodbye"))
    }

    @Test("Quit accepts no parameters")
    func testQuitAcceptsNoParameters() async throws {
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

        // Set up mock to respond "yes" to quit confirmation
        await mockIO.setQueuedInputs(["yes"])

        // When
        try await engine.execute("quit")

        // Then
        let output = await mockIO.flush()
        #expect(output.contains("Goodbye"))
    }

    // MARK: - Processing Testing

    @Test("Quit confirmation with yes quits game")
    func testQuitConfirmationWithYesQuitsGame() async throws {
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

        // Set up mock to respond "yes" to quit confirmation
        await mockIO.setQueuedInputs(["yes"])

        // When
        try await engine.execute("quit")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > quit
            Your score is 0 of 0, in 1 move.
            Do you really want to quit? yes
            Goodbye.
            """)

        // Game should be marked for quit
        let isQuitting = await engine.isQuitting
        #expect(isQuitting == true)
    }

    @Test("Quit confirmation with y quits game")
    func testQuitConfirmationWithYQuitsGame() async throws {
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

        // Set up mock to respond "y" to quit confirmation
        await mockIO.setQueuedInputs(["y"])

        // When
        try await engine.execute("quit")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > quit
            Your score is 0 of 0, in 1 move.
            Do you really want to quit? y
            Goodbye.
            """)

        let isQuitting = await engine.isQuitting
        #expect(isQuitting == true)
    }

    @Test("Quit confirmation with no cancels quit")
    func testQuitConfirmationWithNoCancelsQuit() async throws {
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

        // Set up mock to respond "no" to quit confirmation
        await mockIO.setQueuedInputs(["no"])

        // When
        try await engine.execute("quit")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > quit
            Your score is 0 of 0, in 1 move.
            Do you really want to quit? no
            OK.
            """)

        // Game should NOT be marked for quit
        let isQuitting = await engine.isQuitting
        #expect(isQuitting == false)
    }

    @Test("Quit confirmation with n cancels quit")
    func testQuitConfirmationWithNCancelsQuit() async throws {
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

        // Set up mock to respond "n" to quit confirmation
        await mockIO.setQueuedInputs(["n"])

        // When
        try await engine.execute("quit")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > quit
            Your score is 0 of 0, in 1 move.
            Do you really want to quit? n
            OK.
            """)

        let isQuitting = await engine.isQuitting
        #expect(isQuitting == false)
    }

    @Test("Quit handles invalid response then valid response")
    func testQuitHandlesInvalidResponseThenValid() async throws {
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

        // Set up mock to respond with invalid then valid response
        await mockIO.setQueuedInputs(["maybe", "yes"])

        // When
        try await engine.execute("quit")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > quit
            Your score is 0 of 0, in 1 move.
            Do you really want to quit? maybe
            Please answer yes or no. yes
            Goodbye.
            """)

        let isQuitting = await engine.isQuitting
        #expect(isQuitting == true)
    }

    @Test("Quit handles multiple invalid responses")
    func testQuitHandlesMultipleInvalidResponses() async throws {
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

        // Set up mock to respond with multiple invalid then valid response
        await mockIO.setQueuedInputs(["invalid", "wrong", "no"])

        // When
        try await engine.execute("quit")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > quit
            Your score is 0 of 0, in 1 move.
            Do you really want to quit? invalid
            Please answer yes or no. wrong
            Please answer yes or no. no
            OK.
            """)

        let isQuitting = await engine.isQuitting
        #expect(isQuitting == false)
    }

    @Test("Quit displays current score and moves")
    func testQuitDisplaysCurrentScoreAndMoves() async throws {
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

        // Set some score and execute some moves
        try await engine.apply(
            await engine.setPlayerScore(25)
        )

        // Execute a few commands to increase move count
        try await engine.execute("look")
        _ = await mockIO.flush()
        try await engine.execute("inventory")
        _ = await mockIO.flush()

        // Set up mock to respond "yes" to quit confirmation
        await mockIO.setQueuedInputs(["yes"])

        // When
        try await engine.execute("quit")

        // Then
        let output = await mockIO.flush()

        // Should display the score and move count
        // Move count should be 4 (look + inventory + quit + initial move)
        #expect(output.contains("Your score is 25"))
        #expect(output.contains("in 4 moves"))
    }

    @Test("Quit with maximum score displays correctly")
    func testQuitWithMaximumScoreDisplaysCorrectly() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        // Create a game with maximum score
        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            maximumScore: 100
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set up mock to respond "yes" to quit confirmation
        await mockIO.setQueuedInputs(["yes"])

        // When
        try await engine.execute("quit")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > quit
            Your score is 0 of 100, in 1 move.
            Do you really want to quit? yes
            Goodbye.
            """)
    }

    @Test("Quit handles EOF as confirmation")
    func testQuitHandlesEOFAsConfirmation() async throws {
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

        // Set up mock to return nil (EOF) for input
        await mockIO.setQueuedInputs([])
        await mockIO.simulateEOF()

        // When
        try await engine.execute("quit")

        // Then
        let output = await mockIO.flush()

        // Should quit on EOF
        #expect(output.contains("Goodbye"))

        let isQuitting = await engine.isQuitting
        #expect(isQuitting == true)
    }

    @Test("Quit response is case insensitive")
    func testQuitResponseIsCaseInsensitive() async throws {
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

        // Set up mock to respond with uppercase
        await mockIO.setQueuedInputs(["YES"])

        // When
        try await engine.execute("quit")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > quit
            Your score is 0 of 0, in 1 move.
            Do you really want to quit? YES
            Goodbye.
            """)

        let isQuitting = await engine.isQuitting
        #expect(isQuitting == true)
    }

    @Test("Quit handles whitespace in response")
    func testQuitHandlesWhitespaceInResponse() async throws {
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

        // Set up mock to respond with whitespace around answer
        await mockIO.setQueuedInputs(["  no  "])

        // When
        try await engine.execute("quit")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > quit
            Your score is 0 of 0, in 1 move.
            Do you really want to quit?   no
            OK.
            """)

        let isQuitting = await engine.isQuitting
        #expect(isQuitting == false)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = QuitActionHandler()
        // QuitActionHandler doesn't specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = QuitActionHandler()
        #expect(handler.verbs.contains(.quit))
        #expect(handler.verbs.contains("q"))
        #expect(handler.verbs.count == 2)
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
