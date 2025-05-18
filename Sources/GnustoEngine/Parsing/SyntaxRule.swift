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
/// - `SyntaxRule(.verb, .directObject, .preposition, .indirectObject)` for "PUT APPLE IN BAG",
///   with `requiredPreposition: "in"`.
///
/// Game developers typically define these rules implicitly when creating `VerbDefinition`s
/// using convenience initializers, or explicitly if more control over the grammar is needed.
public struct SyntaxRule: Sendable, Equatable, Codable {
    /// The sequence of `SyntaxTokenType`s that define the grammatical structure of this rule.
    /// For example, `[.verb, .directObject]` or `[.verb, .directObject, .preposition, .indirectObject]`.
    public let pattern: [SyntaxTokenType]

    /// A set of `ObjectCondition`s that the direct object (if specified by `.directObject`
    /// in the `pattern`) must satisfy for this rule to match. For instance, it might
    /// need to be `.held` by the player or be a `.container`.
    public let directObjectConditions: ObjectCondition

    /// A set of `ObjectCondition`s that the indirect object (if specified by `.indirectObject`
    /// in the `pattern`) must satisfy. Similar to `directObjectConditions`.
    public let indirectObjectConditions: ObjectCondition

    /// If the `pattern` includes `.preposition`, this property specifies the exact
    /// preposition string (e.g., "in", "on", "with") that must be present in the player's
    /// input for this rule to match. It is `nil` if no specific preposition is required
    /// or if the pattern doesn't include `.preposition`.
    public let requiredPreposition: String? // Store the string, not PrepositionID

    // Explicit Codable conformance
    enum CodingKeys: String, CodingKey {
        case pattern
        case directObjectConditionsRawValue // Encode/decode rawValue
        case indirectObjectConditionsRawValue // Encode/decode rawValue
        case requiredPreposition
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pattern = try container.decode([SyntaxTokenType].self, forKey: .pattern)
        let doRawValue = try container.decode(Int.self, forKey: .directObjectConditionsRawValue)
        directObjectConditions = ObjectCondition(rawValue: doRawValue)
        let ioRawValue = try container.decode(Int.self, forKey: .indirectObjectConditionsRawValue)
        indirectObjectConditions = ObjectCondition(rawValue: ioRawValue)
        requiredPreposition = try container.decodeIfPresent(String.self, forKey: .requiredPreposition)

        // Initialize without validation, assume encoded data is valid
        // Or re-add validation if needed
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pattern, forKey: .pattern)
        try container.encode(directObjectConditions.rawValue, forKey: .directObjectConditionsRawValue)
        try container.encode(indirectObjectConditions.rawValue, forKey: .indirectObjectConditionsRawValue)
        try container.encodeIfPresent(requiredPreposition, forKey: .requiredPreposition)
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
    ///   - requiredPreposition: The specific preposition string required if the pattern
    ///                        includes `.preposition`. Defaults to `nil`.
    public init(
        pattern: [SyntaxTokenType],
        directObjectConditions: ObjectCondition = .none,
        indirectObjectConditions: ObjectCondition = .none,
        requiredPreposition: String? = nil
    ) {
        self.pattern = pattern
        self.directObjectConditions = directObjectConditions
        self.indirectObjectConditions = indirectObjectConditions
        self.requiredPreposition = requiredPreposition

        // Validation: Ensure preposition is only required if pattern contains .preposition
        if !pattern.contains(.preposition) && requiredPreposition != nil {
             assertionFailure("SyntaxRule created with requiredPreposition but no .preposition in pattern: \(pattern)")
        }
         if pattern.contains(.preposition) && requiredPreposition == nil {
             assertionFailure("SyntaxRule created with .preposition in pattern but no requiredPreposition string: \(pattern)")
        }
    }
}

/// Represents the type of a token expected at a specific position within a `SyntaxRule`'s pattern.
///
/// Each case defines a category of word or phrase the parser looks for when trying to match
/// player input against a known grammatical structure.
public enum SyntaxTokenType: Sendable, Equatable, Codable {
    /// Expects the main verb of the command (e.g., "TAKE", "GO", "LOOK").
    /// This is typically the first significant token matched by the parser.
    case verb
    /// Expects a noun phrase that will be identified as the direct object of the verb
    /// (e.g., the "APPLE" in "TAKE APPLE").
    case directObject
    /// Expects a noun phrase that will be identified as the indirect object of the verb
    /// (e.g., the "BAG" in "PUT APPLE IN BAG").
    case indirectObject
    /// Expects a preposition (e.g., "IN", "ON", "WITH"). If the `SyntaxRule` has a
    /// `requiredPreposition`, this token must match that specific preposition. Otherwise,
    /// it can match any preposition known in the game's `Vocabulary`.
    case preposition // Matches any known preposition unless SyntaxRule specifies one
    /// Expects a word indicating a direction of movement (e.g., "NORTH", "UP", "WEST").
    case direction   // Matches a known direction word (e.g., "north", "n")
    /// Expects a specific particle word that is part of a phrasal verb or special command
    /// syntax (e.g., the "ON" in "TURN LIGHT ON", or "ABOUT" in "THINK ABOUT TOPIC").
    /// The associated `String` value is the exact particle word expected.
    case particle(String) // Matches a specific particle word (e.g., "on", "off")

    // Manual Equatable for associated value
    public static func == (lhs: SyntaxTokenType, rhs: SyntaxTokenType) -> Bool {
        switch (lhs, rhs) {
        case (.verb, .verb),
             (.directObject, .directObject),
             (.indirectObject, .indirectObject),
             (.preposition, .preposition),
             (.direction, .direction):
            return true
        case (.particle(let lhsValue), .particle(let rhsValue)):
            return lhsValue == rhsValue
        default:
            return false
        }
    }

    // Manual Codable implementation due to associated value
    enum CodingKeys: String, CodingKey {
        case caseName
        case associatedValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let caseName = try container.decode(String.self, forKey: .caseName)

        switch caseName {
        case "verb": self = .verb
        case "directObject": self = .directObject
        case "indirectObject": self = .indirectObject
        case "preposition": self = .preposition
        case "direction": self = .direction
        case "particle":
            let value = try container.decode(String.self, forKey: .associatedValue)
            self = .particle(value)
        default:
            throw DecodingError.dataCorruptedError(forKey: .caseName, in: container, debugDescription: "Unknown SyntaxTokenType case name: \(caseName)")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .verb: try container.encode("verb", forKey: .caseName)
        case .directObject: try container.encode("directObject", forKey: .caseName)
        case .indirectObject: try container.encode("indirectObject", forKey: .caseName)
        case .preposition: try container.encode("preposition", forKey: .caseName)
        case .direction: try container.encode("direction", forKey: .caseName)
        case .particle(let value):
            try container.encode("particle", forKey: .caseName)
            try container.encode(value, forKey: .associatedValue)
        }
    }
}
