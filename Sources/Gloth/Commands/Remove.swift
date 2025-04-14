import Foundation

/// Generates phrases related to removing worn items.
enum Remove: Generator {
    /// Generates a random phrase for removing a worn item.
    ///
    /// Examples:
    /// - "remove the leather boots"
    /// - "take off helmet"
    /// - "take the dusty cloak off"
    static func any() -> Phrase {
        let removableObject = Wear.wearableObject
        let clothingMod = Wear.clothingSpecificMod
        let container = PutIn.containerObject

        return any(
            // --- Remove from Implicit Container (Inventory) ---
            phrase( // remove [mod] object
                .verb(removeVerb.rnd),
                .modifier(clothingMod.rnd),
                .directObject(removableObject.rnd)
            ),
            phrase( // remove object
                .verb(removeVerb.rnd),
                .directObject(removableObject.rnd)
            ),

            // --- Remove from Explicit Container ---
            phrase( // remove [mod] object from [mod] container
                .verb(removeVerb.rnd),
                .modifier(clothingMod.rnd),
                .directObject(removableObject.rnd),
                .preposition(fromPrep),
                .modifier(clothingMod.rnd),
                .indirectObject(container.rnd)
            ),
            phrase( // remove object from container
                .verb(removeVerb.rnd),
                .directObject(removableObject.rnd),
                .preposition(fromPrep),
                .indirectObject(container.rnd)
            ),

            // --- Refactored Phrasal ---
            // Take Off
            phrase( // take off [object] -> Verb: take, Prep: off, DO: object
                .verb(takeVerb),
                .preposition(offPrep),
                .directObject(removableObject.rnd)
            ),
            phrase( // take [object] off -> Verb: take, DO: object, Prep: off
                .verb(takeVerb),
                .directObject(removableObject.rnd),
                .preposition(offPrep)
            ),

            // Pull Out
            phrase( // pull out [object] -> Verb: pull, Prep: out, DO: object
                .verb(pullVerb),
                .preposition(outPrep),
                .directObject(removableObject.rnd)
            ),
            phrase( // pull [object] out -> Verb: pull, DO: object, Prep: out
                .verb(pullVerb),
                .directObject(removableObject.rnd),
                .preposition(outPrep)
            )
        )
    }
}

// MARK: - Samples

extension Remove {
    // --- Verbs ---
    static let removeVerb: [String] = ["remove", "dislodge", "extract"]
    static let takeVerb: String = "take" // Back to original use
    static let pullVerb: String = "pull" // Back to original use
    // static let takeOffVerb: String = "take off" // Removed combined verb
    // static let pullOutVerb: String = "pull out" // Removed combined verb

    // --- Prepositions ---
    static let offPrep: String = "off"
    static let outPrep: String = "out"
    static let fromPrep: String = "from"

    // Note: `removableObject` and `clothingMod` are taken from `Wear` enum.
    // Note: `container` is assumed to be defined in `PutIn.containerObject`.
}
