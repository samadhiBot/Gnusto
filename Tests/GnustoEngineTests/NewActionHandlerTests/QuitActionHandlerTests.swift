import CustomDump
import Testing

@testable import GnustoEngine

@Suite("QuitActionHandler Tests")
struct QuitActionHandlerTests {
    let handler = QuitActionHandler()
    var game: MinimalGame!
    var engine: GameEngine!
    var mockIO: MockIOHandler!

    // MARK: - Syntax Rule Testing

    @Test("QUIT syntax works")
    func testQuitSyntax() async throws {
        (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())
        await mockIO.enqueueInput("y")
        try await engine.execute("quit")
        let output = await mockIO.flush()
        #expect(output.contains("Do you wish to leave the game?"))
        #expect(output.contains("Goodbye!"))
        #expect(await engine.shouldQuit == true)
    }

    @Test("Q alias works")
    func testQAlias() async throws {
        (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())
        await mockIO.enqueueInput("y")
        try await engine.execute("q")
        let output = await mockIO.flush()
        #expect(output.contains("Do you wish to leave the game?"))
        #expect(output.contains("Goodbye!"))
        #expect(await engine.shouldQuit == true)
    }

    // MARK: - Validation Testing

    @Test("Validation always succeeds")
    func testValidationSucceeds() async throws {
        (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())
        let context = ActionContext(command: Command(verb: .quit, rawInput: "quit"), engine: engine)
        try await handler.validate(context: context)
    }

    // MARK: - Processing Testing

    @Test("Confirming with 'y' quits the game")
    func testProcessConfirmY() async throws {
        game = MinimalGame(player: Player(in: "room", score: 10, moves: 5))
        (engine, mockIO) = await GameEngine.test(blueprint: game)
        await mockIO.enqueueInput("y")

        try await engine.execute("quit")

        let output = await mockIO.flush()
        #expect(output.contains("Your score is 10 (total of 10 points), in 5 moves."))
        #expect(output.contains("Goodbye!"))
        #expect(await engine.shouldQuit == true)
    }

    @Test("Confirming with 'yes' quits the game")
    func testProcessConfirmYes() async throws {
        (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())
        await mockIO.enqueueInput("yes")
        try await engine.execute("quit")
        #expect(await engine.shouldQuit == true)
    }

    @Test("Cancelling with 'n' continues the game")
    func testProcessCancelN() async throws {
        (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())
        await mockIO.enqueueInput("n")

        try await engine.execute("quit")

        let output = await mockIO.flush()
        #expect(output.contains("OK, continuing the game."))
        #expect(await engine.shouldQuit == false)
    }

    @Test("Cancelling with 'no' continues the game")
    func testProcessCancelNo() async throws {
        (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())
        await mockIO.enqueueInput("no")
        try await engine.execute("quit")
        #expect(await engine.shouldQuit == false)
    }

    @Test("Invalid input re-prompts")
    func testProcessInvalidInput() async throws {
        (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())
        await mockIO.enqueueInput("maybe", "y")

        try await engine.execute("quit")

        let output = await mockIO.flush()
        #expect(output.contains("Please answer yes or no."))
        #expect(output.contains("Goodbye!"))
        #expect(await engine.shouldQuit == true)
    }

    @Test("EOF quits the game")
    func testProcessEOF() async throws {
        (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())
        // Enqueue nothing, so readLine returns nil
        try await engine.execute("quit")
        #expect(await engine.shouldQuit == true)
    }

    // MARK: - ActionID Testing

    @Test("QUIT action resolves to QuitActionHandler")
    func testQuitActionID() async throws {
        (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())
        let parser = StandardParser()
        let command = try parser.parse("quit")
        let resolvedAction = await engine.resolveAction(for: command)
        #expect(isNotNil(resolvedAction))
        #expect(resolvedAction?.handler is QuitActionHandler)
    }
}
