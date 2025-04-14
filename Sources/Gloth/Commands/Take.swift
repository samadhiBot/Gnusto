import Foundation

/// Generates phrases related to taking or getting objects.
enum Take: Generator {
    /// Generates a random phrase for taking an object.
    ///
    /// Examples:
    /// - "take the rusty sword"
    /// - "get potion"
    /// - "pick up the glinting key"
    static func any() -> Phrase {
        let takeableObject = Self.takeableObject
        let objectMod = Self.objectMod
        let enemy = Attack.enemy
        let enemyMod = Attack.enemyMod

        return any(
            phrase(
                .verb(takeVerb.rnd),
                .determiner("the"),
                .modifier(objectMod.rnd),
                .directObject(takeableObject.rnd)
            ),
            phrase(
                .verb(takeVerb.rnd),
                .directObject(takeableObject.rnd)
            ),
            phrase(
                .verb(takeVerb.rnd),
                .determiner("a"),
                .modifier(objectMod.rnd),
                .directObject(takeableObject.rnd)
            ),
            phrase(
                .verb(getVerb),
                .directObject(takeableObject.rnd)
            ),
            phrase(
                .verb(getVerb),
                .determiner("the"),
                .directObject(takeableObject.rnd)
            ),
            phrase(
                .verb(getVerb),
                .modifier(objectMod.rnd),
                .directObject(takeableObject.rnd)
            ),
            phrase(
                .verb(getVerb),
                .modifier(objectMod.rnd),
                .directObject(takeableObject.rnd)
            ),
            phrase(
                .verb(getVerb),
                .determiner("the"),
                .directObject(takeableObject.rnd)
            ),
            phrase(
                .verb(getVerb),
                .directObject(takeableObject.rnd)
            ),
            phrase(
                .verb(takeVerb.rnd),
                .determiner("the"),
                .modifier(objectMod.rnd),
                .directObject(takeableObject.rnd),
                .preposition("from"),
                .determiner("the"),
                .modifier(Attack.enemyMod.rnd),
                .indirectObject(Attack.enemy.rnd)
            ),
            phrase( // pick up [object]
                .verb(pickVerb),
                .preposition(upPrep),
                .directObject(takeableObject.rnd)
            ),
            phrase( // pick [object] up
                .verb(pickVerb),
                .directObject(takeableObject.rnd),
                .preposition(upPrep)
            ),
            phrase( // pick up the [mod][mod] object
                .verb(pickVerb),
                .preposition(upPrep),
                .determiner("the"),
                .modifier(objectMod.rnd),
                .modifier(objectMod.rnd),
                .directObject(takeableObject.rnd)
            )
        )
    }

    static let pickVerb: String = "pick"
    static let getVerb: String = "get"
    static let upPrep: String = "up"
    // static let pickUpVerb: String = "pick up" // Removed combined verb
}

// MARK: - Samples

extension Take {
    /// Sample verbs for taking an object.
    static var takeVerb: [String] {
        [
            "get",
            "grab",
            "pick",
            "steal",
            "take",
        ]
    }

    /// Sample modifiers for takeable objects.
    static var objectMod: [String] {
        // Borrowed some from Attack/Go and added others
        [
            "bloody",
            "brittle",
            "broken",
            "chipped",
            "cracked",
            "creaking",
            "cursed",
            "dark",
            "dull",
            "dusty",
            "edged",
            "enchanted",
            "fiery",
            "glinting",
            "glowing",
            "golden",
            "grim",
            "heavy",
            "iron",
            "jagged",
            "knotted",
            "large",
            "light",
            "long",
            "metal",
            "ornate",
            "pointed",
            "pungent",
            "rusty",
            "sharp",
            "shimmering",
            "silver",
            "slimy",
            "small",
            "spectral",
            "spiked",
            "sturdy",
            "swift",
            "tarnished",
            "terrifying",
            "thin",
            "unfathomable",
            "unholy",
            "vibrant",
            "wooden",
        ]
    }

    /// Sample objects that can be taken.
    static var takeableObject: [String] {
        // Borrowed some from Attack/Go weapons/enemies and added common items
        [
            "amulet",
            "apple",
            "axe",
            "baton",
            "book",
            "bottle",
            "box",
            "bread",
            "candle",
            "chainsaw",
            "chalice",
            "coin",
            "corpse", // Why not?
            "crossbow",
            "crown",
            "crystal",
            "dagger",
            "elixir",
            "food",
            "gem",
            "glove",
            "greataxe",
            "grenade",
            "hammer",
            "helmet",
            "herb",
            "hilt",
            "idol",
            "key",
            "knife",
            "lamp",
            "lantern",
            "letter",
            "letter-opener",
            "mace",
            "machete",
            "map",
            "meat",
            "mirror",
            "money",
            "morning-star",
            "note",
            "orb",
            "paper",
            "pike",
            "potion",
            "rapier",
            "ring",
            "rock",
            "rope",
            "ruby",
            "salami",
            "scepter",
            "scimitar",
            "scroll",
            "shield",
            "shortsword",
            "skull",
            "spatula",
            "spear",
            "spork",
            "staff",
            "stone",
            "sword",
            "tablet",
            "torch",
            "wand",
            "water",
            "whistle",
        ]
    }
}
