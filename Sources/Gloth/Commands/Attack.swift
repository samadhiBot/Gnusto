import Foundation

enum Attack: Generator {
    static func any() -> Phrase {
        let enemy = Self.enemy.rnd
        let enemyMod = Self.enemyMod.rnd
        let weapon = Self.weapon.rnd
        let weaponMod = Self.weaponMod.rnd
        let verb = Self.attack.rnd

        return any(
            // Attack enemy with weapon (full pattern)
            phrase(
                .verb(verb),
                .determiner("the"),
                .modifier(enemyMod),
                .directObject(enemy),
                .preposition("with"),
                .determiner("the"),
                .modifier(weaponMod),
                .indirectObject(weapon)
            ),
            // Attack the modified enemy (existing)
            phrase(
                .verb(verb),
                .determiner("the"),
                .modifier(enemyMod),
                .directObject(enemy)
            ),
            // Attack enemy (Added: No determiner/modifier)
            phrase(
                .verb(verb),
                .directObject(enemy)
            ),
            // Attack the enemy (Added: Determiner, no modifier)
            phrase(
                .verb(verb),
                .determiner("the"),
                .directObject(enemy)
            ),
            // Attack modified enemy (Added: Modifier, no determiner)
            phrase(
                .verb(verb),
                .modifier(enemyMod),
                .directObject(enemy)
            ),
            // Duplicate existing simple patterns for more weight
            phrase(
                .verb(verb),
                .determiner("the"),
                .modifier(enemyMod),
                .directObject(enemy)
            ),
            phrase(
                .verb(verb),
                .directObject(enemy)
            ),
            phrase(
                .verb(verb),
                .determiner("the"),
                .directObject(enemy)
            ),
            phrase(
                .verb(verb),
                .modifier(enemyMod),
                .directObject(enemy)
            )
        )
    }
}

// MARK: - Samples

extension Attack {
    static let attack: [String] = {
        [
            "assassinate",
            "attack",
            "bite",
            "break",
            "crush",
            "destroy",
            "disembowel",
            "divide",
            "eviscerate",
            "execute",
            "exterminate",
            "flay",
            "gore",
            "graze",
            "headbutt",
            "hit",
            "impale",
            "insult",
            "jab",
            "kill",
            "pierce",
            "pummel",
            "punch",
            "slam",
            "slay",
            "slice",
            "smash",
            "squeeze",
            "stab",
            "stomp",
            "strike",
        ]
    }()

    static let anyone: [String] = {
        enemy + [
            "me",
            "myself",
            "self",
        ]
    }()

    static let enemy: [String] = {
        [
            "adventurer",
            "barbarian",
            "bat",
            "bear",
            "beholder",
            "centaur",
            "chest",
            "demon",
            "dragon",
            "drow",
            "elemental",
            "elf",
            "fighter",
            "goblin",
            "half-orc",
            "imp",
            "kobald",
            "monster",
            "orb",
            "orc",
            "skeleton",
            "thief",
            "troll",
            "witch",
            "wizard",
            "zombie",
        ]
    }()

    static let enemyMod: [String] = {
        [
            "angry",
            "annoying",
            "barbaric",
            "biting",
            "bloody",
            "bumbling",
            "chortling",
            "clumsy",
            "condescending",
            "cunning",
            "evil",
            "fierce",
            "gluttonous",
            "greedy",
            "impatient",
            "insatiable",
            "jovial",
            "lustful",
            "maddening",
            "ostentatious",
            "proud",
            "rancid",
            "shifty",
            "sinister",
            "slovenly",
            "sly",
            "trembling",
            "vicious",
        ]
    }()

    static let weapon: [String] = {
        [
            "axe",
            "baton",
            "chainsaw",
            "crossbow",
            "dagger",
            "greataxe",
            "grenade",
            "hammer",
            "hilt",
            "knife",
            "letter-opener",
            "mace",
            "machete",
            "morning-star",
            "pike",
            "rapier",
            "salami",
            "scepter",
            "scimitar",
            "shortsword",
            "spatula",
            "spear",
            "spork",
            "staff",
            "sword",
        ]
    }()

    static let weaponMod: [String] = {
        [
            "bloody",
            "brittle",
            "broken",
            "chipped",
            "cracked",
            "cursed",
            "dull",
            "edged",
            "enchanted",
            "fiery",
            "glinting",
            "glowing",
            "golden",
            "grim",
            "hilted",
            "iron",
            "jagged",
            "knotted",
            "laminated",
            "long",
            "metal",
            "pointed",
            "pungent",
            "rusty",
            "sharp",
            "shimmering",
            "silver",
            "slicing",
            "spectral",
            "spiked",
            "sturdy",
            "swift",
            "tarnished",
            "thin",
            "unholy",
            "vibrant",
        ]
    }()
}
