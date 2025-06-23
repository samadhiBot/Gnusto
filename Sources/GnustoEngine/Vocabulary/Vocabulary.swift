/// Holds the game's vocabulary, mapping words to game entities and concepts.
public struct Vocabulary: Codable, Equatable, Sendable {
    // MARK: - Properties

    /// Maps VerbIDs to their full definitions (including synonyms, syntax, requiresLight).
    public var verbDefinitions: [VerbID: Verb]

    /// Maps known nouns (including synonyms) to the Set of ItemIDs they can refer to.
    /// Example: `["lantern": ["lantern", "lantern2"], "lamp": ["lantern", "lantern2"]]`
    public var items: [String: Set<ItemID>]

    /// Maps known adjectives to the set of ItemIDs they can describe.
    /// Example: `["brass": ["lantern", "hook"], "rusty": ["knife"]]`
    public var adjectives: [String: Set<ItemID>]

    /// Maps known location names to the LocationID they refer to.
    public var locationNames: [String: LocationID]

    /// A set of "noise" words to be ignored by the parser (articles, punctuation, etc.).
    /// Example: `["a", "an", "the", ".", ","]`
    public var noiseWords: Set<String>

    /// Common adverbs that can be ignored by the parser.
    /// These words are recognized but don't affect command processing.
    /// Example: `["carefully", "quickly", "slowly", "quietly"]`
    public var adverbs: Set<String>

    /// Common prepositions used to separate objects (e.g., "put X IN Y").
    public var prepositions: Set<String>

    /// Common pronouns handled by the parser.
    public var pronouns: Set<String>

    /// Maps direction words (and abbreviations) to their canonical Direction.
    /// Example: `["north": .north, "n": .north, "up": .up]`
    public var directions: [String: Direction]

    /// Special keywords that receive special parser treatment.
    /// These are not treated as regular nouns but trigger special parsing logic.
    /// Example: `["all", "everything", "each"]`
    public var specialKeywords: Set<String>

    /// Conjunctions used to connect multiple objects in commands.
    /// These words are used to parse commands like "TAKE SWORD AND LANTERN".
    /// Example: `["and", ","]`
    public var conjunctions: Set<String>

    /// Computed property to get the verb synonym mapping needed by the parser.
    /// Maps a synonym string (lowercase) to the Set of VerbIDs it can represent.
    /// When multiple verbs match, all potential matches are included so the parser can
    /// use syntax rules to determine the best match.
    public var verbSynonyms: [String: Set<VerbID>] {
        var mapping: [String: Set<VerbID>] = [:]

        // Build the mapping without prioritization - include all possible matches
        for verb in verbDefinitions.values {
            let verbID = verb.id
            let primaryKey = verbID.rawValue.lowercased()

            // Map the primary ID
            mapping[primaryKey, default: Set()].insert(verbID)

            // Map all synonyms - allow synonyms to coexist with exact ID matches
            for synonym in verb.synonyms {
                let synonymKey = synonym.lowercased()
                mapping[synonymKey, default: Set()].insert(verbID)
            }
        }
        return mapping
    }

    // MARK: - Initialization

    /// Initializes an empty vocabulary, using default noise words, prepositions, and pronouns.
    public init() {
        self.verbDefinitions = [:] // Initialize new dictionary
        self.items = [:]
        self.adjectives = [:]
        self.locationNames = [:] // Initialize new property
        self.noiseWords = Vocabulary.defaultNoiseWords
        self.prepositions = Vocabulary.defaultPrepositions
        self.pronouns = Vocabulary.defaultPronouns
        self.directions = [:]
        self.specialKeywords = Vocabulary.defaultSpecialKeywords
        self.conjunctions = Vocabulary.defaultConjunctions
        self.adverbs = Vocabulary.defaultAdverbs
    }

    /// Initializes a vocabulary with pre-populated dictionaries and sets.
    public init(
        verbDefinitions: [VerbID: Verb] = [:], // Use verbDefinitions
        items: [String: Set<ItemID>] = [:],
        adjectives: [String: Set<ItemID>] = [:],
        locationNames: [String: LocationID] = [:], // Added parameter
        directions: [String: Direction] = [:],
        noiseWords: Set<String> = Vocabulary.defaultNoiseWords,
        prepositions: Set<String> = Vocabulary.defaultPrepositions,
        pronouns: Set<String> = Vocabulary.defaultPronouns,
        specialKeywords: Set<String> = Vocabulary.defaultSpecialKeywords,
        conjunctions: Set<String> = Vocabulary.defaultConjunctions,
        adverbs: Set<String> = Vocabulary.defaultAdverbs
    ) {
        self.verbDefinitions = verbDefinitions // Assign new dictionary
        self.items = items
        self.adjectives = adjectives
        self.locationNames = locationNames // Assign new property
        self.directions = directions
        self.noiseWords = noiseWords
        self.prepositions = prepositions
        self.pronouns = pronouns
        self.specialKeywords = specialKeywords
        self.conjunctions = conjunctions
        self.adverbs = adverbs
    }

    // MARK: - Default Definitions

    /// Default set of common English noise words.
    public static let defaultNoiseWords: Set<String> = [
        "!",
        "'",
        "(",
        ")",
        ".",
        ":",
        ";",
        "?",
        "\"",
        "a",
        "an",
        "some",
        "that",
        "the",
        "these",
        "this",
        "those",
    ]

    /// Default set of common English prepositions.
    public static let defaultPrepositions: Set<String> = [
        "about",
        "at",
        "behind",
        "down",
        "for",
        "from",
        "in",
        "inside",
        "into",
        "on",
        "onto",
        "over",
        "through",
        "to",
        "under",
        "up",
        "with",
    ]

    /// Default set of common English pronouns.
    public static let defaultPronouns: Set<String> = [
        "it",
        "them"
    ]

    /// Default set of special keywords that receive special parser treatment.
    /// These words trigger special parsing logic rather than being treated as regular nouns.
    public static let defaultSpecialKeywords: Set<String> = [
        "all",
        "everything",
        "each"
    ]

    /// Default set of conjunctions used to connect multiple objects.
    /// These words are used to parse commands like "TAKE SWORD AND LANTERN".
    public static let defaultConjunctions: Set<String> = [
        "and",
        ","
    ]

    /// Default adverbs that can be ignored by the parser.
    /// These words are recognized but don't affect command processing.
    /// Example: `["carefully", "quickly", "slowly", "quietly"]`
    public static let defaultAdverbs: Set<String> = [
        "carefully",
        "gently",
        "loudly",
        "quietly",
        "quickly",
        "rapidly",
        "slowly",
        "softly",
        "thoroughly",
        "vigorously",
    ]

    // MARK: - Building Vocabulary

    /// Adds a verb definition to the vocabulary.
    /// - Parameter verb: The `Verb` object to add.
    public mutating func add(verb: Verb) {
        // Store the full verb definition under its ID
        self.verbDefinitions[verb.id] = verb
    }

    /// Adds an item, its synonyms, and its adjectives to the vocabulary.
    /// - Parameter item: The `Item` object to add.
    public mutating func add(item: Item) {
        let itemID = item.id
        let lowercasedName = item.name.lowercased()
        let lowercasedID = itemID.rawValue.lowercased()

        // Add full name as a potential noun (for multi-word names like "gold box")
        self.items[lowercasedName, default: []].insert(itemID)

        // Add individual words from multi-word names
        // This allows "box" to match "gold box" when used with proper modifiers
        let nameWords = lowercasedName.split(separator: " ").map(String.init)
        if nameWords.count > 1 {
            // For multi-word names, add the last word as the primary noun
            // and earlier words as potential adjectives
            if let lastWord = nameWords.last {
                self.items[lastWord, default: []].insert(itemID)
            }

            // Add earlier words as adjectives so they can be used as modifiers
            for word in nameWords.dropLast() {
                self.adjectives[word, default: []].insert(itemID)
            }
        }

        // Add item ID as a potential noun
        self.items[lowercasedID, default: []].insert(itemID)

        // Add synonyms as potential nouns
        for synonym in item.synonyms {
            let lowercasedSynonym = synonym.lowercased()
            self.items[lowercasedSynonym, default: []].insert(itemID)

            // Handle multi-word synonyms similarly
            let synonymWords = lowercasedSynonym.split(separator: " ").map(String.init)
            if synonymWords.count > 1 {
                if let lastWord = synonymWords.last {
                    self.items[lastWord, default: []].insert(itemID)
                }
                for word in synonymWords.dropLast() {
                    self.adjectives[word, default: []].insert(itemID)
                }
            }
        }

        // Add explicit adjectives
        for adjective in item.adjectives {
            let lowercasedAdj = adjective.lowercased()
            self.adjectives[lowercasedAdj, default: []].insert(itemID)
        }
    }

    /// Adds a location and its name to the vocabulary.
    /// - Parameter location: The `Location` object to add.
    public mutating func add(location: Location) {
        let locationID = location.id
        let lowercasedName = location.name.lowercased()
        let lowercasedID = locationID.rawValue.lowercased()

        self.locationNames[lowercasedName] = locationID
        self.locationNames[lowercasedID] = locationID
    }

    /// Builds a basic vocabulary from arrays of items and verbs, including standard directions.
    /// - Parameters:
    ///   - items: An array of `Item` objects specific to the game.
    ///   - locations: An array of `Location` objects specific to the game.
    ///   - verbs: An array of `Verb` objects specific to the game.
    /// - Returns: A populated `Vocabulary` instance.
    public static func build(
        items: [Item] = [],
        locations: [Location] = [],
        verbs: [Verb] = []
    ) -> Vocabulary {
        var vocab = Vocabulary()

        #if DEBUG

        vocab.add(
            verb: Verb(
                id: .debug,
                synonyms: "db",
                syntax: [
                    .match(.verb, .directObject)
                ],
                requiresLight: false
            )
        )

        #endif

        // Add game-specific items
        for item in items {
            vocab.add(item: item)
        }
        // Add game-specific locations
        for location in locations {
            vocab.add(location: location)
        }
        // Add game-specific verbs
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
            "in": .inside,
            "out": .outside
            // Add LAND? Might conflict with "land verb"
        ]
    }

    /// Checks if a given word is a known pronoun.
    public func isPronoun(_ word: String) -> Bool {
        return pronouns.contains(word.lowercased())
    }

    // MARK: - Codable Conformance

    enum CodingKeys: String, CodingKey {
        case verbDefinitions // Updated key
        case items
        case adjectives
        case locationNames // Added coding key
        case noiseWords
        case adverbs
        case prepositions
        case pronouns
        case directions
        case specialKeywords
        case conjunctions
        // Removed verbs, syntaxRules
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Decode verbDefinitions or default to empty
        verbDefinitions = try container.decodeIfPresent([VerbID: Verb].self, forKey: .verbDefinitions) ?? [:]
        items = try container.decode([String: Set<ItemID>].self, forKey: .items)
        adjectives = try container.decode([String: Set<ItemID>].self, forKey: .adjectives)
        locationNames = try container.decodeIfPresent([String: LocationID].self, forKey: .locationNames) ?? [:] // Decode new property
        noiseWords = try container.decode(Set<String>.self, forKey: .noiseWords)
        adverbs = try container.decode(Set<String>.self, forKey: .adverbs)
        prepositions = try container.decode(Set<String>.self, forKey: .prepositions)
        pronouns = try container.decode(Set<String>.self, forKey: .pronouns)
        directions = try container.decode([String: Direction].self, forKey: .directions)
        specialKeywords = try container.decode(Set<String>.self, forKey: .specialKeywords)
        conjunctions = try container.decodeIfPresent(Set<String>.self, forKey: .conjunctions) ?? Vocabulary.defaultConjunctions
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(verbDefinitions, forKey: .verbDefinitions)
        try container.encode(items, forKey: .items)
        try container.encode(adjectives, forKey: .adjectives)
        try container.encode(locationNames, forKey: .locationNames) // Encode new property
        try container.encode(noiseWords, forKey: .noiseWords)
        try container.encode(adverbs, forKey: .adverbs)
        try container.encode(prepositions, forKey: .prepositions)
        try container.encode(pronouns, forKey: .pronouns)
        try container.encode(directions, forKey: .directions)
        try container.encode(specialKeywords, forKey: .specialKeywords)
        try container.encode(conjunctions, forKey: .conjunctions)
    }
}
