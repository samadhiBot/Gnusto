import GnustoEngine
import Foundation // For print

/// Defines the verbs used *specifically* by the Frobozz Magic Demo Kit game.
/// Common verbs (look, go, inventory, quit, wait, etc.) are provided by the engine's default vocabulary.
enum VocabularySetup {
    /// Game-specific verbs.
    static let verbs: [Verb] = [
        // Removed light, extinguish (handled by engine defaults + particles)

        // Game-specific puzzle verb
        Verb(
            id: "unlock",
            syntax: [SyntaxRule(.verb, .directObject)]
        ),

        // Custom interaction verb
        Verb(
            id: "drink", // Keep "sip" synonym, remove "taste"
            synonyms: "sip",
            syntax: [SyntaxRule(.verb, .directObject)]
        ),

        // Completely new game-specific verb
        Verb(
            id: "invoke",
            synonyms: "chant",
            syntax: [SyntaxRule(.verb)]
        ),

        // Override/Extend default engine verb 'drop'
        Verb(
            id: "drop", // No synonyms needed if just extending
            syntax: [
                // Add game-specific syntax rule for drop
                SyntaxRule(.verb, .directObject, .particle("silently"))
                // Note: Engine's default rule [.verb, .directObject] will also be added
                // during Vocabulary.build() unless we explicitly prevent defaults.
            ]
        ),
    ]

    // Note: The actual Vocabulary object is built in GameDataSetup using these verbs
    // and the items defined in Game/*.swift files. The engine's default verbs are
    // typically included automatically by Vocabulary.build().
}
