/// Holds the game's vocabulary, mapping words to game entities and concepts.
public struct Vocabulary: Codable {
    // MARK: - Properties

    /// Maps known verbs (including synonyms) to their canonical VerbID.
    /// Example: `["take": "take", "get": "take", "look": "look"]`
    public var verbs: [String: VerbID]

    /// Maps known nouns (including synonyms) to the Set of ItemIDs they can refer to.
    /// Example: `["lantern": ["lantern", "lantern2"], "lamp": ["lantern", "lantern2"]]`
    public var items: [String: Set<ItemID>]

    /// Maps known adjectives to the set of ItemIDs they can describe.
    /// Example: `["brass": ["lantern", "hook"], "rusty": ["knife"]]`
    public var adjectives: [String: Set<ItemID>]

    /// A set of "noise" words to be ignored by the parser (articles, punctuation, etc.).
    /// Example: `["a", "an", "the", ".", ","]`
    public var noiseWords: Set<String>

    /// Common prepositions used to separate objects (e.g., "put X IN Y").
    public var prepositions: Set<String>

    /// Common pronouns handled by the parser.
    public var pronouns: Set<String>

    /// Maps VerbIDs to the list of syntax rules they accept.
    public var syntaxRules: [VerbID: [SyntaxRule]]

    /// Maps direction words (and abbreviations) to their canonical Direction.
    /// Example: `["north": .north, "n": .north, "up": .up]`
    public var directions: [String: Direction]

    // MARK: - Initialization

    /// Initializes an empty vocabulary, using default noise words, prepositions, and pronouns.
    public init() {
        self.verbs = [:]
        self.items = [:]
        self.adjectives = [:]
        self.noiseWords = Vocabulary.defaultNoiseWords
        self.prepositions = Vocabulary.defaultPrepositions
        self.pronouns = Vocabulary.defaultPronouns
        self.syntaxRules = [:]
        self.directions = [:]
    }

    /// Initializes a vocabulary with pre-populated dictionaries and sets.
    public init(
        verbs: [String: VerbID] = [:],
        items: [String: Set<ItemID>] = [:],
        adjectives: [String: Set<ItemID>] = [:],
        syntaxRules: [VerbID: [SyntaxRule]] = [:],
        directions: [String: Direction] = [:],
        noiseWords: Set<String> = Vocabulary.defaultNoiseWords,
        prepositions: Set<String> = Vocabulary.defaultPrepositions,
        pronouns: Set<String> = Vocabulary.defaultPronouns
    ) {
        self.verbs = verbs
        self.items = items
        self.adjectives = adjectives
        self.syntaxRules = syntaxRules
        self.directions = directions
        self.noiseWords = noiseWords
        self.prepositions = prepositions
        self.pronouns = pronouns
    }

    // MARK: - Default Definitions

    /// Default set of common English noise words.
    public static let defaultNoiseWords: Set<String> = [
        "a", "an", "and", "the", "some", "this", "that", "those", "these",
        ".", ",", "!", "?", ";", ":", "'", "\"", "(", ")",
        "at", "in", "on", "to", "of", "with", // Add common prepositions often treated as noise
    ]

    /// Default set of common English prepositions.
    public static let defaultPrepositions: Set<String> = [
        "in", "on", "under", "into", "onto", "through", "behind", "over", "with", "about", "for", "from", "to", "up", "down" // Added up/down
        // Note: Some might also be noise words, parser needs to handle context.
    ]

    /// Default set of common English pronouns.
    public static let defaultPronouns: Set<String> = [
        "it", "them"
    ]

    /// Default verbs common to most IF games.
    @MainActor public static let defaultVerbs: [Verb] = [
        // Core Actions
        Verb(id: "look", synonyms: ["l"], syntax: [SyntaxRule(pattern: [.verb])]),
        Verb(id: "examine", synonyms: ["x", "inspect"], syntax: [SyntaxRule(pattern: [.verb, .directObject])]), // Examine needs DO
        Verb(id: "inventory", synonyms: ["i"], syntax: [SyntaxRule(pattern: [.verb])]),
        Verb(id: "quit", synonyms: ["q"], syntax: [SyntaxRule(pattern: [.verb])]),
        Verb(id: "score", syntax: [SyntaxRule(pattern: [.verb])]),
        Verb(id: "wait", synonyms: ["z"], syntax: [SyntaxRule(pattern: [.verb])]),

        // Movement
        Verb(id: "go", synonyms: ["move", "walk", "run", "proceed"], syntax: [SyntaxRule(pattern: [.verb, .direction])]), // Default takes direction
        // Note: Single directions (N, S, E, W...) handled separately by StandardParser

        // Common Interactions (often need specific handlers, but define verb)
        Verb(id: "take", synonyms: ["get", "grab", "pick"], syntax: [SyntaxRule(pattern: [.verb, .directObject])]),
        Verb(id: "drop", synonyms: ["put", "place", "discard"], syntax: [SyntaxRule(pattern: [.verb, .directObject])]), // Simple drop syntax
        // TODO: Add rules for DROP X ON Y, PUT X IN Y, etc.
        Verb(id: "open", syntax: [SyntaxRule(pattern: [.verb, .directObject])]),
        Verb(id: "close", synonyms: ["shut"], syntax: [SyntaxRule(pattern: [.verb, .directObject])]),
        Verb(id: "read", syntax: [SyntaxRule(pattern: [.verb, .directObject])]),
        Verb(id: "wear", syntax: [SyntaxRule(pattern: [.verb, .directObject])]),
        Verb(id: "remove", synonyms: ["take off"], syntax: [SyntaxRule(pattern: [.verb, .directObject])]), // For worn items

        // Sensory / Non-committal
        Verb(id: "smell", synonyms: ["sniff"], syntax: [SyntaxRule(pattern: [.verb]), SyntaxRule(pattern: [.verb, .directObject])]), // Smell or Smell X
        Verb(id: "listen", syntax: [SyntaxRule(pattern: [.verb])]),
        Verb(id: "taste", syntax: [SyntaxRule(pattern: [.verb, .directObject])]),
        Verb(id: "touch", synonyms: ["feel"], syntax: [SyntaxRule(pattern: [.verb, .directObject])]),

        // Meta
        Verb(id: "help", syntax: [SyntaxRule(pattern: [.verb])]),
        Verb(id: "save", syntax: [SyntaxRule(pattern: [.verb])]),
        Verb(id: "restore", synonyms:["load"], syntax: [SyntaxRule(pattern: [.verb])]),
        Verb(id: "verbose", syntax: [SyntaxRule(pattern: [.verb])]),
        Verb(id: "brief", syntax: [SyntaxRule(pattern: [.verb])]), // Often used for description detail
    ]

    // MARK: - Building Vocabulary (Example Methods)

    /// Adds a verb, its synonyms, and its syntax rules to the vocabulary.
    /// - Parameter verb: The `Verb` object to add.
    public mutating func add(verb: Verb) {
        self.verbs[verb.id.rawValue] = verb.id
        for synonym in verb.synonyms {
            self.verbs[synonym.lowercased()] = verb.id
        }
        if !verb.syntax.isEmpty {
            self.syntaxRules[verb.id, default: []].append(contentsOf: verb.syntax)
        }
    }

    /// Adds an item, its synonyms, and its adjectives to the vocabulary.
    /// - Parameter item: The `Item` object to add.
    public mutating func add(item: Item) {
        let itemID = item.id
        let lowercasedName = item.name.lowercased()
        self.items[lowercasedName, default: []].insert(itemID)
        for synonym in item.synonyms {
            self.items[synonym.lowercased(), default: []].insert(itemID)
        }
        for adjective in item.adjectives {
            let lowercasedAdj = adjective.lowercased()
            self.adjectives[lowercasedAdj, default: []].insert(itemID)
        }
    }

    /// Builds a basic vocabulary from arrays of items and verbs, including standard directions
    /// and optionally including default verbs.
    /// - Parameters:
    ///   - items: An array of `Item` objects specific to the game.
    ///   - verbs: An array of `Verb` objects specific to the game (can override defaults).
    ///   - useDefaultVerbs: If true, includes the `Vocabulary.defaultVerbs`.
    /// - Returns: A populated `Vocabulary` instance.
    @MainActor public static func build(items: [Item], verbs: [Verb], useDefaultVerbs: Bool = true) -> Vocabulary {
        var vocab = Vocabulary()

        // Add default verbs first if requested
        if useDefaultVerbs {
            for verb in Vocabulary.defaultVerbs {
                vocab.add(verb: verb)
            }
        }

        // Add game-specific items
        for item in items {
            vocab.add(item: item)
        }
        // Add game-specific verbs (allowing overrides of defaults)
        for verb in verbs {
            vocab.add(verb: verb)
        }

        // Add standard directions
        vocab.addStandardDirections()

        return vocab
    }

    // MARK: - Helper Methods

    /// Adds standard English directions and abbreviations to the vocabulary.
    mutating func addStandardDirections() {
        directions = [
            "north": .north, "n": .north,
            "south": .south, "s": .south,
            "east": .east, "e": .east,
            "west": .west, "w": .west,
            "northeast": .northeast, "ne": .northeast,
            "northwest": .northwest, "nw": .northwest,
            "southeast": .southeast, "se": .southeast,
            "southwest": .southwest, "sw": .southwest,
            "up": .up, "u": .up,
            "down": .down, "d": .down,
            "in": .in, // Note: 'in' is already a preposition, parser needs to handle ambiguity
            "out": .out
            // Add LAND? Might conflict with "land verb"
        ]
    }

    /// Checks if a given word is a known pronoun.
    public func isPronoun(_ word: String) -> Bool {
        return pronouns.contains(word.lowercased())
    }

    // Codable conformance
    // Synthesized conformance should work if all properties are Codable.
}
