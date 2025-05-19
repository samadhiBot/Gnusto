/// Represents a recognized verb in the game's command vocabulary.
public struct Verb: Codable, Equatable, Identifiable, Sendable {
    /// The unique identifier for this verb (e.g., "take").
    public let id: VerbID

    /// Synonyms used to invoke this verb (e.g., ["get", "pick up"]).
    /// The `id` itself should also be considered a primary way to invoke the verb.
    public var synonyms: Set<String>

    /// The defined syntax patterns for this verb.
    public var syntax: [SyntaxRule]

    /// Indicates whether this verb's action typically requires light to perform.
    /// Defaults to `true` for most interactive verbs.
    public var requiresLight: Bool

    // --- Initialization ---
    public init(
        id: VerbID,
        synonyms: String...,
        syntax: [SyntaxRule] = [],
        requiresLight: Bool = true // Default to true
    ) {
        self.id = id
        self.synonyms = Set(synonyms)
        self.syntax = syntax
        self.requiresLight = requiresLight
    }

    enum CodingKeys: String, CodingKey {
        case id
        case synonyms
        case syntax
        case requiresLight
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(VerbID.self, forKey: .id)
        synonyms = try container.decode(Set<String>.self, forKey: .synonyms)
        syntax = try container.decodeIfPresent([SyntaxRule].self, forKey: .syntax) ?? [] // Default to empty syntax
        // Decode requiresLight, defaulting to true if missing for backward compatibility
        requiresLight = try container.decodeIfPresent(Bool.self, forKey: .requiresLight) ?? true
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(synonyms, forKey: .synonyms)
        try container.encode(syntax, forKey: .syntax)
        // Only encode requiresLight if it's false (to keep JSON smaller for the common case)
        if !requiresLight {
            try container.encode(requiresLight, forKey: .requiresLight)
        }
    }
}
