import Foundation

/// Generates phrases related to digging.
enum Dig: Generator {
    /// Generates a random phrase for digging.
    ///
    /// Examples:
    /// - "dig in the loose sand"
    /// - "dig ground with rusty shovel"
    /// - "excavate mound"
    static func any() -> Phrase {
        // Combine relevant modifiers
        let surfaceModCombined = Array(Set(Take.objectMod + surfaceMod))
        let toolModCombined = Array(Set(Take.objectMod + toolMod))

        return any(
            // --- Simple Dig ---
            phrase( // dig [mod] surface
                .verb(digVerb.rnd),
                .modifier(surfaceModCombined.rnd),
                .directObject(diggableSurface.rnd)
            ),
            phrase( // dig surface
                .verb(digVerb.rnd),
                .directObject(diggableSurface.rnd)
            ),

            // --- Dig In ---
            phrase( // dig in the [mod] surface
                .verb(digVerb.rnd),
                .preposition(inPrep),
                .determiner("the"),
                .modifier(surfaceModCombined.rnd),
                .directObject(diggableSurface.rnd)
            ),
            phrase( // dig in surface
                .verb(digVerb.rnd),
                .preposition(inPrep),
                .directObject(diggableSurface.rnd)
            ),

            // --- Dig With Tool ---
            phrase( // dig [mod] surface with [mod] tool
                .verb(digVerb.rnd),
                .modifier(surfaceModCombined.rnd),
                .directObject(diggableSurface.rnd),
                .preposition(withPrep),
                .modifier(toolModCombined.rnd),
                .indirectObject(diggingTool.rnd)
            ),
            phrase( // dig surface with tool
                .verb(digVerb.rnd),
                .directObject(diggableSurface.rnd),
                .preposition(withPrep),
                .indirectObject(diggingTool.rnd)
            ),

            // --- Dig In With Tool ---
            phrase( // dig in [mod] surface with [mod] tool
                .verb(digVerb.rnd),
                .preposition(inPrep),
                .modifier(surfaceModCombined.rnd),
                .directObject(diggableSurface.rnd),
                .preposition(withPrep),
                .modifier(toolModCombined.rnd),
                .indirectObject(diggingTool.rnd)
            ),
            phrase( // dig in surface with tool
                .verb(digVerb.rnd),
                .preposition(inPrep),
                .directObject(diggableSurface.rnd),
                .preposition(withPrep),
                .indirectObject(diggingTool.rnd)
            )
        )
    }
}

// MARK: - Samples

extension Dig {
    // --- Verbs ---
    static let digVerb: [String] = {
        [
            "dig",
            "burrow",
            "excavate",
            "scoop",
            "tunnel",
        ]
    }()

    // --- Prepositions ---
    static let inPrep: String = "in"
    static let withPrep: String = "with"

    // --- Objects ---

    /// Surfaces or locations that can be dug.
    static let diggableSurface: [String] = {
        [
            "area",
            "ash",
            "bank",
            "clay",
            "dirt",
            "dune",
            "earth",
            "floor", // From Examine
            "gravel",
            "ground", // From Examine
            "hole", // From Go/Examine/Traverse
            "humus",
            "ice",
            "mound", // From Traverse
            "mud",
            "patch",
            "path",
            "pit", // From Traverse
            "sand",
            "site",
            "snow",
            "soil",
            "spot",
            "turf",
        ]
    }()

    /// Tools used for digging.
    static let diggingTool: [String] = {
        [
            "axe", // From Take/Attack
            "bayonet",
            "claws",
            "crowbar",
            "dagger", // From Take/Attack
            "fingers",
            "hands",
            "hoe",
            "knife", // From Take/Attack
            "mattock",
            "pick",
            "pickaxe",
            "scoop", // Also a verb
            "shovel",
            "spade",
            "stick",
            "sword", // From Take/Attack
            "trowel",
        ]
    }()

    // --- Modifiers ---

    /// Modifiers specific to diggable surfaces.
    static let surfaceMod: [String] = {
        [
            "bare",
            "barren",
            "damp",
            "dark", // From Take/Toggle
            "deep",
            "disturbed",
            "dry", // From Burn
            "dusty", // From Take
            "fertile",
            "frozen",
            "gravelly",
            "hard", // From Consume
            "icy", // From Consume
            "level",
            "loose", // From Wear
            "muddy",
            "packed",
            "patchy",
            "powdery",
            "rich",
            "rocky",
            "sandy",
            "shallow",
            "slimy", // From Go
            "soft",
            "solid",
            "soggy",
            "stony",
            "wet",
        ]
    }()

    /// Modifiers specific to digging tools (some overlap with Take.objectMod).
    static let toolMod: [String] = {
        [
            "blunt",
            "broken", // From Take
            "chipped", // From Take
            "crude",
            "dull", // From Take
            "heavy", // From Take/Wear
            "improvised",
            "large", // From Take
            "light", // From Take/Wear
            "long", // From Take/Wear
            "metal", // From Take
            "makeshift",
            "pointed", // From Take
            "rusty", // From Take
            "sharp", // From Take
            "short",
            "small", // From Take
            "sturdy", // From Take
            "wooden", // From Take
        ]
    }()
}
