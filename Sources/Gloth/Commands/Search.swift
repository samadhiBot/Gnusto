import Foundation

/// Generates phrases related to searching containers.
enum Search: Generator {
    /// Generates a random phrase for searching a container.
    ///
    /// Examples:
    /// - "search the dusty chest"
    /// - "look in the sack"
    /// - "search wardrobe"
    static func any() -> Phrase {
        let container = PutIn.containerObject // Reuse container list
        let objectMod = Take.objectMod
        let item = Take.takeableObject // What might be searched for

        return any(
            phrase( // search [mod] container
                .verb(searchVerb.rnd),
                .modifier(objectMod.rnd),
                .directObject(container.rnd)
            ),
            phrase( // search container
                .verb(searchVerb.rnd),
                .directObject(container.rnd)
            ),
            phrase( // look in [mod] container -> V: look, P: in, DO: container
                .verb("look"),
                .preposition("in"),
                .modifier(objectMod.rnd),
                .directObject(container.rnd)
            ),
            phrase( // look in container -> V: look, P: in, DO: container
                .verb("look"),
                .preposition("in"),
                .directObject(container.rnd)
            ),
            // --- Added for Test Failures ---
            phrase( // search for [item] -> V: search, P: for, IO: item
                .verb(searchVerb.rnd),
                .preposition(forPrep),
                .indirectObject(item.rnd)
            ),
            phrase( // search [container] for [item] (Verb: search, DO: container, Prep: for, IO: item)
                .verb(searchVerb.rnd),
                .directObject(container.rnd),
                .preposition(forPrep),
                .indirectObject(item.rnd)
            ),
            // Added: Double Modifiers
            phrase( // search [mod1] [mod2] container
                .verb(searchVerb.rnd),
                .modifier(objectMod.rnd),
                .modifier(objectMod.rnd),
                .directObject(container.rnd)
            ),
            phrase( // look in [mod1] [mod2] container -> V: look, P: in, DO: container
                .verb("look"),
                .preposition("in"),
                .modifier(objectMod.rnd),
                .modifier(objectMod.rnd),
                .directObject(container.rnd)
            ),
            phrase( // search for [mod1] [mod2] item -> V: search, P: for, IO: item
                .verb(searchVerb.rnd),
                .preposition(forPrep),
                .modifier(objectMod.rnd),
                .modifier(objectMod.rnd),
                .indirectObject(item.rnd)
            ),
            phrase( // search [container] for [mod1] [mod2] item
                .verb(searchVerb.rnd),
                .directObject(container.rnd),
                .preposition(forPrep),
                .modifier(objectMod.rnd),
                .modifier(objectMod.rnd),
                .indirectObject(item.rnd)
            ),
            // Added: search for [mod] item
            phrase(
                .verb(searchVerb.rnd),
                .preposition(forPrep),
                .modifier(objectMod.rnd),
                .indirectObject(item.rnd)
            )
        )
    }
}

// MARK: - Samples

extension Search {
    /// Sample verbs for searching.
    static let searchVerb: [String] = ["search", "investigate"]
    static let lookVerb: String = "look" // Added
    static let inPrep: String = "in" // Added
    static let forPrep: String = "for"

    // Note: `container` and `objectMod` are taken from
    // `PutIn` and `Take` enums directly in `any()`.
}
