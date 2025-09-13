import Foundation

/// Defines a specific grammatical pattern or syntax that a player's command can match
/// for a particular verb.
///
/// The `StandardParser` uses a collection of `SyntaxRule`s, typically associated with
/// each `VerbDefinition` in the `Vocabulary`, to interpret player input. Each rule
/// describes an expected sequence of token types (`SyntaxTokenType`), along with optional
/// conditions (`ObjectCondition`) for any direct or indirect objects, and a specific
/// required preposition if the pattern includes one.
///
/// For example, a "TAKE" verb might have rules like:
/// - `.match(.verb, .directObject)` for "TAKE APPLE"
/// - `.match(.verb, .directObjects)` for "TAKE ALL" or "TAKE APPLE AND ORANGE"
/// - `.match(.verb, .directObject, .in, .indirectObject)` for "PUT APPLE IN BAG"
///
/// Game developers typically define these rules implicitly when creating `VerbDefinition`s
/// using convenience initializers, or explicitly if more control over the grammar is needed.
public struct SyntaxRule: Sendable, Equatable, Codable {
    /// The sequence of `SyntaxTokenType`s that define the grammatical structure of this rule.
    /// For example, `[.verb, .directObject]` or `[.verb, .directObjects, .in, .indirectObject]`.
    public let pattern: [SyntaxTokenType]

    /// Creates a `SyntaxRule` with a specific pattern.
    ///
    /// - Parameters:
    ///   - pattern: An array of `SyntaxTokenType`s defining the rule's structure.
    private init(pattern: [SyntaxTokenType]) {
        self.pattern = pattern
    }

    /// Creates a `SyntaxRule` with the given sequence of `SyntaxTokenType`s.
    ///
    /// This is a factory for simple patterns, e.g. `.rule(.verb, .at, .directObject)`
    ///
    /// - Parameter pattern: A variadic list of `SyntaxTokenType`s defining the rule's structure.
    public static func match(_ pattern: SyntaxTokenType...) -> SyntaxRule {
        .init(pattern: pattern)
    }

    public static func match(
        _ verbID: Verb,
        _ pattern: SyntaxTokenType...
    ) -> SyntaxRule {
        .init(pattern: [.specificVerb(verbID)] + pattern)
    }

    /// Computed property that returns the required preposition for this rule.
    ///
    /// This checks any `.particle(string)` tokens that function as prepositions.
    ///
    /// - Returns: The preposition string, or `nil` if no specific preposition is required.
    public var expectedPreposition: String? {
        // Then check for particle tokens that are prepositions
        for token in pattern {
            if case .particle(let particle) = token {
                // Check if this particle is actually a preposition by seeing if it's in the standard set
                // This is a reasonable heuristic since particles used as prepositions should be prepositions
                if Vocabulary.defaultPrepositions.contains(particle) {
                    return particle
                }
            }
        }
        return nil
    }
}
