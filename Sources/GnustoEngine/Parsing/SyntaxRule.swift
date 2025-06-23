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
/// - `SyntaxRule(.verb, .directObject)` for "TAKE APPLE"
/// - `SyntaxRule(.verb, .directObject, .in, .indirectObject)` for "PUT APPLE IN BAG"
///
/// Game developers typically define these rules implicitly when creating `VerbDefinition`s
/// using convenience initializers, or explicitly if more control over the grammar is needed.
public struct SyntaxRule: Sendable, Equatable, Codable {
    /// The sequence of `SyntaxTokenType`s that define the grammatical structure of this rule.
    /// For example, `[.verb, .directObject]` or `[.verb, .directObject, [.preposition], .indirectObject]`.
    public let pattern: [SyntaxTokenType]

    /// A set of `ObjectCondition`s that the direct object (if specified by `.directObject`
    /// in the `pattern`) must satisfy for this rule to match. For instance, it might
    /// need to be `.held` by the player or be a `.container`.
    public let directObjectConditions: ObjectCondition

    /// A set of `ObjectCondition`s that the indirect object (if specified by `.indirectObject`
    /// in the `pattern`) must satisfy. Similar to `directObjectConditions`.
    public let indirectObjectConditions: ObjectCondition

    /// Computed property that returns the required preposition for this rule.
    ///
    /// This checks any `.particle(string)` tokens that function as prepositions.
    ///
    /// - Returns: The preposition string, or `nil` if no specific preposition is required.
    public var effectiveRequiredPreposition: String? {
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

    // Explicit Codable conformance
    enum CodingKeys: String, CodingKey {
        case pattern
        case directObjectConditionsRawValue // Encode/decode rawValue
        case indirectObjectConditionsRawValue // Encode/decode rawValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pattern = try container.decode([SyntaxTokenType].self, forKey: .pattern)
        let doRawValue = try container.decode(Int.self, forKey: .directObjectConditionsRawValue)
        directObjectConditions = ObjectCondition(rawValue: doRawValue)
        let ioRawValue = try container.decode(Int.self, forKey: .indirectObjectConditionsRawValue)
        indirectObjectConditions = ObjectCondition(rawValue: ioRawValue)

        // Initialize without validation, assume encoded data is valid
        // Or re-add validation if needed
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pattern, forKey: .pattern)
        try container.encode(directObjectConditions.rawValue, forKey: .directObjectConditionsRawValue)
        try container.encode(indirectObjectConditions.rawValue, forKey: .indirectObjectConditionsRawValue)
    }

    /// Creates a `SyntaxRule` with the given sequence of `SyntaxTokenType`s and default
    /// (empty) conditions for objects, and no required preposition.
    ///
    /// This is a convenience initializer for simple patterns.
    /// Example: `SyntaxRule(.verb, .directObject)`
    ///
    /// - Parameter pattern: A variadic list of `SyntaxTokenType`s defining the rule's structure.
    public init(_ pattern: SyntaxTokenType...) {
        self = .init(pattern: pattern)
    }

    /// Creates a `SyntaxRule` with a specific pattern and optional conditions for objects
    /// and a required preposition.
    ///
    /// - Parameters:
    ///   - pattern: An array of `SyntaxTokenType`s defining the rule's structure.
    ///   - directObjectConditions: Conditions the direct object must meet. Defaults to `.none`.
    ///   - indirectObjectConditions: Conditions the indirect object must meet. Defaults to `.none`.
    public init(
        pattern: [SyntaxTokenType],
        directObjectConditions: ObjectCondition = .none,
        indirectObjectConditions: ObjectCondition = .none
    ) {
        self.pattern = pattern
        self.directObjectConditions = directObjectConditions
        self.indirectObjectConditions = indirectObjectConditions
    }
}
