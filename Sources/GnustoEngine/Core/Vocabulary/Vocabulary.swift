/// Holds the game's vocabulary, mapping words to game entities and concepts.
public struct Vocabulary: Codable, Sendable {
    // MARK: - Properties

    /// Maps VerbIDs to their full definitions (including synonyms, syntax, requiresLight).
    public var verbDefinitions: [VerbID: Verb]

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

    /// Maps direction words (and abbreviations) to their canonical Direction.
    /// Example: `["north": .north, "n": .north, "up": .up]`
    public var directions: [String: Direction]

    /// Computed property to get the verb synonym mapping needed by the parser.
    public var verbSynonyms: [String: VerbID] {
        var mapping: [String: VerbID] = [:]
        for verb in verbDefinitions.values {
            // Map the primary ID
            mapping[verb.id.rawValue.lowercased()] = verb.id
            // Map all synonyms
            for synonym in verb.synonyms {
                mapping[synonym.lowercased()] = verb.id
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
        directions: [String: Direction] = [:],
        noiseWords: Set<String> = Vocabulary.defaultNoiseWords,
        prepositions: Set<String> = Vocabulary.defaultPrepositions,
        pronouns: Set<String> = Vocabulary.defaultPronouns
    ) {
        self.verbDefinitions = verbDefinitions // Assign new dictionary
        self.items = items
        self.adjectives = adjectives
        self.directions = directions
        self.noiseWords = noiseWords
        self.prepositions = prepositions
        self.pronouns = pronouns
    }

    // MARK: - Default Definitions

    /// Default set of common English noise words.
    public static let defaultNoiseWords: Set<String> = [
        "a", "an", "and", "the", "some", "this", "that", "those", "these",
        ".", ",", "!", "?", ";", ":", "'", "\"", "(", ")"
        // Removed: "at", "in", "on", "to", "of", "with" - These are important prepositions/directions
        // Note: "on" and "off" are NOT noise words here as they are significant particles.
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
        Verb(
            id: "look",
            synonyms: ["l"],
            syntax: [
                SyntaxRule(.verb),
                SyntaxRule(.verb, .directObject) // Added rule for look <item>
            ],
            requiresLight: false // LOOK works in the dark (prints dark message)
        ),
        Verb(
            id: "examine",
            synonyms: ["x", "inspect"],
            syntax: [SyntaxRule(.verb, .directObject)],
            requiresLight: true // EXAMINE requires light
        ), // Examine needs DO
        Verb(
            id: "inventory",
            synonyms: ["i"],
            syntax: [SyntaxRule(.verb)],
            requiresLight: false // Inventory check works in the dark
        ),
        Verb(
            id: "quit",
            synonyms: ["q"],
            syntax: [SyntaxRule(.verb)],
            requiresLight: false // Quitting works in the dark
        ),
        Verb(
            id: "score",
            syntax: [SyntaxRule(.verb)],
            requiresLight: false // Checking score works in the dark
        ),
        Verb(
            id: "wait",
            synonyms: ["z"],
            syntax: [SyntaxRule(.verb)],
            requiresLight: false // Waiting works in the dark
        ),

        // Movement
        Verb(
            id: "go",
            synonyms: ["move", "walk", "run", "proceed"],
            syntax: [SyntaxRule(.verb, .direction)],
            requiresLight: false // Movement attempt works in dark (might fail)
        ), // Default takes direction
        // Note: Single directions (N, S, E, W...) handled separately by StandardParser

        // Common Interactions
        Verb(
            id: "take",
            synonyms: ["get", "grab", "pick"],
            syntax: [SyntaxRule(.verb, .directObject)]
        ),
        Verb(
            id: "put",
            synonyms: ["place", "hang"],
            // Corrected: Only place is a reasonable synonym
            syntax: [
                // Define rules for PUT/PLACE: V+DO+PREP+IO
                // put <DO> in <IO> - DO must be reachable, IO must be a container
                // put <DO> into <IO> - Same as 'in'
                SyntaxRule(
                    pattern: [.verb, .directObject, .preposition, .indirectObject],
                    // Must be reachable (default), .takable checked by action
                    indirectObjectConditions: [.container],
                    // IO must be a container
                    requiredPreposition: "in"
                ),
                SyntaxRule(
                    pattern: [.verb, .directObject, .preposition, .indirectObject],
                    // Must be reachable (default), .takable checked by action
                    indirectObjectConditions: [.container],
                    // IO must be a container
                    requiredPreposition: "into"
                ),
                // put <DO> on <IO> - DO must be reachable, IO must be a surface (checked by action)
                // put <DO> into <IO> - Same as 'in'
                SyntaxRule(
                    pattern: [.verb, .directObject, .preposition, .indirectObject],
                    // IO must be reachable surface (action checks property)
                    requiredPreposition: "on"
                ),
            ]
        ),
        // put <DO> into <IO> - Same as 'in'
        Verb(
            id: "drop",
            synonyms: ["discard"],
            // Corrected: Removed put, place
            syntax: [SyntaxRule(.verb, .directObject)]
        ), // Simple drop syntax
        Verb(
            id: "open",
            syntax: [SyntaxRule(.verb, .directObject)]
        ),
        Verb(
            id: "close",
            synonyms: ["shut"],
            syntax: [SyntaxRule(.verb, .directObject)]
        ),
        Verb(
            id: "read",
            syntax: [SyntaxRule(.verb, .directObject)]
        ),
        Verb(
            id: "wear",
            synonyms: ["don", "put on"],
            // Added "put on"
            syntax: [SyntaxRule(.verb, .directObject)]
        ),
        Verb(
            id: "remove",
            synonyms: ["take off", "doff"],
            // Added "doff"
            syntax: [SyntaxRule(.verb, .directObject)],
            requiresLight: false // ADDED: Removing items works in the dark
        ), // For worn items
        // Light/Device Verbs (Note: Synonyms handle mapping multiple words to the same VerbID)
        Verb(
            id: "light",
            synonyms: ["illuminate"],
            // Direct mapping to turn_on
            syntax: [SyntaxRule(.verb, .directObject)]
        ),
        Verb(
            id: "extinguish",
            synonyms: ["douse"],
            // Direct mapping to turn_off
            syntax: [SyntaxRule(.verb, .directObject)]
        ),
        Verb(
            id: "blow",
            // Requires "out" particle
            syntax: [
                SyntaxRule(.verb, .particle("out"), .directObject),
                SyntaxRule(.verb, .directObject, .particle("out"))
            ]
        ),
        Verb(
            id: "turn",
            // Requires "on"/"off" particle
            syntax: [
                SyntaxRule(.verb, .particle("on"), .directObject),
                SyntaxRule(.verb, .directObject, .particle("on")),
                SyntaxRule(.verb, .particle("off"), .directObject),
                SyntaxRule(.verb, .directObject, .particle("off"))
            ]
        ),
        Verb(
            id: "switch",
            // Requires "on"/"off" particle
            syntax: [
                SyntaxRule(.verb, .particle("on"), .directObject),
                SyntaxRule(.verb, .directObject, .particle("on")),
                SyntaxRule(.verb, .particle("off"), .directObject),
                SyntaxRule(.verb, .directObject, .particle("off"))
            ]
        ),

        // Sensory / Non-committal
        Verb(
            id: "smell",
            synonyms: ["sniff"],
            syntax: [
                SyntaxRule(.verb),
                SyntaxRule(.verb, .directObject)
            ],
            requiresLight: false // Smelling works in the dark
        ), // Smell or Smell X
        Verb(
            id: "listen",
            syntax: [
                SyntaxRule(.verb),
                SyntaxRule(.verb, .particle("to"), .directObject) // listen to <item>
            ],
            requiresLight: false // Listening works in the dark
        ),
        Verb(
            id: "taste",
            syntax: [SyntaxRule(.verb, .directObject)],
            requiresLight: true // Tasting requires light (to see what you're tasting)
        ),
        Verb(
            id: "touch",
            synonyms: ["feel"],
            syntax: [SyntaxRule(.verb, .directObject)],
            requiresLight: true // Touching likely requires seeing the item
        ),

        // Think About (from Cloak of Darkness)
        Verb(
            id: "think-about", // Use hyphenated ID for consistency
            synonyms: ["contemplate", "think about"], // Add synonym from CoD and the multi-word phrase itself
            syntax: [SyntaxRule(.verb, .directObject)],
            requiresLight: false // Thinking works in the dark
        ),

        // Meta
        Verb(
            id: "help",
            syntax: [SyntaxRule(.verb)],
            requiresLight: false
        ),
        Verb(
            id: "save",
            syntax: [SyntaxRule(.verb)],
            requiresLight: false
        ),
        Verb(
            id: "restore",
            synonyms:["load"],
            syntax: [SyntaxRule(.verb)],
            requiresLight: false
        ),
        Verb(
            id: "verbose",
            syntax: [SyntaxRule(.verb)],
            requiresLight: false
        ),
        Verb(
            id: "brief",
            syntax: [SyntaxRule(.verb)],
            requiresLight: false
        ), // Often used for description detail

        // Lock/Unlock Verbs
        Verb(
            id: "lock",
            syntax: [
                SyntaxRule(
                    pattern: [.verb, .directObject, .preposition, .indirectObject],
                    requiredPreposition: "with"
                )
            ]
        ),
        Verb(
            id: "unlock",
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
    @MainActor public static func build(
        items: [Item],
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

        // Add game-specific items
        for item in items {
            vocab.add(item: item)
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
            "in": .in, // Note: 'in' is already a preposition, parser needs to handle ambiguity
            "out": .out
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
        try container.encode(noiseWords, forKey: .noiseWords)
        try container.encode(prepositions, forKey: .prepositions)
        try container.encode(pronouns, forKey: .pronouns)
        try container.encode(directions, forKey: .directions)
    }
}
