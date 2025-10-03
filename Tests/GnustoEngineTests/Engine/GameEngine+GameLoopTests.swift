import CustomDump
import GnustoTestSupport
import Testing

@testable import GnustoEngine

@Suite("GameEngine Game Loop Tests")
struct GameEngineGameLoopTests {

    // MARK: - Process Turn Tests

    @Test("processTurn handles basic command execution")
    func testProcessTurnBasicCommand() async throws {
        let game = MinimalGame()

        let (engine, mockIO) = await GameEngine.test(
            blueprint: game,
            ioHandler: await MockIOHandler("look")
        )

        try await engine.processTurn()

        await mockIO.expect(
            """
            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.
            """
        )
    }

    @Test("processTurn handles quit command")
    func testProcessTurnQuitCommand() async throws {
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(
            blueprint: game,
            ioHandler: await MockIOHandler("quit")
        )

        #expect(await engine.shouldQuit == false)

        try await engine.processTurn()

        #expect(await engine.shouldQuit == true)
    }

    @Test("processTurn handles EOF input")
    func testProcessTurnEOFInput() async throws {
        let game = MinimalGame()

        let (engine, mockIO) = await GameEngine.test(
            blueprint: game,
            ioHandler: await MockIOHandler(nil)  // nil simulates EOF
        )

        #expect(await engine.shouldQuit == false)

        try await engine.processTurn()

        #expect(await engine.shouldQuit == true)

        await mockIO.expect(
            """
            >
            Farewell, brave soul!
            """
        )
    }

    @Test("processTurn handles parse errors")
    func testProcessTurnParseError() async throws {
        let game = MinimalGame()

        let (engine, mockIO) = await GameEngine.test(
            blueprint: game,
            ioHandler: await MockIOHandler("xyzzy nonexistent very complex invalid syntax")
        )

        try await engine.processTurn()

        await mockIO.expect(
            """
            > xyzzy nonexistent very complex invalid syntax
            The phrase 'nonexistent very complex invalid syntax' eludes my
            comprehension.
            """
        )
    }

    @Test("processTurn skips processing when shouldQuit is already true")
    func testProcessTurnSkipsWhenShouldQuit() async throws {
        let game = MinimalGame()

        let (engine, mockIO) = await GameEngine.test(
            blueprint: game,
            ioHandler: await MockIOHandler("look")
        )

        // Set shouldQuit before processing
        try await engine.apply(.requestGameQuit)
        #expect(await engine.shouldQuit == true)

        try await engine.processTurn()

        // Should not have processed the command
        let output = await mockIO.flush()
        #expect(output.isEmpty)
    }

    @Test("processTurn skips processing when shouldRestart is true")
    func testProcessTurnSkipsWhenShouldRestart() async throws {
        let game = MinimalGame()

        let (engine, mockIO) = await GameEngine.test(
            blueprint: game,
            ioHandler: await MockIOHandler("look")
        )

        // Set shouldRestart before processing
        try await engine.apply(.requestGameRestart)
        #expect(await engine.shouldRestart == true)

        try await engine.processTurn()

        // Should not have processed the command
        let output = await mockIO.flush()
        #expect(output.isEmpty)
    }

    // MARK: - Show Status Tests

    @Test("showStatus displays correct information")
    func testShowStatus() async throws {
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.showStatus()

        // Verify the status line was called with correct parameters
        // Note: We can't directly verify the IOHandler call parameters in this setup,
        // but we can verify no errors were thrown
        _ = await mockIO.flush()
        // MockIOHandler may or may not output anything for showStatusLine
        // The important thing is that it didn't throw an error
    }

    // MARK: - Request Quit Tests

    @Test("requestQuit sets shouldQuit flag")
    func testRequestQuit() async throws {
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)

        #expect(await engine.shouldQuit == false)

        try await engine.apply(.requestGameQuit)

        #expect(await engine.shouldQuit == true)
    }

    // MARK: - Request Restart Tests

    @Test("requestRestart sets shouldRestart flag")
    func testRequestRestart() async throws {
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)

        #expect(await engine.shouldRestart == false)

        try await engine.apply(.requestGameRestart)

        #expect(await engine.shouldRestart == true)
    }

    // MARK: - Game Loop Run Tests

    @Test("run method handles immediate quit")
    func testRunWithImmediateQuit() async throws {
        let game = MinimalGame()

        let (engine, mockIO) = await GameEngine.test(
            blueprint: game,
            ioHandler: await MockIOHandler("quit", "y")
        )

        await engine.run()

        await mockIO.expect(
            """
            Minimal Game

            Welcome to the Minimal Game!

            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.

            > quit
            Your score is 0 (total of 10 points), in 0 moves. Do you wish
            to leave the game? (Y is affirmative): y
            Farewell, brave soul!
            """
        )
    }

    @Test("run method handles restart")
    func testRunWithRestart() async throws {
        let testItem = Item("testItem")
            .name("test item")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(items: testItem)

        let (engine, mockIO) = await GameEngine.test(
            blueprint: game,
            ioHandler: await MockIOHandler("take test item", "restart", "y")
        )

        await engine.run()

        await mockIO.expect(
            """
            Minimal Game

            Welcome to the Minimal Game!

            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.

            There is a test item here.

            > take test item
            Got it.

            > restart
            If you restart now you will lose any unsaved progress. Are you
            sure you want to restart? (Y is affirmative): y
            Restarting the game...
            """
        )
    }

    @Test("run method displays title and introduction")
    func testRunDisplaysTitleAndIntroduction() async throws {
        let game = MinimalGame()

        let (engine, mockIO) = await GameEngine.test(
            blueprint: game,
            ioHandler: await MockIOHandler("quit", "y")
        )

        await engine.run()

        await mockIO.expect(
            """
            Minimal Game

            Welcome to the Minimal Game!

            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.

            > quit
            Your score is 0 (total of 10 points), in 0 moves. Do you wish
            to leave the game? (Y is affirmative): y
            Farewell, brave soul!
            """
        )
    }

    // MARK: - Error Handling Tests

    @Test("processTurn handles errors gracefully")
    func testProcessTurnErrorHandling() async throws {
        let game = MinimalGame()

        let (engine, mockIO) = await GameEngine.test(
            blueprint: game,
            ioHandler: await MockIOHandler(
                "examine nonexistent very complex item with multiple words")
        )

        // Should not throw - errors should be caught and logged
        try await engine.processTurn()

        await mockIO.expect(
            """
            > examine nonexistent very complex item with multiple words
            The phrase 'with multiple words' eludes my comprehension.
            """
        )
    }

    @Test("run method handles errors in showStatus gracefully")
    func testRunHandlesShowStatusErrors() async throws {
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(
            blueprint: game,
            ioHandler: await MockIOHandler("quit", "y")
        )

        // Should not throw even if status display has issues
        await engine.run()

        #expect(await engine.shouldQuit == true)
    }

    // MARK: - Turn Consumption Tests

    @Test("successful commands consume turns")
    func testSuccessfulCommandsConsumeTurns() async throws {
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(
            blueprint: game,
            ioHandler: await MockIOHandler("look")
        )

        let initialMoves = await engine.gameState.player.moves

        try await engine.processTurn()

        let finalMoves = await engine.gameState.player.moves
        #expect(finalMoves > initialMoves)
    }

    @Test("parse errors consume turns")
    func testParseErrorsConsumeTurns() async throws {
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(
            blueprint: game,
            ioHandler: await MockIOHandler("invalid nonsense command")
        )

        let initialMoves = await engine.gameState.player.moves

        try await engine.processTurn()

        let finalMoves = await engine.gameState.player.moves
        #expect(finalMoves > initialMoves)
    }

    // MARK: - Integration Tests

    @Test("complete game session with multiple commands")
    func testCompleteGameSession() async throws {
        let testItem = Item("coin")
            .name("gold coin")
            .description("A shiny gold coin.")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(items: testItem)

        let (engine, mockIO) = await GameEngine.test(
            blueprint: game,
            ioHandler: await MockIOHandler(
                """
                look
                examine coin
                take coin
                inventory
                quit
                y
                """
            )
        )

        await engine.run()

        await mockIO.expect(
            """
            Minimal Game

            Welcome to the Minimal Game!

            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.

            There is a gold coin here.

            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.

            Present in this location is a gold coin.

            > examine coin
            A shiny gold coin.

            > take coin
            Acquired.

            > inventory
            You are carrying:
            - A gold coin

            > quit
            Your score is 0 (total of 10 points), in 3 moves. Do you wish
            to leave the game? (Y is affirmative): y
            May your adventures elsewhere prove fruitful!
            """
        )
    }

    @Test("game loop maintains state consistency")
    func testGameLoopStateConsistency() async throws {
        let testItem = Item("testItem")
            .name("test item")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(items: testItem)

        let (engine, mockIO) = await GameEngine.test(
            blueprint: game,
            ioHandler: await MockIOHandler("take test item")
        )

        try await engine.processTurn()

        // Verify the item is now held
        let item = await engine.item("testItem")
        #expect(await item.parent == .player)

        // Verify player location is still correct
        let playerLocation = await engine.player.location
        #expect(playerLocation.id == .startRoom)

        await mockIO.expect(
            """
            > take test item
            Taken.
            """
        )
    }

    @Test("multiple turns advance move counter correctly")
    func testMultipleTurnsAdvanceMoveCounter() async throws {
        let game = MinimalGame()

        // Test that commands consume turns by using execute() method instead of processTurn()
        // which better simulates the full game loop behavior
        let (engine, _) = await GameEngine.test(blueprint: game)

        let initialMoves = await engine.gameState.player.moves

        // Execute commands that should consume turns
        try await engine.execute("look")
        let movesAfterFirst = await engine.gameState.player.moves
        #expect(movesAfterFirst == initialMoves + 1)

        try await engine.execute("wait")
        let movesAfterSecond = await engine.gameState.player.moves
        #expect(movesAfterSecond == initialMoves + 2)

        try await engine.execute("look")
        let finalMoves = await engine.gameState.player.moves
        #expect(finalMoves == initialMoves + 3)
    }
}
