import Foundation

/// Generates phrases related to throwing or tossing objects.
enum Throw: Generator {
    /// Generates a random phrase for throwing an object.
    ///
    /// Examples:
    /// - "throw the sharp knife"
    /// - "toss the rock at the troll"
    /// - "throw grenade"
    static func any() -> Phrase {
        let item = Take.takeableObject.rnd
        let itemMod = Take.objectMod.rnd
        let target = Attack.enemy.rnd
        let targetMod = Attack.enemyMod.rnd

        return any(
            phrase(.verb(throwVerb.rnd), .directObject(item)),
            phrase(.verb(throwVerb.rnd), .modifier(itemMod), .directObject(item)),
            phrase(.verb(throwVerb.rnd), .directObject(item), .preposition("at"), .directObject(target)),
            phrase(.verb(throwVerb.rnd), .modifier(itemMod), .directObject(item), .preposition("at"), .modifier(targetMod), .indirectObject(target)),
            // Added: Double Modifiers
            phrase( // throw [mod1] [mod2] item
                .verb(throwVerb.rnd),
                .modifier(itemMod), // Already random from var def
                .modifier(itemMod), // Already random from var def
                .directObject(item)
            ),
            phrase( // throw [item] at [mod1] [mod2] target
                .verb(throwVerb.rnd),
                .directObject(item),
                .preposition("at"),
                .modifier(targetMod), // Already random from var def
                .modifier(targetMod), // Already random from var def
                .indirectObject(target)
            ),
            // --- Refactored Phrasal ---
            phrase( // throw away [item] -> Verb: throw, Prep: away, DO: item
                .verb(throwVerb.rnd),
                .preposition(awayPrep), // Particle immediately after verb
                .directObject(item)
            ),
            phrase( // throw [item] away -> Verb: throw, DO: item, Prep: away
                .verb(throwVerb.rnd),
                .directObject(item),
                .preposition(awayPrep) // Particle after object
            ),
            // --- End Refactored ---
            // --- Throw Direction (Added) ---
            phrase( // throw [item] [direction]
                .verb(throwVerb.rnd),
                .directObject(item),
                .preposition(Go.direction.rnd) // Direction as Preposition
            ),
            phrase( // throw [mod] [item] [direction]
                .verb(throwVerb.rnd),
                .modifier(itemMod),
                .directObject(item),
                .preposition(Go.direction.rnd) // Direction as Preposition
            ),
            // --- Specific Direction Patterns ---
            // phrase(.verb("throw"), .directObject(item), .preposition("north")),
            // phrase(.verb("throw"), .directObject(item), .preposition("south")),
            // phrase(.verb("throw"), .directObject(item), .preposition("east")),
            // phrase(.verb("throw"), .directObject(item), .preposition("west")),
            // phrase(.verb("throw"), .directObject(item), .preposition("up")),
            // phrase(.verb("throw"), .directObject(item), .preposition("down"))
        )
    }
}

// MARK: - Samples

extension Throw {
    /// Sample verbs for throwing.
    static let throwVerb: [String] = {
        [
            "chuck",
            "fling",
            "heave", // Also in Pull
            "hurl",
            "launch",
            "lob",
            "pitch",
            "throw",
            "toss",
        ]
    }()

    /// Preposition for throwing at a target.
    static let atPrep: String = "at"

    /// Added for Test Failures
    static let throwAwayVerb: String = "throw away"

    /// Added for Test Failures
    static let awayPrep: String = "away"

    // Note: Object, target, direction lists and modifiers reused
}
