import GnustoEngine

/// Defines the verbs used in the game.
@MainActor enum VocabularySetup {
    /// Verbs used in the game.
    static let verbs: [Verb] = [
        // Basic navigation and interaction
        Verb(id: "look", synonyms: ["l"]),
        Verb(id: "examine", synonyms: ["x", "inspect"]),
        Verb(id: "inventory", synonyms: ["i"]),
        Verb(id: "take", synonyms: ["get", "grab", "pick"]),
        Verb(id: "drop", synonyms: ["put", "place"]),
        Verb(id: "go", synonyms: ["move", "walk"]),

        // Directions (handled specially by the parser, but defined here for potential custom actions)
        Verb(id: "north", synonyms: ["n"]),
        Verb(id: "south", synonyms: ["s"]),
        Verb(id: "east", synonyms: ["e"]),
        Verb(id: "west", synonyms: ["w"]),
        Verb(id: "up", synonyms: ["u"]),
        Verb(id: "down", synonyms: ["d"]),

        // Light interaction
        Verb(id: "light", synonyms: ["turn on"]),      // Consider specific action handler
        Verb(id: "extinguish", synonyms: ["turn off"]), // Consider specific action handler

        // Container interaction
        Verb(id: "open", synonyms: ["unlock"]),      // Often needs custom logic
        Verb(id: "close", synonyms: ["shut"]),       // Often needs custom logic

        // Puzzle-specific / Custom Actions
        Verb(id: "unlock", synonyms: []),            // Specific action handler needed (e.g., for iron door)

        // Other interactions
        Verb(id: "help", synonyms: ["hint", "info"]), // Handled by engine? Or custom?
        Verb(id: "drink", synonyms: ["sip", "taste"]),
        Verb(id: "touch", synonyms: ["feel"])
    ]

    // Note: The actual Vocabulary object is built in GameDataSetup using these verbs
    // and the items defined in Game/*.swift files.
}
