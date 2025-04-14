import Foundation

/// Generates phrases related to touching or feeling objects.
enum Touch: Generator {
    /// Generates a random phrase for touching an object.
    ///
    /// Examples:
    /// - "touch the smooth stone"
    /// - "feel the rough wall"
    /// - "pat the dog"
    /// - "rub the magic lamp"
    static func any() -> Phrase {
        // Combine objects from various sources that might be touched
        let touchableObjectList = Array(Set(
            Take.takeableObject +
            Examine.scenery +
            Wear.wearableObject +
            Attack.enemy + // Includes animals/creatures
            Traverse.surfaceObject +
            Traverse.underObject
        ))

        // Reuse general object modifiers
        let objectMod = Take.objectMod

        return any(
            phrase( // verb the [mod] object
                .verb(touchVerb.rnd),
                .determiner("the"),
                .modifier(objectMod.rnd),
                .directObject(touchableObjectList.rnd)
            ),
            phrase( // verb object
                .verb(touchVerb.rnd),
                .directObject(touchableObjectList.rnd)
            )
        )
    }
}

// MARK: - Samples

extension Touch {
    /// Sample verbs for touching, feeling, etc.
    static var touchVerb: [String] {
        [
            "feel",
            "pat",
            "pet", // Usually for animals
            "poke",
            "prod",
            "rub",
            "stroke",
            "tap",
            "touch",
        ]
    }

    // Note: Object list and modifiers are generated/reused within any()
}
