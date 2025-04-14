import Foundation

/// Generates phrases related to dropping or putting down items.
enum Drop: Generator {
    /// Generates a random phrase for dropping an item.
    ///
    /// Examples:
    /// - "drop the heavy rock"
    /// - "put down the rusty sword"
    /// - "drop all"
    /// - "put the potion down"
    static func any() -> Phrase {
        let droppableObject = Take.takeableObject
        let objectMod = Take.objectMod
        let allObject = Self.allObject

        return any(
            // Drop
            phrase(.verb(dropVerb.rnd), .determiner("the"), .modifier(objectMod.rnd), .directObject(droppableObject.rnd)),
            phrase(.verb(dropVerb.rnd), .directObject(droppableObject.rnd)),
            phrase(.verb(dropVerb.rnd), .directObject(allObject.rnd)),

            // Discard
            phrase(.verb(discardVerb.rnd), .determiner("the"), .modifier(objectMod.rnd), .directObject(droppableObject.rnd)),
            phrase(.verb(discardVerb.rnd), .directObject(droppableObject.rnd)),

            // Put Down
            phrase(.verb(putVerb), .preposition(downPrep), .directObject(droppableObject.rnd)),
            phrase(.verb(putVerb), .directObject(droppableObject.rnd), .preposition(downPrep)),

            // Throw Away
            phrase(.verb(throwVerb), .preposition(awayPrep), .directObject(droppableObject.rnd)),
            phrase(.verb(throwVerb), .directObject(droppableObject.rnd), .preposition(awayPrep))
        )
    }
}

// MARK: - Samples

extension Drop {
    // --- Verbs ---
    static let dropVerb: [String] = ["drop"]
    static let putVerb: String = "put"
    static let discardVerb: [String] = ["discard", "jettison", "dispose of"]
    static let throwVerb: String = "throw"

    // --- Prepositions ---
    static let downPrep: String = "down"
    static let awayPrep: String = "away"

    // --- Objects ---
    /// Special objects for dropping.
    static let allObject: [String] = {
        [
            "all",
            "everything",
        ]
    }()

    // Note: `droppableObject` and `objectMod` are taken from `Take` enum directly in `any()`
}
