/// Represents a recognized verb in the game's command vocabulary.
public struct Verb: Codable, Identifiable {
    /// The unique identifier for this verb (e.g., "take").
    public let id: VerbID

    /// Synonyms used to invoke this verb (e.g., ["get", "pick up"]).
    /// The `id` itself should also be considered a primary way to invoke the verb.
    public var synonyms: Set<String>

    /// The defined syntax patterns for this verb.
    public var syntax: [SyntaxRule]

    // --- Initialization ---
    public init(
        id: VerbID,
        synonyms: String...,
        syntax: [SyntaxRule] = []
    ) {
        self.id = id
        self.synonyms = Set(synonyms)
        self.syntax = syntax
    }

    init(
        id: VerbID,
        synonyms: Set<String> = [],
        syntax: [SyntaxRule] = []
    ) {
        self.id = id
        self.synonyms = synonyms
        self.syntax = syntax
    }

    enum CodingKeys: String, CodingKey {
        case id
        case synonyms
        case syntax
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(VerbID.self, forKey: .id)
        synonyms = try container.decode(Set<String>.self, forKey: .synonyms)
        syntax = try container.decode([SyntaxRule].self, forKey: .syntax)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(synonyms, forKey: .synonyms)
        try container.encode(syntax, forKey: .syntax)
    }
}
