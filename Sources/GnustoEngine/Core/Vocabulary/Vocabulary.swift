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

    /// Common prepositions used to separate objects (e.g., "put X IN Y").
    public var prepositions: Set<String>

    /// Common pronouns handled by the parser.
    public var pronouns: Set<String>

    /// Maps direction words (and abbreviations) to their canonical Direction.
    /// Example: `["north": .north, "n": .north, "up": .up]`
    public var directions: [String: Direction]

    /// Computed property to get the verb synonym mapping needed by the parser.
    /// Maps a synonym string (lowercase) to the Set of VerbIDs it can represent.
    public var verbSynonyms: [String: Set<VerbID>] {
        var mapping: [String: Set<VerbID>] = [:]
        for verb in verbDefinitions.values {
            let verbID = verb.id
            let primaryKey = verbID.rawValue.lowercased()
            // Map the primary ID
            mapping[primaryKey, default: Set()].insert(verbID)
            // Map all synonyms
            for synonym in verb.synonyms {
                let synonymKey = synonym.lowercased()
                mapping[synonymKey, default: Set()].insert(verbID) // Insert instead of overwrite
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
        pronouns: Set<String> = Vocabulary.defaultPronouns
    ) {
        self.verbDefinitions = verbDefinitions // Assign new dictionary
        self.items = items
        self.adjectives = adjectives
        self.locationNames = locationNames // Assign new property
        self.directions = directions
        self.noiseWords = noiseWords
        self.prepositions = prepositions
        self.pronouns = pronouns
    }

    // MARK: - Default Definitions

    /// Default set of common English noise words.
    public static let defaultNoiseWords: Set<String> = [
        "!",
        "'",
        "(",
        ")",
        ",",
        ".",
        ":",
        ";",
        "?",
        "\"",
        "a",
        "an",
        "and",
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
        "behind",
        "down",
        "for",
        "from",
        "in",
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

    /// Default verbs common to most IF games.
    public static let defaultVerbs: [Verb] = [
        // Core Actions

        Verb(
            id: .look,
            synonyms: "l",
            syntax: [
                SyntaxRule(.verb),
                SyntaxRule(.verb, .directObject)
            ],
            requiresLight: false
        ),

        Verb(
            id: .examine,
            synonyms: "x", "inspect",
            syntax: [SyntaxRule(.verb, .directObject)],
            requiresLight: true
        ),

        Verb(
            id: .inventory,
            synonyms: "i",
            syntax: [SyntaxRule(.verb)],
            requiresLight: false
        ),

        Verb(
            id: .quit,
            synonyms: "q",
            syntax: [SyntaxRule(.verb)],
            requiresLight: false
        ),

        Verb(
            id: .score,
            syntax: [SyntaxRule(.verb)],
            requiresLight: false
        ),

        Verb(
            id: .wait,
            synonyms: "z",
            syntax: [SyntaxRule(.verb)],
            requiresLight: false
        ),

        // Movement
        // Note: Single directions (N, S, E, W...) handled separately by StandardParser

        Verb(
            id: .go,
            synonyms: "move", "walk", "run", "proceed",
            syntax: [SyntaxRule(.verb, .direction)],
            requiresLight: false
        ),

        // Common Interactions

        Verb(
            id: .take,
            synonyms: "get", "grab", "pick",
            syntax: [SyntaxRule(.verb, .directObject)]
        ),

        Verb(
            id: .insert,
            synonyms: "put", "place",
            syntax: [
                SyntaxRule(
                    pattern: [.verb, .directObject, .preposition, .indirectObject],
                    requiredPreposition: "in"
                ),
                SyntaxRule(
                    pattern: [.verb, .directObject, .preposition, .indirectObject],
                    requiredPreposition: "into"
                ),
            ],
            requiresLight: true
        ),

        Verb(
            id: .putOn,
            synonyms: "hang", "put", "place", "set",
            syntax: [
                SyntaxRule(
                    pattern: [.verb, .directObject, .preposition, .indirectObject],
                    requiredPreposition: "on"
                ),
                SyntaxRule(
                    pattern: [.verb, .directObject, .preposition, .indirectObject],
                    requiredPreposition: "onto"
                ),
            ],
            requiresLight: true
        ),

        Verb(
            id: .drop,
            synonyms: "discard",
            syntax: [SyntaxRule(.verb, .directObject)]
        ),
        Verb(
            id: .open,
            syntax: [SyntaxRule(.verb, .directObject)]
        ),

        Verb(
            id: .close,
            synonyms: "shut",
            syntax: [SyntaxRule(.verb, .directObject)]
        ),

        Verb(
            id: .read,
            syntax: [SyntaxRule(.verb, .directObject)]
        ),

        Verb(
            id: .wear,
            synonyms: "don", "put on",
            syntax: [SyntaxRule(.verb, .directObject)]
        ),

        Verb(
            id: .remove,
            synonyms: "take off", "doff",
            syntax: [SyntaxRule(.verb, .directObject)],
            requiresLight: false
        ),

        Verb(
            id: .turnOn,
            synonyms: "light", "switch on", "turn on",
            syntax: [SyntaxRule(.verb, .directObject)],
            requiresLight: true
        ),

        Verb(
            id: .turnOff,
            synonyms: "extinguish", "douse", "switch off", "blow out", "turn off",
            syntax: [SyntaxRule(.verb, .directObject)],
            requiresLight: true
        ),

        // Sensory / Non-committal

        Verb(
            id: .smell,
            synonyms: "sniff",
            syntax: [
                SyntaxRule(.verb),
                SyntaxRule(.verb, .directObject)
            ],
            requiresLight: false
        ),

        Verb(
            id: .listen,
            syntax: [
                SyntaxRule(.verb),
                SyntaxRule(.verb, .particle("to"), .directObject)
            ],
            requiresLight: false
        ),

        Verb(
            id: .taste,
            syntax: [SyntaxRule(.verb, .directObject)],
            requiresLight: true
        ),

        Verb(
            id: .touch,
            synonyms: "feel",
            syntax: [SyntaxRule(.verb, .directObject)],
            requiresLight: true
        ),

        // Think About (from Cloak of Darkness)

        Verb(
            id: .thinkAbout,
            synonyms: "contemplate", "think about",
            syntax: [SyntaxRule(.verb, .directObject)],
            requiresLight: false
        ),

        // Meta
        Verb(
            id: .help,
            syntax: [SyntaxRule(.verb)],
            requiresLight: false
        ),

        Verb(
            id: .save,
            syntax: [SyntaxRule(.verb)],
            requiresLight: false
        ),

        Verb(
            id: .restore,
            synonyms: "load",
            syntax: [SyntaxRule(.verb)],
            requiresLight: false
        ),

        Verb(
            id: .verbose,
            syntax: [SyntaxRule(.verb)],
            requiresLight: false
        ),

        Verb(
            id: .brief,
            syntax: [SyntaxRule(.verb)],
            requiresLight: false
        ),

        // Lock/Unlock Verbs

        Verb(
            id: .lock,
            syntax: [
                SyntaxRule(
                    pattern: [.verb, .directObject, .preposition, .indirectObject],
                    requiredPreposition: "with"
                )
            ]
        ),

        Verb(
            id: .unlock,
            syntax: [
                SyntaxRule(
                    pattern: [.verb, .directObject, .preposition, .indirectObject],
                    requiredPreposition: "with"
                )
            ]
        ),
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

        // Add name, ID, and synonyms as potential nouns
        self.items[lowercasedName, default: []].insert(itemID)
        self.items[lowercasedID, default: []].insert(itemID) // Add item ID
        for synonym in item.synonyms {
            self.items[synonym.lowercased(), default: []].insert(itemID)
        }
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

    /// Builds a basic vocabulary from arrays of items and verbs, including standard directions
    /// and optionally including default verbs.
    /// - Parameters:
    ///   - items: An array of `Item` objects specific to the game.
    ///   - locations: An array of `Location` objects specific to the game.
    ///   - verbs: An array of `Verb` objects specific to the game (can override defaults).
    ///   - useDefaultVerbs: If true, includes the `Vocabulary.defaultVerbs`.
    /// - Returns: A populated `Vocabulary` instance.
    public static func build(
        items: [Item],
        locations: [Location],
        verbs: [Verb] = [],
        useDefaultVerbs: Bool = true
    ) -> Vocabulary {
        var vocab = Vocabulary()

        // Add default verbs first if requested
        if useDefaultVerbs {
            for verb in Vocabulary.defaultVerbs {
                vocab.add(verb: verb) // Uses the updated add(verb:)
            }
        }

        #if DEBUG
        vocab.add(
            verb: Verb(
                id: .debug,
                syntax: [SyntaxRule(.verb, .directObject)],
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
        // Add game-specific verbs (allowing overrides of defaults)
        for verb in verbs {
            vocab.add(verb: verb) // Uses the updated add(verb:)
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
        case prepositions
        case pronouns
        case directions
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
        prepositions = try container.decode(Set<String>.self, forKey: .prepositions)
        pronouns = try container.decode(Set<String>.self, forKey: .pronouns)
        directions = try container.decode([String: Direction].self, forKey: .directions)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(verbDefinitions, forKey: .verbDefinitions)
        try container.encode(items, forKey: .items)
        try container.encode(adjectives, forKey: .adjectives)
        try container.encode(locationNames, forKey: .locationNames) // Encode new property
        try container.encode(noiseWords, forKey: .noiseWords)
        try container.encode(prepositions, forKey: .prepositions)
        try container.encode(pronouns, forKey: .pronouns)
        try container.encode(directions, forKey: .directions)
    }
}
