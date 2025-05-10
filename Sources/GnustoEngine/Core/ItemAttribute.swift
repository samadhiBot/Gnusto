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
    static func adjectives(_ adjectives: String...) -> ItemAttribute {
        ItemAttribute(
            id: .adjectives,
            rawValue: .stringSet(Set(adjectives))
        )
    }

    /// The carrying capacity of a container item.
    ///
    /// - Parameter capacity: The carrying capacity of a container item.
    /// - Returns: A .capacity attribute.
    static func capacity(_ capacity: Int) -> ItemAttribute {
        ItemAttribute(
            id: .capacity,
            rawValue: .int(capacity)
        )
    }

    /// The item's primary, detailed description (ZIL `LDESC`).
    ///
    /// - Parameter description: The item's primary detailed description.
    /// - Returns: A .description attribute.
    static func description(_ description: String) -> ItemAttribute {
        ItemAttribute(
            id: .description,
            rawValue: .string(description)
        )
    }

    /// The description shown the first time an item is seen (ZIL `FDESC`).
    ///
    /// - Parameter description: The description shown the first time an item is seen.
    /// - Returns: A .firstDescription attribute.
    static func firstDescription(_ description: String) -> ItemAttribute {
        ItemAttribute(
            id: .firstDescription,
            rawValue: .string(description)
        )
    }
    
    /// The item's parent entity (ZIL `IN`).
    ///
    /// - Parameter parent: The item's parent entity.
    /// - Returns: A .parentEntity attribute.
    static func `in`(_ parent: ParentEntity) -> ItemAttribute {
        ItemAttribute(
            id: .parentEntity,
            rawValue: .parentEntity(parent)
        )
    }

    /// The key needed to lock/unlock an item (if `.isLockable`).
    ///
    /// - Parameter lockKey: <#lockKey description#>
    /// - Returns: <#description#>
    static func lockKey(_ lockKey: ItemID) -> ItemAttribute {
        ItemAttribute(
            id: .lockKey,
            rawValue: .itemID(lockKey)
        )
    }

    /// Text that can be read from an item (ZIL `RTEXT/TEXT`).
    ///
    /// - Parameter text: Text that can be read from an item.
    /// - Returns: A .readText attribute.
    static func readText(_ text: String) -> ItemAttribute {
        ItemAttribute(
            id: .readText,
            rawValue: .string(text)
        )
    }

    /// Text that can be read from an item while holding it (ZILF `TEXT-HELD`).
    ///
    /// - Parameter text: Text that can be read from an item while holding it.
    /// - Returns: A .readWhileHeldText attribute.
    static func readWhileHeldText(_ text: String) -> ItemAttribute {
        ItemAttribute(
            id: .readWhileHeldText,
            rawValue: .string(text)
        )
    }

    /// The shorter item description used in lists or brief mentions (ZIL `SDESC`).
    ///
    /// - Parameter description: The shorter item description.
    /// - Returns: A .shortDescription attribute.
    static func shortDescription(_ description: String) -> ItemAttribute {
        ItemAttribute(
            id: .shortDescription,
            rawValue: .string(description)
        )
    }

    /// An item's size, influencing carrying capacity and container limits.
    ///
    /// - Parameter size: An item's size.
    /// - Returns: A .size attribute.
    static func size(_ size: Int) -> ItemAttribute {
        ItemAttribute(
            id: .size,
            rawValue: .int(size)
        )
    }

    /// Synonyms for an item (e.g., "lamp", "light").
    ///
    /// - Parameter synonyms: Synonyms associated with an item.
    /// - Returns: A .synonyms attribute.
    static func synonyms(_ synonyms: String...) -> ItemAttribute {
        ItemAttribute(
            id: .synonyms,
            rawValue: .stringSet(Set(synonyms))
        )
    }

}

// MARK: - Flag attributes

extension ItemAttribute {
    /// ACTORBIT: Is a non-player character.
    static var isCharacter: ItemAttribute {
        ItemAttribute(id: .isCharacter, rawValue: true)
    }

    /// CLIMBBIT: Can be climbed.
    static var isClimbable: ItemAttribute {
        ItemAttribute(id: .isClimbable, rawValue: true)
    }

    /// FIGHTBIT: Can participate in combat.
    static var isCombatReady: ItemAttribute {
        ItemAttribute(id: .isCombatReady, rawValue: true)
    }

    /// CONTBIT: Can hold other items.
    static var isContainer: ItemAttribute {
        ItemAttribute(id: .isContainer, rawValue: true)
    }

    /// DEVICEBIT: Can be turned on/off (ZILF specific).
    static var isDevice: ItemAttribute {
        ItemAttribute(id: .isDevice, rawValue: true)
    }

    /// DOORBIT: Functions as a door.
    static var isDoor: ItemAttribute {
        ItemAttribute(id: .isDoor, rawValue: true)
    }

    /// EDIBLEBIT / FOODBIT: Can be eaten.
    static var isEdible: ItemAttribute {
        ItemAttribute(id: .isEdible, rawValue: true)
    }

    /// Can be equipped (e.g., weapon, shield).
    static var isEquippable: ItemAttribute {
        ItemAttribute(id: .isEquippable, rawValue: true)
    }

    /// FEMALEBIT: Grammatically female.
    static var isFemale: ItemAttribute {
        ItemAttribute(id: .isFemale, rawValue: true)
    }

    /// Cannot be taken or moved (scenery).
    static var isFixed: ItemAttribute {
        ItemAttribute(id: .isFixed, rawValue: true)
    }

    /// BURNBIT / FLAMEBIT: Is flammable or burning.
    static var isFlammable: ItemAttribute {
        ItemAttribute(id: .isFlammable, rawValue: true)
    }

    /// INVISIBLE: Not normally seen (object is invisible).
    static var isInvisible: ItemAttribute {
        ItemAttribute(id: .isInvisible, rawValue: true)
    }

    /// Can be used to lock/unlock.
    static var isKey: ItemAttribute {
        ItemAttribute(id: .isKey, rawValue: true)
    }

    /// LIGHTBIT: Provides light when active/on.
    static var isLightSource: ItemAttribute {
        ItemAttribute(id: .isLightSource, rawValue: true)
    }

    /// Indicates whether an entity is currently considered "lit".
    static var isLit: ItemAttribute {
        ItemAttribute(id: .isLit, rawValue: true)
    }

    /// LOCKBIT: Can be locked/unlocked (needs `lockKey`).
    static var isLockable: ItemAttribute {
        ItemAttribute(id: .isLockable, rawValue: true)
    }

    /// LOCKED: Is locked.
    static var isLocked: ItemAttribute {
        ItemAttribute(id: .isLocked, rawValue: true)
    }

    /// NARTICLEBIT: Suppress default article ("a", "the").
    static var suppressArticle: ItemAttribute {
        ItemAttribute(id: .suppressArticle, rawValue: true)
    }

    /// NDESCBIT: Suppress automatic description in room contents.
    static var suppressDescription: ItemAttribute {
        ItemAttribute(id: .suppressDescription, rawValue: true)
    }

    /// ONBIT: Is currently switched on.
    static var isOn: ItemAttribute {
        ItemAttribute(id: .isOn, rawValue: true)
    }

    /// OPENBIT: Whether a container item is currently open.
    static var isOpen: ItemAttribute {
        ItemAttribute(id: .isOpen, rawValue: true)
    }

    /// OPENABLEBIT: Can be opened/closed by player.
    static var isOpenable: ItemAttribute {
        ItemAttribute(id: .isOpenable, rawValue: true)
    }

    /// PERSONBIT: An NPC or the player.
    static var isPerson: ItemAttribute {
        ItemAttribute(id: .isPerson, rawValue: true)
    }

    /// PLURALBIT: Grammatically plural.
    static var isPlural: ItemAttribute {
        ItemAttribute(id: .isPlural, rawValue: true)
    }

    /// READBIT: Can be read (implies text content).
    static var isReadable: ItemAttribute {
        ItemAttribute(id: .isReadable, rawValue: true)
    }

    /// SEARCHBIT: Can be searched.
    static var isSearchable: ItemAttribute {
        ItemAttribute(id: .isSearchable, rawValue: true)
    }

    /// SURFACEBIT: Items can be placed *on* it.
    static var isSurface: ItemAttribute {
        ItemAttribute(id: .isSurface, rawValue: true)
    }

    /// TAKEBIT: Can be picked up.
    static var isTakable: ItemAttribute {
        ItemAttribute(id: .isTakable, rawValue: true)
    }

    /// TOOLBIT: Is a tool (specific game logic).
    static var isTool: ItemAttribute {
        ItemAttribute(id: .isTool, rawValue: true)
    }

    /// TOUCHBIT: Player has interacted with it (used for brief mode descriptions).
    static var isTouched: ItemAttribute {
        ItemAttribute(id: .isTouched, rawValue: true)
    }

    /// TRANSBIT: Contents are visible even if closed.
    static var isTransparent: ItemAttribute {
        ItemAttribute(id: .isTransparent, rawValue: true)
    }

    /// TRYTAKEBIT: Needs special check before taking.
    static var requiresTryTake: ItemAttribute {
        ItemAttribute(id: .requiresTryTake, rawValue: true)
    }

    /// VEHBIT: Is a vehicle.
    static var isVehicle: ItemAttribute {
        ItemAttribute(id: .isVehicle, rawValue: true)
    }

    /// VOWELBIT: Name starts with vowel (for "an").
    static var startsWithVowel: ItemAttribute {
        ItemAttribute(id: .startsWithVowel, rawValue: true)
    }

    /// WEAPONBIT: Is a weapon.
    static var isWeapon: ItemAttribute {
        ItemAttribute(id: .isWeapon, rawValue: true)
    }

    /// WEARBIT: Can be worn.
    static var isWearable: ItemAttribute {
        ItemAttribute(id: .isWearable, rawValue: true)
    }

    /// WORNBIT: Is currently being worn.
    static var isWorn: ItemAttribute {
        ItemAttribute(id: .isWorn, rawValue: true)
    }

}
