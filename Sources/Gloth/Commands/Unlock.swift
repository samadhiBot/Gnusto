import Foundation

/// Generates phrases related to unlocking objects.
enum Unlock: Generator {
    /// Generates a random phrase for unlocking an object.
    ///
    /// Examples:
    /// - "unlock the heavy door"
    /// - "unlock chest"
    /// - "unlock the safe with the silver key"
    static func any() -> Phrase {
        // Reuse objects from Open/Close (same as Lock)
        let unlockableObject = Open.openableObject
        // Reuse modifiers from Take
        let objectMod = Take.objectMod
        let keyMod = Take.objectMod
        // Reuse keys from Lock
        let keyObject = Lock.keyObject
        // Reuse preposition from Lock
        let withPrep = Lock.withPrep

        return any(
            // --- Simple Unlock ---
            phrase( // unlock the [mod] object
                .verb(unlockVerb),
                .determiner("the"),
                .modifier(objectMod.rnd),
                .directObject(unlockableObject.rnd)
            ),
            phrase( // unlock object
                .verb(unlockVerb),
                .directObject(unlockableObject.rnd)
            ),

            // --- Unlock With Key ---
            phrase( // unlock the [mod] object with the [mod] key
                .verb(unlockVerb),
                .determiner("the"),
                .modifier(objectMod.rnd),
                .directObject(unlockableObject.rnd),
                .preposition(withPrep),
                .determiner("the"),
                .modifier(keyMod.rnd),
                .indirectObject(keyObject.rnd)
            ),
            phrase( // unlock object with key
                .verb(unlockVerb),
                .directObject(unlockableObject.rnd),
                .preposition(withPrep),
                .indirectObject(keyObject.rnd)
            ),

            // --- Unlock With Double Modifier Key ---
            phrase( // unlock the [mod] object with the [mod] [mod] key
                .verb(unlockVerb),
                .determiner("the"),
                .modifier(objectMod.rnd),
                .directObject(unlockableObject.rnd),
                .preposition(withPrep),
                .determiner("the"),
                .modifier(keyMod.rnd),
                .modifier(keyMod.rnd),
                .indirectObject(keyObject.rnd)
            ),
            phrase( // unlock object with [mod] [mod] key
                .verb(unlockVerb),
                .directObject(unlockableObject.rnd),
                .preposition(withPrep),
                .modifier(keyMod.rnd),
                .modifier(keyMod.rnd),
                .indirectObject(keyObject.rnd)
            ),
            // Duplicate double IO modifier patterns for more weight
            phrase( // unlock the [mod] object with the [mod] [mod] key
                .verb(unlockVerb),
                .determiner("the"),
                .modifier(objectMod.rnd),
                .directObject(unlockableObject.rnd),
                .preposition(withPrep),
                .determiner("the"),
                .modifier(keyMod.rnd),
                .modifier(keyMod.rnd),
                .indirectObject(keyObject.rnd)
            ),
            phrase( // unlock object with [mod] [mod] key
                .verb(unlockVerb),
                .directObject(unlockableObject.rnd),
                .preposition(withPrep),
                .modifier(keyMod.rnd),
                .modifier(keyMod.rnd),
                .indirectObject(keyObject.rnd)
            )
        )
    }
}

// MARK: - Samples

extension Unlock {
    /// Sample verbs for unlocking.
    static var unlockVerb: String {
        "unlock"
    }

    // Note: `unlockableObject`, `keyObject`, `withPrep`, and modifiers
    // are taken from `Lock` or `Take` enums directly in `any()`.
}
