import Foundation

/// Generates phrases related to smelling objects or the environment.
enum Smell: Generator {
    /// Generates a random phrase for smelling.
    ///
    /// Examples:
    /// - "smell the strange flower"
    /// - "sniff the air"
    /// - "smell potion"
    static func any() -> Phrase {
        // Combine objects from various sources that might be smelled
        let smellableObjectList = Array(Set(
            Take.takeableObject +
            Examine.scenery +
            Wear.wearableObject +
            Consume.foodObject +
            Consume.drinkObject +
            Attack.enemy +
            ["air", "area", "room", "environment"] // General terms
        ))

        // Reuse general object modifiers
        let objectMod = Take.objectMod

        return any(
            phrase( // verb the [mod] object
                .verb(smellVerb.rnd),
                .determiner("the"),
                .modifier(objectMod.rnd),
                .directObject(smellableObjectList.rnd)
            ),
            phrase( // verb object
                .verb(smellVerb.rnd),
                .directObject(smellableObjectList.rnd)
            )
        )
    }
}

// MARK: - Samples

extension Smell {
    /// Sample verbs for smelling.
    static var smellVerb: [String] {
        [
            "smell",
            "sniff",
            "inhale", // Can imply smelling
            "whiff",
        ]
    }

    // Note: Object list and modifiers are generated/reused within any()
}
