import Foundation

/// A unique identifier for a standard or dynamic property within the game.
public struct AttributeID: Hashable, Comparable, Codable, ExpressibleByStringLiteral, Sendable {
    public let rawValue: String

    /// Initializes a `AttributeID` using a string literal.
    /// - Parameter value: The string literal representing the property ID.
    public init(stringLiteral value: String) {
        assert(!value.isEmpty, "Attribute ID cannot be empty")
        self.rawValue = value
    }

    /// Initializes a `AttributeID` with a raw string value.
    /// - Parameter rawValue: The string value for the ID.
    public init(_ rawValue: String) {
        assert(!rawValue.isEmpty, "Attribute ID cannot be empty")
        self.rawValue = rawValue
    }

    public static func < (lhs: AttributeID, rhs: AttributeID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - General Property IDs

public extension AttributeID {
    /// Adjectives associated with an item (e.g., "brass", "small"), used for disambiguation.
    static let adjectives = AttributeID("adjectives")

    /// The carrying capacity of a container item.
    static let capacity = AttributeID("capacity")

    /// Items that are considered local to a location (e.g. fixed scenery) and always in scope.
    static let localGlobals = AttributeID("localGlobals")
    
    /// The available exits from a location.
    static let locationExits = AttributeID("locationExits")

    /// The key needed to lock/unlock an item (if `.isLockable`).
    static let lockKey = AttributeID("lockKey")
    
    /// The identifier of the item's parent entity.
    static let parentEntity = AttributeID("parentEntity")

    /// An item's size, influencing carrying capacity and container limits.
    static let size = AttributeID("size")

    /// Synonyms for an item (e.g., "lamp", "light").
    static let synonyms = AttributeID("synonyms")
}

// MARK: - Descriptions

public extension AttributeID {
    /// The description shown the first time an item is seen (ZIL `FDESC`).
    static let firstDescription = AttributeID("firstDescription")

    /// The primary, detailed description (ZIL `LDESC`).
    static let description = AttributeID("description")

    /// The shorter description used in lists or brief mentions (ZIL `SDESC`).
    static let shortDescription = AttributeID("shortDescription")

    /// Text that can be read from an item (ZIL `RTEXT/TEXT`).
    static let readText = AttributeID("readText")

    /// Text that can be read from an item while holding it (ZILF `TEXT-HELD`).
    static let readWhileHeldText = AttributeID("readWhileHeldText")
}

// MARK: - Item Flags

public extension AttributeID {
    /// ACTORBIT: Is a non-player character.
    static let isCharacter = AttributeID("isCharacter")

    /// CLIMBBIT: Can be climbed.
    static let isClimbable: AttributeID = "isClimbable"

    /// FIGHTBIT: Can participate in combat.
    static let isCombatReady = AttributeID("isCombatReady")

    /// CONTBIT: Can hold other items.
    static let isContainer = AttributeID("isContainer")

    /// DEVICEBIT: Can be turned on/off (ZILF specific).
    static let isDevice = AttributeID("isDevice")

    /// DOORBIT: Functions as a door.
    static let isDoor = AttributeID("isDoor")

    /// EDIBLEBIT / FOODBIT: Can be eaten.
    static let isEdible = AttributeID("isEdible")

    /// Can be equipped (e.g., weapon, shield).
    static let isEquippable = AttributeID("isEquippable")

    /// FEMALEBIT: Grammatically female.
    static let isFemale = AttributeID("isFemale")

    /// Cannot be taken or moved (scenery).
    static let isFixed = AttributeID("isFixed")

    /// BURNBIT / FLAMEBIT: Is flammable or burning.
    static let isFlammable = AttributeID("isFlammable")

    /// INVISIBLE: Not normally seen (object is invisible).
    static let isInvisible = AttributeID("isInvisible")

    /// Can be used to lock/unlock.
    static let isKey = AttributeID("isKey")

    /// LIGHTBIT: Provides light when active/on.
    static let isLightSource = AttributeID("isLightSource")

    /// Indicates whether an entity is currently considered "lit".
    static let isLit = AttributeID("isLit")

    /// LOCKBIT: Can be locked/unlocked (needs `lockKey`).
    static let isLockable = AttributeID("isLockable")

    /// LOCKED: Is locked.
    static let isLocked = AttributeID("isLocked")

    /// NARTICLEBIT: Suppress default article ("a", "the").
    static let suppressArticle = AttributeID("suppressArticle")

    /// NDESCBIT: Suppress automatic description in room contents.
    static let suppressDescription = AttributeID("suppressDescription")

    /// ONBIT: Is currently switched on.
    static let isOn = AttributeID("isOn") // Note: Potential overlap with computed isLit? Review needed.

    /// OPENBIT: Whether a container item is currently open.
    static let isOpen = AttributeID("isOpen")

    /// OPENABLEBIT: Can be opened/closed by player.
    static let isOpenable = AttributeID("isOpenable")

    /// PERSONBIT: An NPC or the player.
    static let isPerson = AttributeID("isPerson")

    /// PLURALBIT: Grammatically plural.
    static let isPlural = AttributeID("isPlural")

    /// READBIT: Can be read (implies text content).
    static let isReadable = AttributeID("isReadable")

    /// SEARCHBIT: Can be searched.
    static let isSearchable = AttributeID("isSearchable")

    /// SURFACEBIT: Items can be placed *on* it.
    static let isSurface = AttributeID("isSurface")

    /// TAKEBIT: Can be picked up.
    static let isTakable = AttributeID("isTakable")

    /// TOOLBIT: Is a tool (specific game logic).
    static let isTool = AttributeID("isTool")

    /// TOUCHBIT: Player has interacted with it (used for brief mode descriptions).
    static let isTouched = AttributeID("isTouched")

    /// TRANSBIT: Contents are visible even if closed.
    static let isTransparent = AttributeID("isTransparent")

    /// TRYTAKEBIT: Needs special check before taking.
    static let requiresTryTake = AttributeID("requiresTryTake")

    /// VEHBIT: Is a vehicle.
    static let isVehicle = AttributeID("isVehicle")

    /// VOWELBIT: Name starts with vowel (for "an").
    static let startsWithVowel = AttributeID("startsWithVowel")
    
    /// WEAPONBIT: Is a weapon.
    static let isWeapon = AttributeID("isWeapon")

    /// WEARBIT: Can be worn.
    static let isWearable = AttributeID("isWearable")

    /// WORNBIT: Is currently being worn.
    static let isWorn = AttributeID("isWorn")
}

// MARK: - Location Flags

public extension AttributeID {
    /// RLIGHTBIT: Location is inherently lit (e.g., outdoors).
    static let inherentlyLit = AttributeID("inherentlyLit")

    /// Location is considered outdoors.
    static let isOutside = AttributeID("isOutside")

    /// Location is sacred, thus profanity is discouraged or disallowed here.
    static let isSacred = AttributeID("isSacred")

    /// RMUNGBIT: Location description has been changed.
    static let isChanged = AttributeID("isChanged")

    /// RLANDBIT: Location is land, not water/air.
    static let isLand = AttributeID("isLand")

    /// The player has visited this location previously.
    static let isVisited = AttributeID("isVisited")

    /// The location contains or is primarily composed of water.
    static let isWater = AttributeID("locationIsWater")

    /// Magic does not function here.
    static let breaksMagic = AttributeID("breaksMagic")
}
