import Foundation

/// Defines the interface for turning raw player input strings into structured `Command`
/// objects that the `GameEngine` can understand and process.
///
/// A `Parser` implementation is responsible for tokenizing the input, looking up words
/// in the game's `Vocabulary`, understanding grammar, and resolving references to
/// objects in the current `GameState` (e.g., pronouns, items in scope).
///
/// Game developers typically interact with parsers indirectly. The `GameEngine` uses a
/// configured `Parser` instance (like `StandardParser`) to interpret player commands.
/// Customizing parsing behavior usually involves modifying the `Vocabulary` or, for
/// advanced scenarios, providing a custom `Parser` implementation.
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
