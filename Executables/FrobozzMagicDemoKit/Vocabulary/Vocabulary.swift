import GnustoEngine

/// Defines the verbs used *specifically* by the Frobozz Magic Demo Kit game.
/// Common verbs (look, go, inventory, quit, wait, etc.) are provided by the engine's default vocabulary.
@MainActor enum VocabularySetup {
    /// Game-specific verbs.
    static let verbs: [Verb] = [
        // Light interaction (Needs custom logic beyond simple on/off)

        Verb(
            id: "light",
            synonyms: "turn on"
        ),
        Verb(
            id: "extinguish",
            synonyms: "turn off"
        ),

        // Puzzle-specific / Custom Actions

        Verb(id: "unlock"),

        // Other interactions (Taste/Touch defaults exist)

        Verb(
            id: "drink",
            synonyms: "sip", "taste"
        ),
    ]

    // Note: The actual Vocabulary object is built in GameDataSetup using these verbs
    // and the items defined in Game/*.swift files. The engine's default verbs are
    // typically included automatically by Vocabulary.build().
}
