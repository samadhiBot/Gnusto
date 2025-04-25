import Foundation

/// Action handler for the SCORE verb.
struct ScoreActionHandler: ActionHandler {
    func perform(command: Command, engine: GameEngine) async throws {
        // Use the safe accessor on the engine
        let currentScore = await engine.playerScore()
        let turnCount = await engine.playerMoves()
        await engine.output("Your score is \(currentScore) in \(turnCount) turns.")
    }
}
