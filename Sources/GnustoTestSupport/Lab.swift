import GnustoEngine

// MARK: - Locations

/// A laboratory in which strange experiments are being conducted.
public enum Lab {
    public static let laboratory = Location(
        id: .startRoom,
        .name("Laboratory"),
        .description("A laboratory in which strange experiments are being conducted."),
        .inherentlyLit
    )
}

// MARK: - Items

extension Lab {
    public static let axe = Item(
        id: .axe,
        .name("bloody axe"),
        .synonyms("axe", "ax"),
        .adjectives("bloody", "rusty", "nicked", "gruesome"),
        .isWeapon,
        .requiresTryTake,
        .isTakable,
        .omitDescription,
        .size(25),
        .in(.item(.troll))
    )

    public static let grapes = Item(
        id: "grapes",
        .name("grapes"),
        .description("A bunch of purple grapes."),
        .isPlural,
        .isTakable,
        .in(.startRoom)
    )

    public static let ironSword = Item(
        id: "sword",
        .name("iron sword"),
        .description("A sharp iron sword."),
        .isTakable,
        .isWeapon,
        .in(.player)
    )

    public static let matchStick = Item(
        id: "match",
        .name("wooden match"),
        .description("A wooden match."),
        .isSelfIgnitable,
        .isTakable,
        .in(.player)
    )

    public static let pebble = Item(
        id: .startItem,
        .name("pebble"),
        .description("A wholly unremarkable pebble."),
        .in(.startRoom),
        .isTakable
    )

    public static let torch = Item(
        id: "torch",
        .name("flaming torch"),
        .description("A wooden torch with a bright flame."),
        .isFlammable,
        .isBurning,
        .isLightSource,
        .in(.player)
    )
}

// MARK: - NPC's

extension Lab {
    public static let castleGuard = Item(
        id: "guard",
        .name("castle guard"),
        .description("A stern castle guard."),
        .synonyms("brute", "guard", "bully"),
        .adjectives("surly", "drunken", "bitter"),
        .characterSheet(
            CharacterSheet(
                strength: 13,
                dexterity: 12,
                constitution: 13,
                intelligence: 8,
                wisdom: 6,
                charisma: 9,
                bravery: 13,
                perception: 7,
                luck: 4,
                morale: 9,
                intimidation: 13,
                stealth: 9,
                level: 2,
                classification: .masculine,
                alignment: .lawfulNeutral,
                armorClass: 12,
                consciousness: .drowsy,
                generalCondition: .drunk,
                taunts: [
                    #""I'll ask the questions here!" barks the castle guard."#,
                    #""Submit to my authority!", cries the castle guard."#,
                    #""I'm the one in charge!", bellows the castle guard."#,
                ]
            )
        ),
        .in(.startRoom)
    )

    public static let dragon = Item(
        id: "dragon",
        .name("terrible dragon"),
        .description("A terrible dragon."),
        .characterSheet(
            CharacterSheet(
                strength: 20,
                dexterity: 14,
                constitution: 20,
                intelligence: 20,
                wisdom: 20,
                charisma: 14,
                bravery: 18,
                perception: 18,
                morale: 18,
                accuracy: 18,
                intimidation: 20,
                stealth: 4,
                level: 20,
                alignment: .neutralEvil,
                armorClass: 20,
                health: 400,
                maxHealth: 400
            )
        ),
        .in(.startRoom)
    )

    public static let fairy = Item(
        id: "fairy",
        .name("woodland fairy"),
        .description("A woodland fairy."),
        .characterSheet(
            CharacterSheet(
                strength: 8,
                dexterity: 20,
                constitution: 12,
                intelligence: 18,
                wisdom: 16,
                charisma: 18,
                bravery: 16,
                perception: 18,
                luck: 18,
                morale: 16,
                accuracy: 18,
                intimidation: 4,
                stealth: 18,
                level: 4,
                classification: .feminine,
                alignment: .chaoticGood,
                armorClass: 4,
                health: 16,
                maxHealth: 16
            )
        ),
        .in(.startRoom)
    )

    public static let knight = Item(
        id: "knight",
        .name("knight"),
        .description("A noble knight."),
        .characterSheet(
            CharacterSheet(
                strength: 17,
                dexterity: 16,
                constitution: 17,
                intelligence: 13,
                wisdom: 11,
                charisma: 17,
                bravery: 16,
                perception: 13,
                luck: 15,
                morale: 16,
                accuracy: 14,
                intimidation: 11,
                stealth: 5,
                level: 2,
                classification: .masculine,
                alignment: .lawfulGood,
                armorClass: 15,
                taunts: [
                    #""Take that!", cries the noble knight."#,
                    #""Cease, you... rapscallion!", cries the good sir knight."#,
                ]
            )
        ),
        .in(.startRoom)
    )

    public static let merchant = Item(
        id: "merchant",
        .name("traveling merchant"),
        .description("A traveling merchant."),
        .characterSheet(.default),
        .in(.startRoom)
    )

    public static let princess = Item(
        id: "princess",
        .name("princess"),
        .description("A beautiful princess."),
        .characterSheet(
            CharacterSheet(
                dexterity: 14,
                intelligence: 16,
                wisdom: 16,
                charisma: 18,
                perception: 14,
                luck: 17,
                level: 2,
                classification: .feminine,
                alignment: .lawfulNeutral
            )
        ),
        .in(.startRoom)
    )

    public static let troll = Item(
        id: .troll,
        .name("fierce troll"),
        .adjectives("angry", "fearsome", "terrible", "grotesque"),
        .synonyms("beast", "monster", "creature"),
        .description("A fierce troll blocking your way."),
        .characterSheet(
            CharacterSheet(
                strength: 14,
                dexterity: 8,
                constitution: 12,
                intelligence: 6,
                wisdom: 5,
                charisma: 1,
                bravery: 12,
                perception: 8,
                luck: 6,
                morale: 12,
                accuracy: 10,
                intimidation: 12,
                stealth: 4,
                level: 1,
                classification: .masculine,
                alignment: .neutralEvil,
                armorClass: 10,
                taunts: [
                    """
                    The troll spits in your face, grunting "Better luck next time"
                    in a rather barbarous accent.
                    """,
                    "The troll laughs at your puny gesture.",
                    """
                    The troll says something, probably uncomplimentary, in
                    his guttural tongue.
                    """,
                ]
            )
        ),
        .isTransparent,
        .requiresTryTake,
        .in(.startRoom)
    )

    public static let wizard = Item(
        id: "wizard",
        .name("Spandalf"),
        .synonyms("wizard", "mage"),
        .adjectives("clever", "wise"),
        .description("A wise old wizard."),
        .characterSheet(.wise),
        .in(.startRoom)
    )
}

extension Item {
    public var fighting: Item {
        var fighter = self
        if case .characterSheet(var fightSheet) = fighter.properties[.characterSheet] {
            fightSheet.isFighting = true
            fighter.properties[.characterSheet] = .characterSheet(fightSheet)
            return fighter
        }
        return self
    }
}

// MARK: - Common Test IDs

extension ItemID {
    public static let axe: ItemID = "axe"
    public static let startItem: ItemID = "startItem"
    public static let troll: ItemID = "troll"
}

extension LocationID {
    public static let startRoom: LocationID = "startRoom"
}
