import Foundation
@testable import GnustoEngine

/// A mock implementation of the `Parser` protocol for testing purposes.
struct MockParser: Parser {

    /// A closure that the mock will execute when `parse` is called.
    /// Allows tests to define custom parsing results.
    var parseHandler: (@Sendable (String, Vocabulary, GameState) -> Result<Command, ParseError>)?

    /// A predefined result to return for *any* input if `parseHandler` is nil.
    var defaultParseResult: Result<Command, ParseError>?

    func parse(input: String, vocabulary: Vocabulary, gameState: GameState) -> Result<Command, ParseError> {
        if let handler = parseHandler {
            return handler(input, vocabulary, gameState)
        } else if let defaultResult = defaultParseResult {
            return defaultResult
        } else {
            // Default fallback if nothing is configured
            return .failure(.internalError("MockParser not configured"))
        }
    }
}
