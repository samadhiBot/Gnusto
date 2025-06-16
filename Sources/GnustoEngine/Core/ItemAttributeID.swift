import Foundation

/// A unique identifier for a standard or dynamic property within the game.
public struct ItemAttributeID: GnustoID {
    public let rawValue: String

    /// Initializes a `AttributeID` with a raw string value.
    /// - Parameter rawValue: The string value for the ID.
    public init(rawValue: String) {
        assert(!rawValue.isEmpty, "Attribute ID cannot be empty")
        self.rawValue = rawValue
    }
}

// MARK: - General Property IDs

public extension ItemAttributeID {
    /// Adjectives associated with an item (e.g., "brass", "small"), used for disambiguation.
    static let adjectives = ItemAttributeID("adjectives")

    /// The carrying capacity of a container item.
    static let capacity = ItemAttributeID("capacity")

    /// The key needed to lock/unlock an item (if `.isLockable`).
    static let lockKey = ItemAttributeID("lockKey")

    /// The primary noun used to refer to the item (ZIL: `DESC`).
    static let name = ItemAttributeID("name")

    /// The identifier of the item's parent entity.
    static let parentEntity = ItemAttributeID("parentEntity")

    /// An item's size, influencing carrying capacity and container limits.
    static let size = ItemAttributeID("size")

    /// An item's strength, influencing fighting ability.
    static let strength = ItemAttributeID("strength")

    /// Synonyms for an item (e.g., "lamp", "light").
    static let synonyms = ItemAttributeID("synonyms")

    /// The value of the item.
    static let value = ItemAttributeID("value")
}

// MARK: - Descriptions

public extension ItemAttributeID {
    /// The description shown the first time an item is seen (ZIL `FDESC`).
    static let firstDescription = ItemAttributeID("firstDescription")

    /// The primary, detailed description (ZIL `LDESC`).
    static let description = ItemAttributeID("description")

    /// The shorter description used in lists or brief mentions (ZIL `SDESC`).
    static let shortDescription = ItemAttributeID("shortDescription")

    /// Text that can be read from an item (ZIL `RTEXT/TEXT`).
    static let readText = ItemAttributeID("readText")

    /// Text that can be read from an item while holding it (ZILF `TEXT-HELD`).
    static let readWhileHeldText = ItemAttributeID("readWhileHeldText")
}

// MARK: - Item Flags

public extension ItemAttributeID {
    /// ACTORBIT: Is a non-player character.
    static let isCharacter = ItemAttributeID("isCharacter")

    /// CLIMBBIT: Can be climbed.
    static let isClimbable: ItemAttributeID = "isClimbable"

    /// FIGHTBIT: Can participate in combat.
    static let isCombatReady = ItemAttributeID("isCombatReady")

    /// CONTBIT: Can hold other items.
    static let isContainer = ItemAttributeID("isContainer")

    /// DEVICEBIT: Can be turned on/off (ZILF specific).
    static let isDevice = ItemAttributeID("isDevice")

    /// DOORBIT: Functions as a door.
    static let isDoor = ItemAttributeID("isDoor")

    /// Is a dial that can be turned with clicking sounds.
    static let isDial = ItemAttributeID("isDial")

    /// DRINKBIT: Can be consumed as a liquid.
    static let isDrinkable = ItemAttributeID("isDrinkable")

    /// EDIBLEBIT / FOODBIT: Can be eaten.
    static let isEdible = ItemAttributeID("isEdible")

    /// Can be entered (e.g., buildings, vehicles).
    static let isEnterable = ItemAttributeID("isEnterable")

    /// Can be equipped (e.g., weapon, shield).
    static let isEquippable = ItemAttributeID("isEquippable")

    /// FEMALEBIT: Grammatically female.
    static let isFemale = ItemAttributeID("isFemale")

    /// FIGHTBIT: Is fighting.
    static let isFighting = ItemAttributeID("isFighting")

    /// Is a flag that can be waved.
    static let isFlag = ItemAttributeID("isFlag")

    /// BURNBIT / FLAMEBIT: Is flammable or burning.
    static let isFlammable = ItemAttributeID("isFlammable")

    /// Is a handle that can be turned.
    static let isHandle = ItemAttributeID("isHandle")

    /// Can be inflated (like balloons, rafts, etc.).
    static let isInflatable = ItemAttributeID("isInflatable")

    /// Is currently inflated.
    static let isInflated = ItemAttributeID("isInflated")

    /// INVISIBLE: Not normally seen (object is invisible).
    static let isInvisible = ItemAttributeID("isInvisible")

    /// Can be used to lock/unlock.
    static let isKey = ItemAttributeID("isKey")

    /// Is a knob that can be turned with clicking sounds.
    static let isKnob = ItemAttributeID("isKnob")

    /// LIGHTBIT: Provides light when active/on.
    static let isLightSource = ItemAttributeID("isLightSource")

    /// Contains liquid that can be heard when shaken.
    static let isLiquidContainer = ItemAttributeID("isLiquidContainer")

    /// Indicates whether an entity is currently considered "lit".
    static let isLit = ItemAttributeID("isLit")

    /// LOCKBIT: Can be locked/unlocked (needs `lockKey`).
    static let isLockable = ItemAttributeID("isLockable")

    /// LOCKED: Is locked.
    static let isLocked = ItemAttributeID("isLocked")

    /// ONBIT: Is currently switched on.
    static let isOn = ItemAttributeID("isOn") // Note: Potential overlap with computed isLit? Review needed.

    /// OPENBIT: Whether a container item is currently open.
    static let isOpen = ItemAttributeID("isOpen")

    /// OPENABLEBIT: Can be opened/closed by player.
    static let isOpenable = ItemAttributeID("isOpenable")

    /// PERSONBIT: An NPC or the player.
    static let isPerson = ItemAttributeID("isPerson")

    /// PLURALBIT: Grammatically plural.
    static let isPlural = ItemAttributeID("isPlural")

    /// Indicates a plant that can be watered.
    static let isPlant = ItemAttributeID("isPlant")

    /// Can be pressed (like buttons, switches).
    static let isPressable = ItemAttributeID("isPressable")

    /// Can be pulled.
    static let isPullable = ItemAttributeID("isPullable")

    /// READBIT: Can be read (implies text content).
    static let isReadable = ItemAttributeID("isReadable")

    /// Is a rope-like object that can have knots tied in it.
    static let isRope = ItemAttributeID("isRope")

    /// SEARCHBIT: Can be searched.
    static let isSearchable = ItemAttributeID("isSearchable")

    /// Is a soft, yielding object (like pillows, cushions).
    static let isSoft = ItemAttributeID("isSoft")

    /// Is a sponge that can absorb and release water.
    static let isSponge = ItemAttributeID("isSponge")

    /// Is a magical staff that can be waved.
    static let isStaff = ItemAttributeID("isStaff")

    /// SURFACEBIT: Items can be placed *on* it.
    static let isSurface = ItemAttributeID("isSurface")

    /// TAKEBIT: Can be picked up.
    static let isTakable = ItemAttributeID("isTakable")

    /// TOOLBIT: Is a tool (specific game logic).
    static let isTool = ItemAttributeID("isTool")

    /// TOUCHBIT: Player has interacted with it (used for brief mode descriptions).
    static let isTouched = ItemAttributeID("isTouched")

    /// TRANSBIT: Contents are visible even if closed.
    static let isTransparent = ItemAttributeID("isTransparent")

    /// TRYTAKEBIT: Needs special check before taking.
    static let requiresTryTake = ItemAttributeID("requiresTryTake")

    /// VEHBIT: Is a vehicle.
    static let isVehicle = ItemAttributeID("isVehicle")

    /// VOWELBIT: Name starts with vowel (for "an").
    static let startsWithVowel = ItemAttributeID("startsWithVowel")

    /// Is a magical wand that can be waved.
    static let isWand = ItemAttributeID("isWand")

    /// WEAPONBIT: Is a weapon.
    static let isWeapon = ItemAttributeID("isWeapon")

    /// WEARBIT: Can be worn.
    static let isWearable = ItemAttributeID("isWearable")

    /// Is a wheel that can be turned with effort.
    static let isWheel = ItemAttributeID("isWheel")

    /// WORNBIT: Is currently being worn.
    static let isWorn = ItemAttributeID("isWorn")

    /// NARTICLEBIT: Omit default article ("a", "the").
    static let omitArticle = ItemAttributeID("omitArticle")

    /// NDESCBIT: Omit automatic description in room contents.
    static let omitDescription = ItemAttributeID("omitDescription")
}
