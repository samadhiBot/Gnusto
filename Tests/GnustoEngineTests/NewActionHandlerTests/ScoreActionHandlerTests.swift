import CustomDump
import Testing

@testable import GnustoEngine

@Suite("ScoreActionHandler Tests")
struct ScoreActionHandlerTests {
    let handler = ScoreActionHandler()
    var engine: GameEngine!
    var mockIO: MockIOHandler!

    // MARK: - Syntax Rule Testing

    @Test("SCORE syntax works")
    func testScoreSyntax() async throws {
        let player = Player(in: "room", score: 42, moves: 123)
        (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame(player: player))

        try await engine.execute("score")
        let output = await mockIO.flush()
        #expect(output.contains("Your score is 42 in 123 moves."))
    }

    // MARK: - Validation Testing

    @Test("Validation always succeeds")
    func testValidationSucceeds() async throws {
        (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())
        let context = ActionContext(
            command: Command(verb: .score, rawInput: "score"), engine: engine)
        try await handler.validate(context: context)
    }

    // MARK: - Processing Testing

    @Test("Processing returns correct message with zero score and moves")
    func testProcessZeroState() async throws {
        (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())

        try await engine.execute("score")
        let output = await mockIO.flush()
        #expect(output.contains("Your score is 0 in 0 moves."))
    }

    @Test("Processing returns correct message with non-zero score and moves")
    func testProcessNonZeroState() async throws {
        let player = Player(in: "room", score: 10, moves: 5)
        (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame(player: player))

        try await engine.execute("score")
        let output = await mockIO.flush()
        #expect(output.contains("Your score is 10 in 5 moves."))
    }

    // MARK: - ActionID Testing

    @Test("SCORE action resolves to ScoreActionHandler")
    func testScoreActionID() async throws {
        (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())
        let parser = StandardParser()
        let command = try parser.parse("score")
        let resolvedAction = await engine.resolveAction(for: command)
        #expect(isNotNil(resolvedAction))
        #expect(resolvedAction?.handler is ScoreActionHandler)
    }
}
