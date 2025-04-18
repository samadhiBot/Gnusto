import GnustoEngine

/// Defines the verbs used *specifically* by the Frobozz Magic Demo Kit game.
/// Common verbs (look, go, inventory, quit, wait, etc.) are provided by the engine's default vocabulary.
@MainActor enum VocabularySetup {
    /// Game-specific verbs.
    static let verbs: [Verb] = [
        // Light interaction (Needs custom logic beyond simple on/off)
        Verb(id: "light", synonyms: ["turn on"]),      // Needs specific ActionHandler
        Verb(id: "extinguish", synonyms: ["turn off"]), // Needs specific ActionHandler

        // Container interaction (Open/Close defaults exist, but might need override)
        // Verb(id: "open", synonyms: ["unlock"]), // Default exists, synonym handled?
        // Verb(id: "close", synonyms: ["shut"]),   // Default exists

        // Puzzle-specific / Custom Actions
        Verb(id: "unlock", synonyms: []), // Specific action handler needed for iron door

        // Other interactions (Taste/Touch defaults exist)
        Verb(id: "drink", synonyms: ["sip", "taste"]), // Taste synonym might clash? Keep custom for now.
        // Verb(id: "touch", synonyms: ["feel"]), // Default exists

        // Verb(id: "help", synonyms: ["hint", "info"]), // Default exists (placeholder)
    ]

    // Note: The actual Vocabulary object is built in GameDataSetup using these verbs
    // and the items defined in Game/*.swift files. The engine's default verbs are
    // typically included automatically by Vocabulary.build().
}
