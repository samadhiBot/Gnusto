import GnustoEngine

// MARK: - Locations

/// A test laboratory containing various items and NPCs for testing interactive fiction mechanics.
///
/// The `Lab` provides a standardized testing environment with a single room containing
/// a diverse collection of items and characters that cover most common IF scenarios.
public enum Lab {
    /// A well-lit laboratory room that serves as the primary testing location.
    ///
    /// This location is inherently lit and contains various test items and NPCs,
    /// making it ideal for testing game mechanics without worrying about darkness.
    public static let laboratory = Location(.startRoom)
        .name("Laboratory")
        .description("A laboratory in which strange experiments are being conducted.")
        .inherentlyLit
}

// MARK: - Items

extension Lab {
    /// A bloody axe weapon carried by the troll.
    ///
    /// This item demonstrates weapon mechanics and the `requiresTryTake` flag,
    /// making it more challenging to obtain. It has multiple synonyms and adjectives
    /// for testing vocabulary parsing.
    public static let axe = Item(.axe)
        .name("bloody axe")
        .synonyms("axe", "ax")
        .adjectives("bloody", "rusty", "nicked", "gruesome")
        .isWeapon
        .requiresTryTake
        .isTakable
        .omitDescription
        .size(25)
        .in(.item(.troll))

    /// A bunch of purple grapes for testing plural item handling.
    ///
    /// This item tests the plural flag functionality and provides a simple
    /// takeable food item for testing consumption mechanics.
    public static let grapes = Item("grapes")
        .name("grapes")
        .description("A bunch of purple grapes.")
        .isPlural
        .isTakable
        .in(.startRoom)

    /// An iron sword weapon that starts in the player's inventory.
    ///
    /// This weapon provides a baseline for combat testing and demonstrates
    /// items that begin in the player's possession.
    public static let ironSword = Item("sword")
        .name("iron sword")
        .description("A sharp iron sword.")
        .isTakable
        .isWeapon
        .in(.player)

    /// A wooden match that can ignite itself or other items.
    ///
    /// This item tests the self-ignitable flag and fire mechanics,
    /// starting in the player's inventory for immediate use.
    public static let matchStick = Item("match")
        .name("wooden match")
        .description("A wooden match.")
        .isSelfIgnitable
        .isTakable
        .in(.player)

    /// A simple pebble that serves as a basic test item.
    ///
    /// This unremarkable item provides a neutral test object for basic
    /// item manipulation without special properties or complications.
    public static let pebble = Item(.startItem)
        .name("pebble")
        .description("A wholly unremarkable pebble.")
        .in(.startRoom)
        .isTakable

    /// A burning torch that provides light.
    ///
    /// This item tests light source mechanics, flammability, and burning states.
    /// It starts in the player's inventory as an active light source.
    public static let torch = Item("torch")
        .name("flaming torch")
        .description("A wooden torch with a bright flame.")
        .isFlammable
        .isBurning
        .isLightSource
        .in(.player)
}

// MARK: - NPC's

extension Lab {
    /// A stern castle guard with moderate combat abilities.
    ///
    /// This NPC demonstrates character sheet mechanics, taunts system,
    /// and represents a lawful neutral authority figure with combat capabilities.
    /// The guard is drunk and drowsy, affecting their performance.
    public static let castleGuard = Item("guard")
        .name("castle guard")
        .description("A stern castle guard.")
        .synonyms("brute", "guard", "bully")
        .adjectives("surly", "drunken", "bitter")
        .characterSheet(
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
        .in(.startRoom)

    /// A powerful dragon representing the ultimate combat challenge.
    ///
    /// This NPC serves as a high-level boss enemy with maximum stats across
    /// most categories. It demonstrates neutral evil alignment and represents
    /// the most dangerous combat encounter in the test suite.
    public static let dragon = Item("dragon")
        .name("terrible dragon")
        .description("A terrible dragon.")
        .characterSheet(
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
        .in(.startRoom)

    /// A helpful woodland fairy with high magical abilities.
    ///
    /// This NPC represents a chaotic good character with exceptional dexterity,
    /// luck, and stealth. The fairy demonstrates low physical strength but
    /// high mental attributes, providing a contrast to combat-focused NPCs.
    public static let fairy = Item("fairy")
        .name("woodland fairy")
        .description("A woodland fairy.")
        .characterSheet(
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
        .in(.startRoom)

    /// A noble knight representing lawful good heroic archetype.
    ///
    /// This NPC demonstrates a well-balanced heroic character with high physical
    /// and social stats. The knight has combat taunts and represents traditional
    /// chivalric values in the game world.
    public static let knight = Item("knight")
        .name("knight")
        .description("A noble knight.")
        .characterSheet(
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
        .in(.startRoom)

    /// A traveling merchant with default character stats.
    ///
    /// This NPC provides a baseline character for testing trade mechanics
    /// and demonstrates the use of default character sheet values.
    public static let merchant = Item("merchant")
        .name("traveling merchant")
        .description("A traveling merchant.")
        .characterSheet(.default)
        .in(.startRoom)

    /// A beautiful princess with high social and mental attributes.
    ///
    /// This NPC represents a lawful neutral royal character with exceptional
    /// charisma and luck. She demonstrates high intelligence and wisdom
    /// while maintaining moderate physical capabilities.
    public static let princess = Item("princess")
        .name("princess")
        .description("A beautiful princess.")
        .characterSheet(
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
        .in(.startRoom)

    /// A fierce troll that blocks the player's path.
    ///
    /// This NPC serves as a classic IF obstacle with multiple synonyms and adjectives.
    /// The troll carries an axe and has taunting behavior. It's transparent and
    /// requires special handling to take, making it ideal for testing complex interactions.
    public static let troll = Item(.troll)
        .name("fierce troll")
        .adjectives("angry", "fearsome", "terrible", "grotesque")
        .synonyms("beast", "monster", "creature")
        .description("A fierce troll blocking your way.")
        .characterSheet(
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
        .isTransparent
        .requiresTryTake
        .in(.startRoom)

    /// Spandalf the wizard, a wise magical character.
    ///
    /// This NPC demonstrates the wise character sheet preset and provides
    /// multiple synonyms for testing vocabulary recognition. The wizard
    /// represents a classic IF mentor figure.
    public static let wizard = Item("wizard")
        .name("Spandalf")
        .synonyms("wizard", "mage")
        .adjectives("clever", "wise")
        .description("A wise old wizard.")
        .characterSheet(.wise)
        .in(.startRoom)
}

// MARK: - Item helpers

extension Item {
    /// Returns a copy of this item with their fighting flag set to true.
    ///
    /// This computed property modifies the character sheet to indicate the NPC
    /// is currently engaged in combat, which affects their behavior and responses.
    ///
    /// - Returns: A new `Item` instance with fighting status enabled, or the original
    ///   item if it doesn't have a character sheet.
    public var fighting: Item {
        var fighter = self
        if case .characterSheet(var fightSheet) = fighter.properties[.characterSheet] {
            fightSheet.isFighting = true
            fighter.properties[.characterSheet] = .characterSheet(fightSheet)
            return fighter
        }
        return self
    }

    /// Returns a copy of this item with its location set to the player's inventory.
    ///
    /// This computed property modifies the parent entity to place the item in the
    /// player's possession, which is useful for testing scenarios where items
    /// need to be moved to the player's inventory.
    ///
    /// - Returns: A new `Item` instance located in the player's inventory.
    public var inPlayerInventory: Item {
        var item = self
        item.properties[.parentEntity] = .parentEntity(.player)
        return item
    }
}

// MARK: - Common Test IDs

extension ItemID {
    /// The item ID for the axe.
    public static let axe = ItemID("axe")

    /// The item ID for the castleGuard.
    public static let castleGuard = ItemID("castleGuard")

    /// The item ID for the dragon.
    public static let dragon = ItemID("dragon")

    /// The item ID for the fairy.
    public static let fairy = ItemID("fairy")

    /// The item ID for the grapes.
    public static let grapes = ItemID("grapes")

    /// The item ID for the ironSword.
    public static let ironSword = ItemID("ironSword")

    /// The item ID for the knight.
    public static let knight = ItemID("knight")

    /// The item ID for the matchStick.
    public static let matchStick = ItemID("matchStick")

    /// The item ID for the merchant.
    public static let merchant = ItemID("merchant")

    /// The item ID for the pebble.
    public static let pebble = ItemID("pebble")

    /// The item ID for the princess.
    public static let princess = ItemID("princess")

    /// The item ID for the starting pebble item.
    public static let startItem: ItemID = "startItem"

    /// The item ID for the torch.
    public static let torch = ItemID("torch")

    /// The item ID for the troll.
    public static let troll = ItemID("troll")

    /// The item ID for the wizard.
    public static let wizard = ItemID("wizard")
}

extension LocationID {
    /// The location ID for the laboratory test room.
    public static let startRoom: LocationID = "startRoom"
}
