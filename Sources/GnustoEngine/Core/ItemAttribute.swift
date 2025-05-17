import Foundation

/// Represents an attribute of an `Item`.
public struct ItemAttribute: Attribute {
    public let id: AttributeID
    public let rawValue: StateValue

    public init(
        id: AttributeID,
        rawValue: StateValue
    ) {
        self.id = id
        self.rawValue = rawValue
    }
}

// MARK: - Value attributes

extension ItemAttribute {
    /// Adjectives associated with an item (e.g., "brass", "small"), used for disambiguation.
    ///
    /// - Parameter adjectives: Adjectives associated with an item.
    /// - Returns: An .adjectives attribute.
    public static func adjectives(_ adjectives: String...) -> ItemAttribute {
        ItemAttribute(
            id: .adjectives,
            rawValue: .stringSet(Set(adjectives))
        )
    }

    /// The carrying capacity of a container item.
    ///
    /// - Parameter capacity: The carrying capacity of a container item.
    /// - Returns: A .capacity attribute.
    public static func capacity(_ capacity: Int) -> ItemAttribute {
        ItemAttribute(
            id: .capacity,
            rawValue: .int(capacity)
        )
    }

    /// The item's primary, detailed description (ZIL `LDESC`).
    ///
    /// - Parameter description: The item's primary detailed description.
    /// - Returns: A .description attribute.
    public static func description(_ description: String) -> ItemAttribute {
        ItemAttribute(
            id: .description,
            rawValue: .string(description)
        )
    }

    /// The description shown the first time an item is seen (ZIL `FDESC`).
    ///
    /// - Parameter description: The description shown the first time an item is seen.
    /// - Returns: A .firstDescription attribute.
    public static func firstDescription(_ description: String) -> ItemAttribute {
        ItemAttribute(
            id: .firstDescription,
            rawValue: .string(description)
        )
    }
    
    /// The item's parent entity (ZIL `IN`).
    ///
    /// - Parameter parent: The item's parent entity.
    /// - Returns: A .parentEntity attribute.
    public static func `in`(_ parent: ParentEntity) -> ItemAttribute {
        ItemAttribute(
            id: .parentEntity,
            rawValue: .parentEntity(parent)
        )
    }

    /// The key needed to lock/unlock an item (if `.isLockable`).
    ///
    /// - Parameter lockKey: <#lockKey description#>
    /// - Returns: <#description#>
    public static func lockKey(_ lockKey: ItemID) -> ItemAttribute {
        ItemAttribute(
            id: .lockKey,
            rawValue: .itemID(lockKey)
        )
    }

    /// The primary name used to refer to the item (ZIL: `DESC`).
    ///
    /// - Parameter name: The primary name used to refer to the item.
    /// - Returns: A .name attribute.
    public static func name(_ name: String) -> ItemAttribute {
        ItemAttribute(
            id: .name,
            rawValue: .string(name)
        )
    }

    /// Text that can be read from an item (ZIL `RTEXT/TEXT`).
    ///
    /// - Parameter text: Text that can be read from an item.
    /// - Returns: A .readText attribute.
    public static func readText(_ text: String) -> ItemAttribute {
        ItemAttribute(
            id: .readText,
            rawValue: .string(text)
        )
    }

    /// Text that can be read from an item while holding it (ZILF `TEXT-HELD`).
    ///
    /// - Parameter text: Text that can be read from an item while holding it.
    /// - Returns: A .readWhileHeldText attribute.
    public static func readWhileHeldText(_ text: String) -> ItemAttribute {
        ItemAttribute(
            id: .readWhileHeldText,
            rawValue: .string(text)
        )
    }

    /// The shorter item description used in lists or brief mentions (ZIL `SDESC`).
    ///
    /// - Parameter description: The shorter item description.
    /// - Returns: A .shortDescription attribute.
    public static func shortDescription(_ description: String) -> ItemAttribute {
        ItemAttribute(
            id: .shortDescription,
            rawValue: .string(description)
        )
    }

    /// An item's size, influencing carrying capacity and container limits.
    ///
    /// - Parameter size: An item's size.
    /// - Returns: A .size attribute.
    public static func size(_ size: Int) -> ItemAttribute {
        ItemAttribute(
            id: .size,
            rawValue: .int(size)
        )
    }

    /// Synonyms for an item (e.g., "lamp", "light").
    ///
    /// - Parameter synonyms: Synonyms associated with an item.
    /// - Returns: A .synonyms attribute.
    public static func synonyms(_ synonyms: String...) -> ItemAttribute {
        ItemAttribute(
            id: .synonyms,
            rawValue: .stringSet(Set(synonyms))
        )
    }

}

// MARK: - Flag attributes

extension ItemAttribute {
    /// ACTORBIT: Is a non-player character.
    public static var isCharacter: ItemAttribute {
        ItemAttribute(id: .isCharacter, rawValue: true)
    }

    /// CLIMBBIT: Can be climbed.
    public static var isClimbable: ItemAttribute {
        ItemAttribute(id: .isClimbable, rawValue: true)
    }

    /// FIGHTBIT: Can participate in combat.
    public static var isCombatReady: ItemAttribute {
        ItemAttribute(id: .isCombatReady, rawValue: true)
    }

    /// CONTBIT: Can hold other items.
    public static var isContainer: ItemAttribute {
        ItemAttribute(id: .isContainer, rawValue: true)
    }

    /// DEVICEBIT: Can be turned on/off (ZILF specific).
    public static var isDevice: ItemAttribute {
        ItemAttribute(id: .isDevice, rawValue: true)
    }

    /// DOORBIT: Functions as a door.
    public static var isDoor: ItemAttribute {
        ItemAttribute(id: .isDoor, rawValue: true)
    }

    /// EDIBLEBIT / FOODBIT: Can be eaten.
    public static var isEdible: ItemAttribute {
        ItemAttribute(id: .isEdible, rawValue: true)
    }

    /// Can be equipped (e.g., weapon, shield).
    public static var isEquippable: ItemAttribute {
        ItemAttribute(id: .isEquippable, rawValue: true)
    }

    /// FEMALEBIT: Grammatically female.
    public static var isFemale: ItemAttribute {
        ItemAttribute(id: .isFemale, rawValue: true)
    }

    /// Cannot be taken or moved (scenery).
    public static var isScenery: ItemAttribute {
        ItemAttribute(id: .isScenery, rawValue: true)
    }

    /// BURNBIT / FLAMEBIT: Is flammable or burning.
    public static var isFlammable: ItemAttribute {
        ItemAttribute(id: .isFlammable, rawValue: true)
    }

    /// INVISIBLE: Not normally seen (object is invisible).
    public static var isInvisible: ItemAttribute {
        ItemAttribute(id: .isInvisible, rawValue: true)
    }

    /// Can be used to lock/unlock.
    public static var isKey: ItemAttribute {
        ItemAttribute(id: .isKey, rawValue: true)
    }

    /// LIGHTBIT: Provides light when active/on.
    public static var isLightSource: ItemAttribute {
        ItemAttribute(id: .isLightSource, rawValue: true)
    }

    /// Indicates whether an entity is currently considered "lit".
    public static var isLit: ItemAttribute {
        ItemAttribute(id: .isLit, rawValue: true)
    }

    /// LOCKBIT: Can be locked/unlocked (needs `lockKey`).
    public static var isLockable: ItemAttribute {
        ItemAttribute(id: .isLockable, rawValue: true)
    }

    /// LOCKED: Is locked.
    public static var isLocked: ItemAttribute {
        ItemAttribute(id: .isLocked, rawValue: true)
    }

    /// NARTICLEBIT: Suppress default article ("a", "the").
    public static var suppressArticle: ItemAttribute {
        ItemAttribute(id: .suppressArticle, rawValue: true)
    }

    /// NDESCBIT: Suppress automatic description in room contents.
    public static var suppressDescription: ItemAttribute {
        ItemAttribute(id: .suppressDescription, rawValue: true)
    }

    /// ONBIT: Is currently switched on.
    public static var isOn: ItemAttribute {
        ItemAttribute(id: .isOn, rawValue: true)
    }

    /// OPENBIT: Whether a container item is currently open.
    public static var isOpen: ItemAttribute {
        ItemAttribute(id: .isOpen, rawValue: true)
    }

    /// OPENABLEBIT: Can be opened/closed by player.
    public static var isOpenable: ItemAttribute {
        ItemAttribute(id: .isOpenable, rawValue: true)
    }

    /// PERSONBIT: An NPC or the player.
    public static var isPerson: ItemAttribute {
        ItemAttribute(id: .isPerson, rawValue: true)
    }

    /// PLURALBIT: Grammatically plural.
    public static var isPlural: ItemAttribute {
        ItemAttribute(id: .isPlural, rawValue: true)
    }

    /// READBIT: Can be read (implies text content).
    public static var isReadable: ItemAttribute {
        ItemAttribute(id: .isReadable, rawValue: true)
    }

    /// SEARCHBIT: Can be searched.
    public static var isSearchable: ItemAttribute {
        ItemAttribute(id: .isSearchable, rawValue: true)
    }

    /// SURFACEBIT: Items can be placed *on* it.
    public static var isSurface: ItemAttribute {
        ItemAttribute(id: .isSurface, rawValue: true)
    }

    /// TAKEBIT: Can be picked up.
    public static var isTakable: ItemAttribute {
        ItemAttribute(id: .isTakable, rawValue: true)
    }

    /// TOOLBIT: Is a tool (specific game logic).
    public static var isTool: ItemAttribute {
        ItemAttribute(id: .isTool, rawValue: true)
    }

    /// TOUCHBIT: Player has interacted with it (used for brief mode descriptions).
    public static var isTouched: ItemAttribute {
        ItemAttribute(id: .isTouched, rawValue: true)
    }

    /// TRANSBIT: Contents are visible even if closed.
    public static var isTransparent: ItemAttribute {
        ItemAttribute(id: .isTransparent, rawValue: true)
    }

    /// TRYTAKEBIT: Needs special check before taking.
    public static var requiresTryTake: ItemAttribute {
        ItemAttribute(id: .requiresTryTake, rawValue: true)
    }

    /// VEHBIT: Is a vehicle.
    public static var isVehicle: ItemAttribute {
        ItemAttribute(id: .isVehicle, rawValue: true)
    }

    /// VOWELBIT: Name starts with vowel (for "an").
    public static var startsWithVowel: ItemAttribute {
        ItemAttribute(id: .startsWithVowel, rawValue: true)
    }

    /// WEAPONBIT: Is a weapon.
    public static var isWeapon: ItemAttribute {
        ItemAttribute(id: .isWeapon, rawValue: true)
    }

    /// WEARBIT: Can be worn.
    public static var isWearable: ItemAttribute {
        ItemAttribute(id: .isWearable, rawValue: true)
    }

    /// WORNBIT: Is currently being worn.
    public static var isWorn: ItemAttribute {
        ItemAttribute(id: .isWorn, rawValue: true)
    }

}
