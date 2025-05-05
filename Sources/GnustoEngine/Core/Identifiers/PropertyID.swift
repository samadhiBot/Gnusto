import Foundation

/// A unique identifier for a standard or dynamic property within the game.
public struct PropertyID: Hashable, Comparable, Codable, ExpressibleByStringLiteral, Sendable {
    public let rawValue: String

    /// Initializes a `PropertyID` using a string literal.
    /// - Parameter value: The string literal representing the property ID.
    public init(stringLiteral value: String) {
        // Consider adding validation or normalization if needed (e.g., lowercase)
        self.rawValue = value
    }

    /// Initializes a `PropertyID` with a raw string value.
    /// - Parameter rawValue: The string value for the ID.
    public init(_ rawValue: String) {
        // Consider adding validation or normalization if needed (e.g., lowercase)
        self.rawValue = rawValue
    }

    public static func < (lhs: PropertyID, rhs: PropertyID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - General Property IDs

public extension PropertyID {
    /// Adjectives associated with an item (e.g., "brass", "small"), used for disambiguation.
    static let adjectives = PropertyID("adjectives")

    /// The carrying capacity of a container item.
    static let capacity = PropertyID("capacity")

    /// Items that are considered local to a location (e.g. fixed scenery) and always in scope.
    static let localGlobals = PropertyID("localGlobals")

    /// The key needed to lock/unlock an item (if `.isLockable`).
    static let lockKey = PropertyID("lockKey")

    /// An item's size, influencing carrying capacity and container limits.
    static let size = PropertyID("size")

    /// Synonyms for an item (e.g., "lamp", "light").
    static let synonyms = PropertyID("synonyms")
}

// MARK: - Descriptions

public extension PropertyID {
    /// The description shown the first time an item is seen (ZIL `FDESC`).
    static let firstDescription = PropertyID("firstDescription")

    /// The primary, detailed description (ZIL `LDESC`).
    static let longDescription = PropertyID("longDescription")

    /// The shorter description used in lists or brief mentions (ZIL `SDESC`).
    static let shortDescription = PropertyID("shortDescription")

    /// Text that can be read from an item (ZIL `RTEXT/TEXT`).
    static let readText = PropertyID("readText")

    /// Text that can be read from an item while holding it (ZILF `TEXT-HELD`).
    static let readWhileHeldText = PropertyID("readWhileHeldText")
}

// MARK: - Item Flags

public extension PropertyID {
    /// ACTORBIT: Is a non-player character.
    static let isCharacter = PropertyID("isCharacter")

    /// CLIMBBIT: Can be climbed.
    static let isClimbable: PropertyID = "isClimbable"

    /// FIGHTBIT: Can participate in combat.
    static let isCombatReady = PropertyID("isCombatReady")

    /// CONTBIT: Can hold other items.
    static let isContainer = PropertyID("isContainer")

    /// DEVICEBIT: Can be turned on/off (ZILF specific).
    static let isDevice = PropertyID("isDevice")

    /// DOORBIT: Functions as a door.
    static let isDoor = PropertyID("isDoor")

    /// EDIBLEBIT / FOODBIT: Can be eaten.
    static let isEdible = PropertyID("isEdible")

    /// Can be equipped (e.g., weapon, shield).
    static let isEquippable = PropertyID("isEquippable")

    /// FEMALEBIT: Grammatically female.
    static let isFemale = PropertyID("isFemale")

    /// Cannot be taken or moved (scenery).
    static let isFixed = PropertyID("isFixed")

    /// BURNBIT / FLAMEBIT: Is flammable or burning.
    static let isFlammable = PropertyID("isFlammable")

    /// INVISIBLE: Not normally seen (object is invisible).
    static let isInvisible = PropertyID("isInvisible")

    /// Can be used to lock/unlock.
    static let isKey = PropertyID("isKey")

    /// LIGHTBIT: Provides light when active/on.
    static let isLightSource = PropertyID("isLightSource")

    /// Indicates whether an entity is currently considered "lit".
    static let isLit = PropertyID("isLit")

    /// LOCKBIT: Can be locked/unlocked (needs `lockKey`).
    static let isLockable = PropertyID("isLockable")

    /// LOCKED: Is locked.
    static let isLocked = PropertyID("isLocked")

    /// NARTICLEBIT: Suppress default article ("a", "the").
    static let suppressArticle = PropertyID("suppressArticle")

    /// NDESCBIT: Suppress automatic description in room contents.
    static let suppressDescription = PropertyID("suppressDescription")

    /// ONBIT: Is currently switched on.
    static let isOn = PropertyID("isOn") // Note: Potential overlap with computed isLit? Review needed.

    /// OPENBIT: Whether a container item is currently open.
    static let isOpen = PropertyID("isOpen")

    /// OPENABLEBIT: Can be opened/closed by player.
    static let isOpenable = PropertyID("isOpenable") // Note: Different from `isOpen` state.

    /// PERSONBIT: An NPC or the player.
    static let isPerson = PropertyID("isPerson")

    /// PLURALBIT: Grammatically plural.
    static let isPlural = PropertyID("isPlural")

    /// READBIT: Can be read (implies text content).
    static let isReadable = PropertyID("isReadable")

    /// SEARCHBIT: Can be searched.
    static let isSearchable = PropertyID("isSearchable")

    /// SURFACEBIT: Items can be placed *on* it.
    static let isSurface = PropertyID("isSurface")

    /// TAKEBIT: Can be picked up.
    static let isTakable = PropertyID("isTakable")

    /// TOOLBIT: Is a tool (specific game logic).
    static let isTool = PropertyID("isTool")

    /// TOUCHBIT: Player has interacted with it (used for brief mode descriptions).
    static let itemTouched = PropertyID("itemTouched")

    /// TRANSBIT: Contents are visible even if closed.
    static let isTransparent = PropertyID("isTransparent")

    /// TRYTAKEBIT: Needs special check before taking.
    static let requiresTryTake = PropertyID("requiresTryTake")

    /// VEHBIT: Is a vehicle.
    static let isVehicle = PropertyID("isVehicle")

    /// VOWELBIT: Name starts with vowel (for "an").
    static let startsWithVowel = PropertyID("startsWithVowel")
    
    /// WEAPONBIT: Is a weapon.
    static let isWeapon = PropertyID("isWeapon")

    /// WEARBIT: Can be worn.
    static let isWearable = PropertyID("isWearable")

    /// WORNBIT: Is currently being worn.
    static let isWorn = PropertyID("isWorn")
}

// MARK: - Location Flags

public extension PropertyID {
    /// RLIGHTBIT: Location is inherently lit (e.g., outdoors).
    static let inherentlyLit = PropertyID("inherentlyLit")

    /// Location is considered outdoors.
    static let isOutside = PropertyID("isOutside")

    /// Location is sacred, thus profanity is discouraged or disallowed here.
    static let isSacred = PropertyID("isSacred")

    /// RMUNGBIT: Location description has been changed.
    static let isChanged = PropertyID("isChanged")

    /// RLANDBIT: Location is land, not water/air.
    static let isLand = PropertyID("isLand")

    /// The player has visited this location previously.
    static let isVisited = PropertyID("isVisited")

    /// The location contains or is primarily composed of water.
    static let isWater = PropertyID("locationIsWater")

    /// Magic does not function here.
    static let breaksMagic = PropertyID("breaksMagic")
}
