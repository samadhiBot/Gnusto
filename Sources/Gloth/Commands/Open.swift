import Foundation

/// Generates phrases related to opening objects.
enum Open: Generator {
    /// Generates a random phrase for opening an object.
    ///
    /// Examples:
    /// - "open the heavy door"
    /// - "open window"
    /// - "open the dusty book"
    static func any() -> Phrase {
        let openableObject = Close.closeableObject
        let objectMod = Take.objectMod

        return any(
            phrase( // verb the [mod] object
                .verb(openVerb.rnd),
                .determiner("the"),
                .modifier(objectMod.rnd),
                .directObject(openableObject.rnd)
            ),
            phrase( // verb object
                .verb(openVerb.rnd),
                .directObject(openableObject.rnd)
            ),
            phrase( // verb a [mod] object
                .verb(openVerb.rnd),
                .determiner("a"),
                .modifier(objectMod.rnd),
                .directObject(openableObject.rnd)
            ),
            phrase( // verb a object
                .verb(openVerb.rnd),
                .determiner("a"),
                .directObject(openableObject.rnd)
            ),
            // --- Refactored Phrasal ---
            phrase( // open up [object] -> Verb: open, Prep: up, DO: object
                .verb(openVerb.rnd),
                .preposition(upPrep),
                .directObject(openableObject.rnd)
            ),
            phrase( // open [object] up -> Verb: open, DO: object, Prep: up
                .verb(openVerb.rnd),
                .directObject(openableObject.rnd),
                .preposition(upPrep)
            ),
            // --- End Refactored ---
            phrase( // verb the [mod] object
                .verb(openVerb.rnd),
                .determiner("the"),
                .modifier(objectMod.rnd),
                .directObject(openableObject.rnd)
            ),
            phrase( // verb object
                .verb(openVerb.rnd),
                .directObject(openableObject.rnd)
            ),
            phrase( // verb a [mod] object
                .verb(openVerb.rnd),
                .determiner("a"),
                .modifier(objectMod.rnd),
                .directObject(openableObject.rnd)
            ),
            phrase( // verb a object
                .verb(openVerb.rnd),
                .determiner("a"),
                .directObject(openableObject.rnd)
            )
        )
    }
}

// MARK: - Samples

extension Open {
    /// Sample verbs for opening.
    static let openVerb: [String] = ["open"]

    /// Sample objects that can be opened.
    /// Should mirror `Close.closeableObject`.
    static let openableObject: [String] = Close.closeableObject

    /// Sample preposition for "open up".
    static let upPrep: String = "up"

    // Note: Reusing `Take.objectMod` for modifiers.
}
