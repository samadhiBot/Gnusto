import Foundation

/// Generates phrases related to putting an item onto a surface.
enum PutOnSurface: Generator {
    /// Generates a random phrase for putting an item onto a surface.
    ///
    /// Examples:
    /// - "put the book on the wooden table"
    /// - "set lamp onto shelf"
    /// - "place the statue atop the pedestal"
    static func any() -> Phrase {
        // Reuse modifiers from Take
        let itemMod = Take.objectMod
        let surfaceMod = Take.objectMod

        return any(
            // verb [mod] item prep [mod] surface
            phrase(
                .verb(putVerb.rnd),
                .modifier(itemMod.rnd),
                .directObject(itemObject.rnd),
                .preposition(prep.rnd),
                .modifier(surfaceMod.rnd),
                .indirectObject(surfaceObject.rnd)
            ),
            // verb item prep surface
            phrase(
                .verb(putVerb.rnd),
                .directObject(itemObject.rnd),
                .preposition(prep.rnd),
                .indirectObject(surfaceObject.rnd)
            ),
            // verb [mod] item prep the [mod] surface
            phrase(
                .verb(putVerb.rnd),
                .modifier(itemMod.rnd),
                .directObject(itemObject.rnd),
                .preposition(prep.rnd),
                .determiner("the"),
                .modifier(surfaceMod.rnd),
                .indirectObject(surfaceObject.rnd)
            ),
            // verb item prep the surface
            phrase(
                .verb(putVerb.rnd),
                .directObject(itemObject.rnd),
                .preposition(prep.rnd),
                .determiner("the"),
                .indirectObject(surfaceObject.rnd)
            )
        )
    }
}

// MARK: - Samples

extension PutOnSurface {
    /// Sample verbs for putting something onto a surface.
    static let putVerb: [String] = {
        [
            "lean",
            "place",
            "position",
            "put",
            "rest",
            "set",
        ]
    }()

    /// Sample prepositions used.
    static let prep: [String] = {
        [
            "on",
            "onto",
            "atop",
            "upon",
        ]
    }()

    /// Sample items to be put on a surface (direct objects).
    static let itemObject: [String] = {
        // Generally, any takeable object
        Take.takeableObject
    }()

    /// Sample surfaces (indirect objects).
    static let surfaceObject: [String] = {
        // Combine surfaces from other generators + specifics
        Array(
            Set(
                Traverse.surfaceObject +
                Examine.scenery.filter {
                    ![
                        "door",
                        "window",
                        "crack",
                        "hole",
                        "opening",
                        "passage",
                        "shadow",
                        "wall",
                        "gate"
                    ].contains($0)
                } + // Filter out non-surfaces
                Dig.diggableSurface.filter {
                    [
                        "ground",
                        "floor",
                        "ice",
                        "rock",
                        "snow"
                    ].contains($0)
                } + // Some diggable things are surfaces
                [
                    // Specific additions
                    "bed",
                    // From Traverse.underObject
                    "bench",
                    // From Traverse.underObject
                    "block",
                    // From Traverse.surfaceObject
                    "body",
                    "counter",
                    // From Traverse.surfaceObject
                    "desk",
                    // From Examine/Traverse.underObject
                    "dresser",
                    "ground",
                    // From Examine/Dig.diggableSurface
                    "mantel",
                    "mat",
                    "nightstand",
                    "stand",
                    "windowsill",
                ]
            )
        )
    }()

    // Note: Reusing `Take.objectMod` for modifiers.

    // --- Added for DO/IO Training ---
    // Removed unused dioSamples function
    // --- End Added ---
}
