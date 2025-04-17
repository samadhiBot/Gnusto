import Foundation

/// Defines the interface for a command parser.
public protocol Parser: Sendable {
    /// Parses a raw input string into a structured `Command` within a given game context.
    ///
    /// - Parameters:
    ///   - input: The raw string entered by the player.
    ///   - vocabulary: The game's vocabulary.
    ///   - gameState: The current state of the game for context (e.g., scope, pronoun resolution).
    /// - Returns: A `Result` containing either a `Command` or a `ParseError`.
    func parse(
        input: String,
        vocabulary: Vocabulary,
        gameState: GameState
    ) -> Result<Command, ParseError>
}
