import Foundation

/// A unique identifier for a standard or dynamic property within the game.
public struct ItemAttributeID: GnustoID {
    public let rawValue: String

    /// Initializes a `AttributeID` with a raw string value.
    /// - Parameter rawValue: The string value for the ID.
    public init(rawValue: String) {
        assert(rawValue.isNotEmpty, "Attribute ID cannot be empty")
        self.rawValue = rawValue
    }
}

// MARK: - General Property IDs

extension ItemAttributeID {
    /// Adjectives associated with an item (e.g., "brass", "small"), used for disambiguation.
    public static let adjectives = ItemAttributeID("adjectives")

    /// The carrying capacity of a container item.
    public static let capacity = ItemAttributeID("capacity")

    /// The key needed to lock/unlock an item (if `.isLockable`).
    public static let lockKey = ItemAttributeID("lockKey")

    /// The primary noun used to refer to the item (ZIL: `DESC`).
    public static let name = ItemAttributeID("name")

    /// The identifier of the item's parent entity.
    public static let parentEntity = ItemAttributeID("parentEntity")

    /// An item's size, influencing carrying capacity and container limits.
    public static let size = ItemAttributeID("size")

    /// An item's strength, influencing fighting ability.
    public static let strength = ItemAttributeID("strength")

    /// Synonyms for an item (e.g., "lamp", "light").
    public static let synonyms = ItemAttributeID("synonyms")

    /// The value of the item.
    public static let value = ItemAttributeID("value")
}

// MARK: - Descriptions

extension ItemAttributeID {
    /// The description shown the first time an item is seen (ZIL `FDESC`).
    public static let firstDescription = ItemAttributeID("firstDescription")

    /// The primary, detailed description (ZIL `LDESC`).
    public static let description = ItemAttributeID("description")

    /// The shorter description used in lists or brief mentions (ZIL `SDESC`).
    public static let shortDescription = ItemAttributeID("shortDescription")

    /// Text that can be read from an item (ZIL `RTEXT/TEXT`).
    public static let readText = ItemAttributeID("readText")

    /// Text that can be read from an item while holding it (ZILF `TEXT-HELD`).
    public static let readWhileHeldText = ItemAttributeID("readWhileHeldText")
}

// MARK: - Item Flags

extension ItemAttributeID {
    /// ACTORBIT: Is a non-player character.
    public static let isCharacter = ItemAttributeID("isCharacter")

    /// CLIMBBIT: Can be climbed.
    public static let isClimbable: ItemAttributeID = "isClimbable"

    /// FIGHTBIT: Can participate in combat.
    public static let isCombatReady = ItemAttributeID("isCombatReady")

    /// CONTBIT: Can hold other items.
    public static let isContainer = ItemAttributeID("isContainer")

    /// DEVICEBIT: Can be turned on/off (ZILF specific).
    public static let isDevice = ItemAttributeID("isDevice")

    /// DOORBIT: Functions as a door.
    public static let isDoor = ItemAttributeID("isDoor")

    /// Is a dial that can be turned with clicking sounds.
    public static let isDial = ItemAttributeID("isDial")

    /// DRINKBIT: Can be consumed as a liquid.
    public static let isDrinkable = ItemAttributeID("isDrinkable")

    /// EDIBLEBIT / FOODBIT: Can be eaten.
    public static let isEdible = ItemAttributeID("isEdible")

    /// Can be entered (e.g., buildings, vehicles).
    public static let isEnterable = ItemAttributeID("isEnterable")

    /// Can be equipped (e.g., weapon, shield).
    public static let isEquippable = ItemAttributeID("isEquippable")

    /// FEMALEBIT: Grammatically female.
    public static let isFemale = ItemAttributeID("isFemale")

    /// FIGHTBIT: Is fighting.
    public static let isFighting = ItemAttributeID("isFighting")

    /// Is a flag that can be waved.
    public static let isFlag = ItemAttributeID("isFlag")

    /// BURNBIT / FLAMEBIT: Is flammable or burning.
    public static let isFlammable = ItemAttributeID("isFlammable")

    /// Is a handle that can be turned.
    public static let isHandle = ItemAttributeID("isHandle")

    /// Can be inflated (like balloons, rafts, etc.).
    public static let isInflatable = ItemAttributeID("isInflatable")

    /// Is currently inflated.
    public static let isInflated = ItemAttributeID("isInflated")

    /// INVISIBLE: Not normally seen (object is invisible).
    public static let isInvisible = ItemAttributeID("isInvisible")

    /// Can be used to lock/unlock.
    public static let isKey = ItemAttributeID("isKey")

    /// Is a knob that can be turned with clicking sounds.
    public static let isKnob = ItemAttributeID("isKnob")

    /// LIGHTBIT: Provides light when active/on.
    public static let isLightSource = ItemAttributeID("isLightSource")

    /// Contains liquid that can be heard when shaken.
    public static let isLiquidContainer = ItemAttributeID("isLiquidContainer")

    /// Indicates whether an entity is currently considered "lit".
    public static let isLit = ItemAttributeID("isLit")

    /// LOCKBIT: Can be locked/unlocked (needs `lockKey`).
    public static let isLockable = ItemAttributeID("isLockable")

    /// LOCKED: Is locked.
    public static let isLocked = ItemAttributeID("isLocked")

    /// ONBIT: Is currently switched on.
    public static let isOn = ItemAttributeID("isOn")  // Note: Potential overlap with computed isLit? Review needed.

    /// OPENBIT: Whether a container item is currently open.
    public static let isOpen = ItemAttributeID("isOpen")

    /// OPENABLEBIT: Can be opened/closed by player.
    public static let isOpenable = ItemAttributeID("isOpenable")

    /// PERSONBIT: An NPC or the player.
    public static let isPerson = ItemAttributeID("isPerson")

    /// PLURALBIT: Grammatically plural.
    public static let isPlural = ItemAttributeID("isPlural")

    /// Indicates a plant that can be watered.
    public static let isPlant = ItemAttributeID("isPlant")

    /// Can be pressed (like buttons, switches).
    public static let isPressable = ItemAttributeID("isPressable")

    /// Can be pulled.
    public static let isPullable = ItemAttributeID("isPullable")

    /// READBIT: Can be read (implies text content).
    public static let isReadable = ItemAttributeID("isReadable")

    /// Is a rope-like object that can have knots tied in it.
    public static let isRope = ItemAttributeID("isRope")

    /// SEARCHBIT: Can be searched.
    public static let isSearchable = ItemAttributeID("isSearchable")

    /// Is a soft, yielding object (like pillows, cushions).
    public static let isSoft = ItemAttributeID("isSoft")

    /// Is a sponge that can absorb and release water.
    public static let isSponge = ItemAttributeID("isSponge")

    /// Is a magical staff that can be waved.
    public static let isStaff = ItemAttributeID("isStaff")

    /// SURFACEBIT: Items can be placed *on* it.
    public static let isSurface = ItemAttributeID("isSurface")

    /// TAKEBIT: Can be picked up.
    public static let isTakable = ItemAttributeID("isTakable")

    /// TOOLBIT: Is a tool (specific game logic).
    public static let isTool = ItemAttributeID("isTool")

    /// TOUCHBIT: Player has interacted with it (used for brief mode descriptions).
    public static let isTouched = ItemAttributeID("isTouched")

    /// TRANSBIT: Contents are visible even if closed.
    public static let isTransparent = ItemAttributeID("isTransparent")

    /// TRYTAKEBIT: Needs special check before taking.
    public static let requiresTryTake = ItemAttributeID("requiresTryTake")

    /// VEHBIT: Is a vehicle.
    public static let isVehicle = ItemAttributeID("isVehicle")

    /// VOWELBIT: Name starts with vowel (for "an").
    public static let startsWithVowel = ItemAttributeID("startsWithVowel")

    /// Is a magical wand that can be waved.
    public static let isWand = ItemAttributeID("isWand")

    /// WEAPONBIT: Is a weapon.
    public static let isWeapon = ItemAttributeID("isWeapon")

    /// WEARBIT: Can be worn.
    public static let isWearable = ItemAttributeID("isWearable")

    /// Is a wheel that can be turned with effort.
    public static let isWheel = ItemAttributeID("isWheel")

    /// WORNBIT: Is currently being worn.
    public static let isWorn = ItemAttributeID("isWorn")

    /// NARTICLEBIT: Omit default article ("a", "the").
    public static let omitArticle = ItemAttributeID("omitArticle")

    /// NDESCBIT: Omit automatic description in room contents.
    public static let omitDescription = ItemAttributeID("omitDescription")
}
