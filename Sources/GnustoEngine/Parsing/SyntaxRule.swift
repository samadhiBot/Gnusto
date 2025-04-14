import Foundation

/// Represents a specific syntax pattern for a verb.
public struct SyntaxRule: Sendable, Equatable, Codable {
    /// The sequence of expected token types in the pattern.
    public let pattern: [SyntaxTokenType]

    /// Conditions required for the direct object, if present in the pattern.
    public let directObjectConditions: ObjectCondition

    /// Conditions required for the indirect object, if present in the pattern.
    public let indirectObjectConditions: ObjectCondition

    /// The specific preposition expected, if the pattern includes `.preposition`.
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

/// Represents the type of element expected at a position in a SyntaxRule pattern.
public enum SyntaxTokenType: String, Sendable, Equatable, Codable {
    case verb
    case directObject
    case indirectObject
    case preposition // Matches any known preposition unless SyntaxRule specifies one
    case direction   // Matches a known direction word (e.g., "north", "n")
    // Add others like .topic, .string, .number later?
}
