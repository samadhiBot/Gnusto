import GnustoEngine

/// Defines the verbs used in the game.
enum VocabularySetup {
    /// Verbs used in the game.
    static let verbs: [VerbDefinition] = [
        // Basic navigation and interaction
        VerbDefinition(id: "look", synonyms: ["l"]),
        VerbDefinition(id: "examine", synonyms: ["x", "inspect"]),
        VerbDefinition(id: "inventory", synonyms: ["i"]),
        VerbDefinition(id: "take", synonyms: ["get", "grab", "pick"]),
        VerbDefinition(id: "drop", synonyms: ["put", "place"]),
        VerbDefinition(id: "go", synonyms: ["move", "walk"]),

        // Directions (handled specially by the parser, but defined here for potential custom actions)
        VerbDefinition(id: "north", synonyms: ["n"]),
        VerbDefinition(id: "south", synonyms: ["s"]),
        VerbDefinition(id: "east", synonyms: ["e"]),
        VerbDefinition(id: "west", synonyms: ["w"]),
        VerbDefinition(id: "up", synonyms: ["u"]),
        VerbDefinition(id: "down", synonyms: ["d"]),

        // Light interaction
        VerbDefinition(id: "light", synonyms: ["turn on"]),      // Consider specific action handler
        VerbDefinition(id: "extinguish", synonyms: ["turn off"]), // Consider specific action handler

        // Container interaction
        VerbDefinition(id: "open", synonyms: ["unlock"]),      // Often needs custom logic
        VerbDefinition(id: "close", synonyms: ["shut"]),       // Often needs custom logic

        // Puzzle-specific / Custom Actions
        VerbDefinition(id: "unlock", synonyms: []),            // Specific action handler needed (e.g., for iron door)

        // Other interactions
        VerbDefinition(id: "help", synonyms: ["hint", "info"]), // Handled by engine? Or custom?
        VerbDefinition(id: "drink", synonyms: ["sip", "taste"]),
        VerbDefinition(id: "touch", synonyms: ["feel"])
    ]

    // Note: The actual Vocabulary object is built in GameDataSetup using these verbs
    // and the items defined in Game/*.swift files.
}
