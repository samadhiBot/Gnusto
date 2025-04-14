import Foundation

/// Generates phrases related to waving.
enum Wave: Generator {
    /// Generates a random phrase for waving.
    ///
    /// Examples:
    /// - "wave"
    /// - "wave hand"
    /// - "wave the white flag"
    /// - "wave at the guard"
    static func any() -> Phrase {
        // Objects that can be waved
        let waveableObjectList = Array(Set(
            Take.takeableObject.filter { ["banner", "cloth", "flag", "handkerchief", "kerchief", "rag", "scarf", "staff", "stick", "torch", "wand"].contains($0) } +
            ["arm", "arms", "hand", "hands"]
        ))
        // Recipients/targets to wave at
        let targetList = Give.recipient
        let objectMod = Take.objectMod

        return any(
            // --- Simple Wave ---
            phrase( // wave
                .verb(waveVerb)
            ),

            // --- Wave [Object] ---
            phrase( // wave the [mod] object
                .verb(waveVerb),
                .determiner("the"),
                .modifier(objectMod.rnd),
                .directObject(waveableObjectList.rnd)
            ),
            phrase( // wave object
                .verb(waveVerb),
                .directObject(waveableObjectList.rnd)
            ),

            // --- Wave At [Target] ---
            phrase( // wave at the [mod] target
                .verb(waveVerb),
                .preposition(atPrep),
                .determiner("the"),
                .modifier(objectMod.rnd),
                .indirectObject(targetList.rnd)
            ),
            phrase( // wave at target
                .verb(waveVerb),
                .preposition(atPrep),
                .indirectObject(targetList.rnd)
            ),

            // --- Wave To [Target] (Added) ---
            phrase( // wave to the [mod] target
                .verb(waveVerb),
                .preposition(toPrep),
                .determiner("the"),
                .modifier(objectMod.rnd),
                .indirectObject(targetList.rnd)
            ),
            phrase( // wave to target
                .verb(waveVerb),
                .preposition(toPrep),
                .indirectObject(targetList.rnd)
            )
        )
    }
}

// MARK: - Samples

extension Wave {
    /// Verb for waving.
    static let waveVerb: String = "wave"

    /// Preposition used.
    static let atPrep: String = "at"
    static let toPrep: String = "to"

    // Note: Object/target lists and modifiers generated/reused within any()
}
