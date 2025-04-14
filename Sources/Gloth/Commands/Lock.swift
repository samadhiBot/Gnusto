import Foundation

/// Generates phrases related to locking objects.
enum Lock: Generator {
    /// Generates a random phrase for locking an object.
    ///
    /// Examples:
    /// - "lock the heavy door"
    /// - "lock chest"
    /// - "lock the safe with the silver key"
    static func any() -> Phrase {
        let lockableObject = Close.closeableObject // From Close.swift
        let keyObject = Self.keyObject             // Defined in this file
        let objectMod = Take.objectMod             // From Take.swift
        let person = Attack.enemy                   // From Attack.swift

        return any(
            phrase( // lock [mod] object
                .verb(lockVerb.rnd),
                .modifier(objectMod.rnd),
                .directObject(lockableObject.rnd)
            ),
            phrase( // lock object
                .verb(lockVerb.rnd),
                .directObject(lockableObject.rnd)
            ),
            phrase( // lock [mod] object with [mod] key
                .verb(lockVerb.rnd),
                .modifier(objectMod.rnd),
                .directObject(lockableObject.rnd),
                .preposition(withPrep),
                .modifier(objectMod.rnd),
                .indirectObject(keyObject.rnd)
            ),
            phrase( // lock object with key
                .verb(lockVerb.rnd),
                .directObject(lockableObject.rnd),
                .preposition(withPrep),
                .indirectObject(keyObject.rnd)
            ),
            // Double Modifiers (IO)
            phrase( // lock [mod] object with [mod] [mod] key (multi-modifier IO)
                .verb(lockVerb.rnd),
                .modifier(objectMod.rnd),
                .directObject(lockableObject.rnd),
                .preposition(withPrep),
                .modifier(objectMod.rnd), // IO Mod 1
                .modifier(objectMod.rnd), // IO Mod 2
                .indirectObject(keyObject.rnd)
            ),
            phrase( // lock object with [mod] [mod] key (multi-modifier IO)
                .verb(lockVerb.rnd),
                .directObject(lockableObject.rnd),
                .preposition(withPrep),
                .modifier(objectMod.rnd), // IO Mod 1
                .modifier(objectMod.rnd), // IO Mod 2
                .indirectObject(keyObject.rnd)
            ),
            // Duplicate double IO modifier patterns for more weight
            phrase( // lock [mod] object with [mod] [mod] key (multi-modifier IO)
                .verb(lockVerb.rnd),
                .modifier(objectMod.rnd),
                .directObject(lockableObject.rnd),
                .preposition(withPrep),
                .modifier(objectMod.rnd), // IO Mod 1
                .modifier(objectMod.rnd), // IO Mod 2
                .indirectObject(keyObject.rnd)
            ),
            phrase( // lock object with [mod] [mod] key (multi-modifier IO)
                .verb(lockVerb.rnd),
                .directObject(lockableObject.rnd),
                .preposition(withPrep),
                .modifier(objectMod.rnd), // IO Mod 1
                .modifier(objectMod.rnd), // IO Mod 2
                .indirectObject(keyObject.rnd)
            ),
            // Double Modifiers (DO)
            phrase( // lock up [object] -> Verb: lock, Prep: up, DO: object
                .verb(lockVerb.rnd),
                .preposition(upPrep),
                .directObject(lockableObject.rnd)
            ),
            phrase( // lock [object] up -> Verb: lock, DO: object, Prep: up
                .verb(lockVerb.rnd),
                .directObject(lockableObject.rnd),
                .preposition(upPrep)
            ),
            phrase( // lock up [person] -> Verb: lock, Prep: up, DO: person
                .verb(lockVerb.rnd),
                .preposition(upPrep),
                .directObject(person.rnd)
            ),
            phrase( // lock [person] up -> Verb: lock, DO: person, Prep: up
                .verb(lockVerb.rnd),
                .directObject(person.rnd),
                .preposition(upPrep)
            )
        )
    }
}

// MARK: - Samples

extension Lock {
    /// Sample verbs for locking.
    static let lockVerb: [String] = ["lock", "secure"]

    /// Preposition for specifying the key.
    static let withPrep: String = "with"

    /// Preposition for specifying the direction.
    static let upPrep: String = "up"

    /// Sample key objects.
    static let keyObject: [String] = {
        [
            "key",
            "skeleton key",
            "master key",
            "passkey",
            "card",
            "keycard",
        ]
    }()

    // Note: `lockableObject` is taken from `Close.closeableObject` directly in `any()`
    // Note: Reusing `Take.objectMod` for modifiers.
    // Note: Reusing `Attack.enemy` for person.
}
