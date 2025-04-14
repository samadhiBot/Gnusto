import Foundation

/// Generates phrases related to pulling, dragging or carrying objects.
enum Pull: Generator {
    /// Generates a random phrase for pulling an object.
    ///
    /// Examples:
    /// - "pull the heavy lever"
    /// - "drag crate"
    /// - "yank the stuck door"
    /// - "carry the torch"
    static func any() -> Phrase {
        // Reuse modifiers from Take
        let objectMod = Take.objectMod

        return any(
            phrase( // verb the [mod] object
                .verb(pullVerb.rnd),
                .determiner("the"),
                .modifier(objectMod.rnd),
                .directObject(pullableObject.rnd)
            ),
            phrase( // verb object
                .verb(pullVerb.rnd),
                .directObject(pullableObject.rnd)
            )
        )
    }
}

// MARK: - Samples

extension Pull {
    /// Sample verbs for pulling, dragging, carrying.
    static var pullVerb: [String] {
        [
            "pull",
            "drag",
            "draw",
            "haul",
            "heave",
            "lug",
            "move", // Can sometimes mean pull
            "tow",
            "tug",
            "yank",
            // "carry" is slightly different semantically (implies holding while moving)
            // but often parsed similarly initially. Could be separated later.
            "carry",
        ]
    }

    /// Sample objects that can be pulled, dragged or carried.
    static var pullableObject: [String] {
        // Often similar to pushable, but some differences (e.g., levers, ropes, carried items)
        Array(Set(
            Push.pushableObject.filter { !["button", "switch", "panel"].contains($0) } + // Reuse pushable, remove things not typically pulled
            Take.takeableObject.filter { ["bag", "backpack", "body", "briefcase", "bundle", "case", "chain", "chest", "corpse", "log", "net", "sack", "satchel", "sled", "stone", "suitcase", "torch", "trunk", "weapon"].contains($0) } + // Items often carried/dragged
            Examine.scenery.filter { ["chain", "curtain", "lever", "rope", "switch", "tapestry", "trapdoor"].contains($0) } +
            [
                // Specific additions
                "bellpull",
                "boat", // From Traverse
                "cable",
                "cord",
                "handle",
                "harness",
                "line",
                "oar",
                "plug",
                "ring", // From Take/Wear
                "strap",
                "string",
                "switch", // Also pushable
                "trigger",
                "winch",
                "wire",
            ]
        ))
    }

    // Note: Reusing `Take.objectMod` for modifiers.
}
