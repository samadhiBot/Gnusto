import Foundation

/// Generates phrases related to examining objects or scenery.
enum Examine: Generator {
    /// Generates a random phrase for examining something.
    ///
    /// Examples:
    /// - "examine the dusty scroll"
    /// - "look at the wooden door"
    /// - "x chest"
    /// - "describe strange symbol"
    static func any() -> Phrase {
        // Combine objects from other generators and add scenery
        let allObjects = Take.takeableObject + Consume.foodObject + Consume.drinkObject + Attack.enemy + Go.climbable + Go.climbThroughable + scenery
        let examinableObject = Array(Set(allObjects)) // Ensure uniqueness

        // Combine modifiers
        let allModifiers = Take.objectMod + Consume.foodMod + Consume.drinkMod + Attack.enemyMod + Go.goMod
        let objectMod = Array(Set(allModifiers)) // Ensure uniqueness

        return any(
            // Standard examine: verb det mod obj
            phrase(
                .verb(examineVerb.rnd),
                .determiner("the"),
                .modifier(objectMod.rnd),
                .directObject(examinableObject.rnd)
            ),
            // Standard examine: verb obj (e.g., "x chest")
            phrase(
                .verb(examineVerb.rnd),
                .directObject(examinableObject.rnd)
            ),
            // Standard examine: verb det obj
            phrase(
                .verb(examineVerb.rnd),
                .determiner("the"),
                .directObject(examinableObject.rnd)
            ),
            // Standard examine: verb "a" mod obj
            phrase(
                .verb(examineVerb.rnd),
                .determiner("a"),
                .modifier(objectMod.rnd),
                .directObject(examinableObject.rnd)
            ),
            // Standard examine: verb "a" obj
            phrase(
                .verb(examineVerb.rnd),
                .determiner("a"),
                .directObject(examinableObject.rnd)
            ),
            // Look at: verb prep det mod obj
            phrase(
                .verb(lookVerb),
                .preposition(preposition),
                .determiner("the"),
                .modifier(objectMod.rnd),
                .directObject(examinableObject.rnd)
            ),
            // Look at: verb prep obj
            phrase(
                .verb(lookVerb),
                .preposition(preposition),
                .directObject(examinableObject.rnd)
            ),
            // Look at: verb prep det obj
            phrase(
                .verb(lookVerb),
                .preposition(preposition),
                .determiner("the"),
                .directObject(examinableObject.rnd)
            ),
            // Look at: verb prep "a" mod obj
            phrase(
                .verb(lookVerb),
                .preposition(preposition),
                .determiner("a"),
                .modifier(objectMod.rnd),
                .directObject(examinableObject.rnd)
            ),
            // Look at: verb prep "a" obj
            phrase(
                .verb(lookVerb),
                .preposition(preposition),
                .determiner("a"),
                .directObject(examinableObject.rnd)
            ),

            // --- Look Under ---
            phrase( // look under the [mod] object
                .verb(lookVerb),
                .preposition(underPrep),
                .determiner("the"),
                .modifier(objectMod.rnd),
                .directObject(Traverse.underObject.rnd)
            ),
            phrase( // look under object
                .verb(lookVerb),
                .preposition(underPrep),
                .directObject(Traverse.underObject.rnd)
            )
        )
    }
}

// MARK: - Samples

extension Examine {
    /// Sample verbs for examining (excluding "look at").
    static var examineVerb: [String] {
        [
            "describe",
            "examine",
            "inspect",
            "x", // Abbreviation for examine
        ]
    }

    /// The verb "look", used with "at".
    static var lookVerb: String { "look" }

    /// Preposition used with "look".
    static var preposition: String { "at" }

    /// Preposition used for looking under things.
    static var underPrep: String { "under" }

    /// Sample scenery items that can be examined.
    static var scenery: [String] {
        [
            "altar",
            "button",
            "cabinet",
            "carpet",
            "ceiling",
            "chair",
            "chasm",
            "chest", // Also in Attack.enemy, Go.climbable
            "chimney", // Also in Go.climbable
            "crack",
            "curtain",
            "desk",
            "door",
            "drawing",
            "floor",
            "footprint",
            "fountain",
            "gate",
            "grate",
            "ground",
            "hatch", // Also in Go.climbThroughable
            "hole", // Also in Go.climbThroughable
            "inscription",
            "lever",
            "lock",
            "machine",
            "mechanism",
            "opening", // Also in Go.climbThroughable
            "painting",
            "passage",
            "pedestal",
            "picture",
            "pillar",
            "plaque",
            "pool",
            "portrait",
            "poster",
            "rune",
            "shadow",
            "shelf",
            "sign",
            "slot",
            "stain",
            "stairs", // Also in Go.climbable
            "statue",
            "symbol",
            "table",
            "tapestry",
            "throne",
            "trapdoor", // Also in Go.climbThroughable
            "wall", // Also in Go.climbable
            "window", // Also in Go.climbThroughable
            "writing",
        ]
    }
}
