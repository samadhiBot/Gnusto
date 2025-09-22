/// Holds the game's vocabulary, mapping words to game entities and concepts.
public struct Vocabulary: Equatable, Sendable {
    // MARK: - Properties

    /// Maps Verbs to their full definitions (including synonyms, syntax, requiresLight).
    public var verbs: [Verb]

    /// Maps verbs to their syntax rules from ActionHandlers.
    /// This is used by the parser to validate command structure.
    public var verbToSyntax: [Verb: [SyntaxRule]]

    /// Maps known nouns (including synonyms) to the Set of ItemIDs they can refer to.
    /// Example: `["lantern": ["lantern", "lantern2"], "lamp": ["lantern", "lantern2"]]`
    public var items: [String: Set<ItemID>]

    /// Maps known adjectives to the set of ItemIDs they can describe.
    /// Example: `["brass": ["lantern", "hook"], "rusty": ["knife"]]`
    public var adjectives: [String: Set<ItemID>]

    /// Maps known location names to the LocationID they refer to.
    public var locationNames: [String: LocationID]

    /// Maps known universal object names to the Set of Universals they can refer to.
    /// Universal objects are implicit concepts like "ground", "sky", "walls" that don't
    /// need explicit Item objects but can still be referenced by players.
    /// Example: `["ground": [.ground, .earth], "sky": [.sky, .heavens]]`
    public var universals: [String: Set<Universal>]

    /// A set of "noise" words to be ignored by the parser (articles, punctuation, etc.).
    /// Example: `["a", "an", "the", ".", ","]`
    public var noiseWords: Set<String>

    /// Common adverbs that can be ignored by the parser.
    /// These words are recognized but don't affect command processing.
    /// Example: `["carefully", "quickly", "slowly", "quietly"]`
    public var adverbs: Set<String>

    /// Common prepositions used to separate objects (e.g., "put X IN Y").
    public var prepositions: Set<Preposition>

    /// Common aliases for the player (e.g. "me", "self", "myself").
    public var playerAliases: Set<String>

    /// Common pronouns handled by the parser.
    public var pronouns: Set<String>

    /// Optional vocabulary enhancer for automatic extraction of adjectives and synonyms
    /// This is not persisted when encoding/decoding and must be set at runtime
    public var enhancer: VocabularyEnhancer?

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

    /// Computed property to get the verb lookup mapping needed by the parser.
    /// Maps a verb string (lowercase) to the Verb it represents.
    /// Each verb has a unique rawValue, so this is a simple one-to-one mapping.
    public var verbLookup: [String: Verb] {
        var mapping: [String: Verb] = [:]

        // Build the mapping - each verb rawValue maps to exactly one verb
        for verb in verbs {
            let key = verb.rawValue.lowercased()
            mapping[key] = verb
        }
        return mapping
    }

    // MARK: - Initialization

    /// Initializes an empty vocabulary, using default noise words, prepositions, and pronouns.
    public init(enhancer: VocabularyEnhancer? = nil) {
        self.verbs = []  // Initialize new array
        self.verbToSyntax = [:]  // Initialize new mapping
        self.items = [:]
        self.adjectives = [:]
        self.locationNames = [:]  // Initialize new property
        self.universals = Vocabulary.defaultUniversals
        self.noiseWords = Vocabulary.defaultNoiseWords
        self.playerAliases = Vocabulary.defaultPlayerAliases
        self.prepositions = Vocabulary.defaultPrepositions
        self.pronouns = Vocabulary.defaultPronouns
        self.directions = [:]
        self.specialKeywords = Vocabulary.defaultSpecialKeywords
        self.conjunctions = Vocabulary.defaultConjunctions
        self.adverbs = Vocabulary.defaultAdverbs
        self.enhancer = enhancer
    }

    /// Initializes a vocabulary with pre-populated dictionaries and sets.
    public init(
        verbs: [Verb] = [],
        verbToSyntax: [Verb: [SyntaxRule]] = [:],
        items: [String: Set<ItemID>] = [:],
        adjectives: [String: Set<ItemID>] = [:],
        locationNames: [String: LocationID] = [:],
        universals: [String: Set<Universal>] = Vocabulary.defaultUniversals,
        directions: [String: Direction] = [:],
        noiseWords: Set<String> = Vocabulary.defaultNoiseWords,
        playerAliases: Set<String> = Vocabulary.defaultPlayerAliases,
        prepositions: Set<Preposition> = Vocabulary.defaultPrepositions,
        pronouns: Set<String> = Vocabulary.defaultPronouns,
        specialKeywords: Set<String> = Vocabulary.defaultSpecialKeywords,
        conjunctions: Set<String> = Vocabulary.defaultConjunctions,
        adverbs: Set<String> = Vocabulary.defaultAdverbs,
        enhancer: VocabularyEnhancer? = nil
    ) {
        self.verbs = verbs
        self.verbToSyntax = verbToSyntax
        self.items = items
        self.adjectives = adjectives
        self.locationNames = locationNames
        self.universals = universals
        self.directions = directions
        self.noiseWords = noiseWords
        self.playerAliases = playerAliases
        self.prepositions = prepositions
        self.pronouns = pronouns
        self.specialKeywords = specialKeywords
        self.conjunctions = conjunctions
        self.adverbs = adverbs
        self.enhancer = enhancer
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
        "my",
        "some",
        "that",
        "the",
        "these",
        "this",
        "those",
    ]

    /// Default set of common English prepositions.
    public static let defaultPrepositions: Set<Preposition> = [
        .under,
        .about,
        .above,
        .across,
        .after,
        .against,
        .along,
        .among,
        .around,
        .at,
        .before,
        .behind,
        .below,
        .beneath,
        .beside,
        .between,
        .beyond,
        .by,
        .down,
        .during,
        .for,
        .from,
        .in,
        .inside,
        .into,
        .near,
        .of,
        .off,
        .on,
        .onto,
        .out,
        .outside,
        .over,
        .through,
        .to,
        .toward,
        .under,
        .up,
        .upon,
        .with,
        .within,
        .without,
    ]

    /// Default set of common English aliases for the player.
    public static let defaultPlayerAliases: Set<String> = [
        "me",
        "self",
        "myself",
    ]

    /// Default set of common English pronouns.
    public static let defaultPronouns: Set<String> = [
        "her",
        "him",
        "it",
        "them",
    ]

    /// Default set of special keywords that receive special parser treatment.
    /// These words trigger special parsing logic rather than being treated as regular nouns.
    public static let defaultSpecialKeywords: Set<String> = [
        "all",
        "everything",
        "each",
    ]

    /// Default set of conjunctions used to connect multiple objects.
    /// These words are used to parse commands like "TAKE SWORD AND LANTERN".
    public static let defaultConjunctions: Set<String> = [
        "and",
        ",",
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
        // Remove any existing verb with the same ID, then add the new one
        self.verbs.removeAll { $0.rawValue == verb.rawValue }
        self.verbs.append(verb)
    }

    /// Adds an item, its synonyms, and its adjectives to the vocabulary.
    /// - Parameter item: The `Item` object to add.
    public mutating func add(item: Item) {
        let itemID = item.id
        let itemName = item.properties[.name]?.toString ?? itemID.rawValue
        let lowercasedName = itemName.lowercased()
        let lowercasedID = itemID.rawValue.lowercased()

        // Get enhanced adjectives and synonyms if enhancer is available
        var finalAdjectives: Set<String> = item.properties[.adjectives]?.toStrings ?? []
        var finalSynonyms: Set<String> = item.properties[.synonyms]?.toStrings ?? []

        if let enhancer {
            let extractionResult = enhancer.extractAdjectivesAndSynonyms(from: item)
            let (enhancedAdjectives, enhancedSynonyms) = enhancer.combineExtractedTerms(
                for: item,
                extractedAdjectives: extractionResult.adjectives,
                extractedSynonyms: extractionResult.synonyms
            )

            if enhancer.configuration.shouldMergeWithExplicit {
                finalAdjectives = finalAdjectives.union(enhancedAdjectives)
                finalSynonyms = finalSynonyms.union(enhancedSynonyms)
            } else {
                if finalAdjectives.isEmpty {
                    finalAdjectives = enhancedAdjectives
                }
                if finalSynonyms.isEmpty {
                    finalSynonyms = enhancedSynonyms
                }
            }
        }

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

        // Add synonyms as potential nouns (now potentially enhanced)
        for synonym in finalSynonyms {
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

        // Add explicit adjectives (now potentially enhanced)
        for adjective in finalAdjectives {
            let lowercasedAdj = adjective.lowercased()
            self.adjectives[lowercasedAdj, default: []].insert(itemID)
        }
    }

    /// Adds a location and its name to the vocabulary.
    /// - Parameter location: The `Location` object to add.
    public mutating func add(location: Location) {
        let locationID = location.id
        let locationName = location.properties[.name]?.toString ?? locationID.rawValue
        let lowercasedName = locationName.lowercased()
        let lowercasedID = locationID.rawValue.lowercased()

        self.locationNames[lowercasedName] = locationID
        self.locationNames[lowercasedID] = locationID
    }

    /// Builds a basic vocabulary from arrays of items and verbs, including standard directions.
    /// - Parameters:
    ///   - items: An array of `Item` objects specific to the game.
    ///   - locations: An array of `Location` objects specific to the game.
    ///   - verbs: An array of `Verb` objects specific to the game.
    ///   - verbToSyntax: A mapping from verbs to their syntax rules from ActionHandlers.
    ///   - enhancer: An optional vocabulary enhancer for customizing word recognition.
    /// - Returns: A populated `Vocabulary` instance.
    public static func build(
        items: [Item] = [],
        locations: [Location] = [],
        verbs: [Verb] = [],
        verbToSyntax: [Verb: [SyntaxRule]] = [:],
        enhancer: VocabularyEnhancer? = nil
    ) -> Vocabulary {
        var vocab = Vocabulary(enhancer: enhancer)
        vocab.verbToSyntax = verbToSyntax

        #if DEBUG
            vocab.add(
                verb: Verb(
                    id: "debug",
                    intents: .debug
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
            "out": .outside,
                // Add LAND? Might conflict with "land verb"
        ]
    }

    /// Checks if a given word is a known pronoun.
    public func isPronoun(_ word: String) -> Bool {
        return pronouns.contains(word.lowercased())
    }

    // MARK: - Default Universal Objects

    /// Default mapping of common English words to universal objects.
    /// This provides sensible defaults that work for most English IF games.
    /// Games can override or extend this mapping for localization or customization.
    public static let defaultUniversals: [String: Set<Universal>] = [
        // Ground and earth
        "ground": [.ground],
        "earth": [.earth, .ground],
        "soil": [.soil, .earth, .ground],
        "dirt": [.dirt, .earth, .ground],
        "floor": [.floor, .ground],

        // Sky and atmosphere
        "sky": [.sky],
        "heavens": [.heavens, .sky],
        "air": [.air],
        "clouds": [.clouds, .sky],
        "sun": [.sun],
        "moon": [.moon],
        "stars": [.stars],

        // Architectural elements
        "ceiling": [.ceiling],
        "walls": [.walls],
        "wall": [.wall, .walls],
        "roof": [.roof, .ceiling],

        // Water features
        "water": [.water],
        "river": [.river, .water],
        "stream": [.stream, .river, .water],
        "lake": [.lake, .water],
        "pond": [.pond, .lake, .water],
        "ocean": [.ocean, .sea, .water],
        "sea": [.sea, .ocean, .water],

        // Natural elements
        "wind": [.wind, .air],
        "fire": [.fire],
        "flames": [.flames, .fire],
        "smoke": [.smoke],
        "dust": [.dust],
        "mud": [.mud, .dirt, .earth],
        "sand": [.sand, .dirt],
        "rock": [.rock, .stone],
        "stone": [.stone, .rock],

        // Abstract concepts
        "darkness": [.darkness],
        "shadows": [.shadows, .darkness],
        "light": [.light],
        "silence": [.silence],
        "sound": [.sound, .noise],
        "noise": [.noise, .sound],
    ]
}
