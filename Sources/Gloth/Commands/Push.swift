import Foundation

/// Generates phrases related to pushing or shoving objects.
enum Push: Generator {
    /// Generates a random phrase for pushing an object.
    ///
    /// Examples:
    /// - "push the heavy boulder"
    /// - "shove crate"
    /// - "push the rusty lever"
    static func any() -> Phrase {
        let objectMod = Take.objectMod.rnd
        let object = Take.takeableObject.rnd

        return any(
            phrase(.verb(pushVerb.rnd), .determiner("the"), .modifier(objectMod), .directObject(object)),
            phrase(.verb(pushVerb.rnd), .directObject(object)),
            phrase(.verb(pressVerb.rnd), .directObject(object)),
            phrase(.verb(pressVerb.rnd), .modifier(objectMod), .directObject(object)),
            phrase( // push in [object] -> Verb: push, Prep: in, DO: object
                .verb(pushVerb.rnd),
                .preposition(inPrep),
                .directObject(object)
            ),
            phrase( // push [object] in -> Verb: push, DO: object, Prep: in
                .verb(pushVerb.rnd),
                .directObject(object),
                .preposition(inPrep)
            )
        )
    }
}

// MARK: - Samples

extension Push {
    /// Sample verbs for pushing or shoving.
    static let pushVerb: [String] = {
        [
            "push",
            "shove",
            "press",
            "move",
            "budge",
            "nudge",
        ]
    }()

    /// Sample objects that can be pushed or shoved.
    static let pushableObject: [String] = {
        // Combine potentially pushable objects from other generators + specifics
        Array(Set(
            Examine.scenery.filter { ["boulder", "button", "cart", "chair", "chest", "crate", "door", "gate", "lever", "minecart", "pedestal", "pillar", "rock", "statue", "stone", "switch", "table", "throne", "trolley", "wagon"].contains($0) } +
            Traverse.surfaceObject.filter { ["block", "boulder", "log", "platform", "raft", "rock", "stone"].contains($0) } +
            Attack.enemy + // You might try to push an enemy
            [
                // Specific additions
                "barrel", // From Traverse
                "blockage",
                "cabinet", // From Examine
                "cart", // From Traverse
                "debris",
                "hay bale", // From Traverse
                "panel", // From Close
                "plank",
                "rubble",
                "slab",
                "wardrobe", // From Traverse
                "wheelbarrow",
            ]
        ))
    }()

    /// Sample press verbs.
    static let pressVerb: [String] = {
        [
            "press",
            "depress",
            "activate",
        ]
    }()

    /// Sample prepositions.
    static let inPrep: String = "in"

    // Note: Removed pushInVerb
}
