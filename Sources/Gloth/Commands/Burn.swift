import Foundation

/// Generates phrases related to burning or igniting objects.
enum Burn: Generator {
    /// Generates a random phrase for burning an object.
    ///
    /// Examples:
    /// - "burn the dry leaves"
    /// - "ignite the torch"
    /// - "torch the wooden effigy"
    /// - "incinerate paper"
    static func any() -> Phrase {
        // Combine relevant modifiers and add burn-specific ones
        let allModifiers = Take.objectMod + burnSpecificMod
        let burnableMod = Array(Set(allModifiers))

        return any(
            phrase( // verb the [mod] object
                .verb(burnVerb.rnd),
                .determiner("the"),
                .modifier(burnableMod.rnd),
                .directObject(burnableObject.rnd)
            ),
            phrase( // verb object
                .verb(burnVerb.rnd),
                .directObject(burnableObject.rnd)
            ),
            phrase( // verb a [mod] object
                .verb(burnVerb.rnd),
                .determiner("a"),
                .modifier(burnableMod.rnd),
                .directObject(burnableObject.rnd)
            ),
            phrase( // verb a object
                .verb(burnVerb.rnd),
                .determiner("a"),
                .directObject(burnableObject.rnd)
            )
        )
    }
}

// MARK: - Samples

extension Burn {
    /// Sample verbs for burning or igniting.
    static let burnVerb: [String] = {
        [
            "burn",
            "ignite",
            "incinerate",
            "light", // Overlaps with Toggle, but context is different
            "set fire to", // Multi-word
            "torch", // Can be a verb too
        ]
    }()

    /// Sample burnable objects.
    static let burnableObject: [String] = {
        [
            "book", // From Take
            "branch", // From Traverse
            "brush",
            "candle", // From Take/Toggle
            "canvas",
            "cloth",
            "corpse", // From Take
            "curtain", // From Examine
            "documents",
            "doll",
            "effigy",
            "fabric",
            "firewood",
            "fuse",
            "grass",
            "hay",
            "incense",
            "kindling",
            "leaves",
            "letter", // From Take
            "log", // From Take/Go/Traverse
            "map", // From Take
            "match", // From Toggle
            "note", // From Take
            "oil",
            "paper", // From Take
            "parchment",
            "rags",
            "rope", // From Take
            "rubbish",
            "scroll", // From Take
            "straw",
            "tapestry", // From Examine
            "tinder",
            "torch", // From Take/Toggle (item)
            "trash",
            "twigs",
            "wick",
            "wood",
            "wool", // From Wear
        ]
    }()

    /// Sample modifiers relevant to burnable objects.
    static let burnSpecificMod: [String] = {
        [
            "brittle", // From Take
            "dry",
            "flammable",
            "greasy",
            "oily",
            "old",
            "paper", // From Take (as modifier)
            "tattered", // From Wear
            "thin", // From Take
            "wooden", // From Take
        ]
    }()
}
