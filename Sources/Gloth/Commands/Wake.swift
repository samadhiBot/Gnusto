import Foundation

/// Generates phrases related to waking someone or oneself.
enum Wake: Generator {
    /// Generates a random phrase for waking.
    ///
    /// Examples:
    /// - "wake the sleeping guard"
    /// - "wake up"
    /// - "wake self"
    static func any() -> Phrase {
        // Reuse recipients/enemies from Give/Attack
        let targetList = Give.recipient + Attack.anyone // Add self-references
        let targetMod = Attack.enemyMod

        return any(
            // --- Wake [Target] ---
            phrase( // wake the [mod] target
                .verb(wakeVerb.rnd),
                .determiner("the"),
                .modifier(targetMod.rnd),
                .directObject(targetList.rnd)
            ),
            phrase( // wake target
                .verb(wakeVerb.rnd),
                .directObject(targetList.rnd)
            ),

            // --- Refactored Phrasal ---
            phrase( // wake up [target] -> Verb: wake, Prep: up, DO: target
                .verb(wakeVerb.rnd),
                .preposition(upPrep),
                .directObject(targetList.rnd)
            ),
            phrase( // wake [target] up -> Verb: wake, DO: target, Prep: up
                .verb(wakeVerb.rnd),
                .directObject(targetList.rnd),
                .preposition(upPrep)
            ),
            phrase( // wake up (no object) -> Verb: wake, Prep: up
                .verb(wakeVerb.rnd),
                .preposition(upPrep)
            )
            // --- End Refactored ---
        )
    }
}

// MARK: - Samples

extension Wake {
    /// Sample verbs for waking.
    static let wakeVerb: [String] = {
        [
            "wake",
            "arouse",
            "awaken",
            "rouse",
            "stir",
        ]
    }()

    /// Added preposition.
    static let upPrep: String = "up"

    // Note: Target list and modifiers reused

    // Reuse enemies/persons as targets
    static let target: [String] = Attack.enemy
    static let targetMod: [String] = Attack.enemyMod
}
