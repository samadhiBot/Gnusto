import Foundation

/// Generates phrases related to closing objects.
enum Close: Generator {
    /// Generates a random phrase for closing an object.
    ///
    /// Examples:
    /// - "close the heavy door"
    /// - "shut window"
    /// - "close the dusty book"
    static func any() -> Phrase {
        // Reuse existing modifiers
        let objectMod = Take.objectMod

        return any(
            phrase( // verb the [mod] object
                .verb(closeVerb.rnd),
                .determiner("the"),
                .modifier(objectMod.rnd),
                .directObject(closeableObject.rnd)
            ),
            phrase( // verb object
                .verb(closeVerb.rnd),
                .directObject(closeableObject.rnd)
            ),
            phrase( // verb a [mod] object
                .verb(closeVerb.rnd),
                .determiner("a"),
                .modifier(objectMod.rnd),
                .directObject(closeableObject.rnd)
            ),
            phrase( // verb a object
                .verb(closeVerb.rnd),
                .determiner("a"),
                .directObject(closeableObject.rnd)
            )
        )
    }
}

// MARK: - Samples

extension Close {
    /// Sample verbs for closing.
    static var closeVerb: [String] {
        [
            "close",
            "shut",
        ]
    }

    /// Sample objects that can be closed.
    /// Often the inverse of openable objects.
    static var closeableObject: [String] {
        // Combine potentially closeable objects from other generators + specifics
        Array(Set(
            Examine.scenery.filter { ["door", "window", "gate", "hatch", "trapdoor", "cabinet", "chest", "lock", "curtain"].contains($0) } +
            Take.takeableObject.filter { ["book", "box", "bottle", "journal", "letter", "locket", "map", "scroll"].contains($0) } +
            Traverse.containerSpaceObject.filter { ["barrel", "bin", "box", "cabinet", "closet", "coffin", "container", "crate", "dumpster", "locker", "sack", "sarcophagus", "trunk", "wardrobe"].contains($0) } +
            [
                // Specific additions
                "bag",
                "briefcase",
                "cage",
                "casket",
                "clamp",
                "clasp",
                "cover",
                "drawer",
                "enclosure",
                "envelope",
                "eyes", // Can close eyes
                "eyelids",
                "flap",
                "hatchway",
                "jar",
                "lid",
                "mouth", // Can close mouth
                "panel",
                "pocket",
                "portfolio",
                "pouch",
                "purse",
                "safe",
                "shutter",
                "valve", // From Toggle
                "vault",
                "visor",
                "wallet",
            ]
        ))
    }

    // Note: Reusing `Take.objectMod` for modifiers.
}
