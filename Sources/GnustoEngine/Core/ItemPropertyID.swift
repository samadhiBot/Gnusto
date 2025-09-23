import Foundation

/// A unique identifier for a standard or dynamic property within the game.
public struct ItemPropertyID: GnustoID {
    public let rawValue: String

    /// Initializes a `PropertyID` with a raw string value.
    /// - Parameter rawValue: The string value for the ID.
    public init(rawValue: String) {
        assert(rawValue.isNotEmpty, "Property ID cannot be empty")
        self.rawValue = rawValue
    }
}

// MARK: - General Property IDs

extension ItemPropertyID {
    /// Adjectives associated with an item (e.g., "brass", "small"), used for disambiguation.
    public static let adjectives = ItemPropertyID("adjectives")

    /// The carrying capacity of a container item.
    public static let capacity = ItemPropertyID("capacity")

    /// Comprehensive character sheet containing all attributes, properties, and states for NPCs.
    public static let characterSheet = ItemPropertyID("characterSheet")

    /// The maximum damage that an item can inflict when used as a weapon.
    public static let damage = ItemPropertyID("damage")

    /// The key needed to lock/unlock an item (if `.isLockable`).
    public static let lockKey = ItemPropertyID("lockKey")

    /// The primary noun used to refer to the item (ZIL: `DESC`).
    public static let name = ItemPropertyID("name")

    /// The identifier of the item's parent entity.
    public static let parentEntity = ItemPropertyID("parentEntity")

    /// An item's size, influencing carrying capacity and container limits.
    public static let size = ItemPropertyID("size")

    /// Character properties (D&D-style) for combat and skill calculations.
    public static let properties = ItemPropertyID("properties")

    /// Synonyms for an item (e.g., "lamp", "light").
    public static let synonyms = ItemPropertyID("synonyms")

    /// The locations where a character is allowed to travel.
    public static let validLocations = ItemPropertyID("validLocations")

    /// An item's static value, typically its monetary worth (ZIL: `VALUE`).
    public static let value = ItemPropertyID("value")

    /// An item's temporary value, used when its value needs to change at runtime (ZIL: `TVALUE`).
    public static let tmpValue = ItemPropertyID("tmpValue")
}

// MARK: - Descriptions

extension ItemPropertyID {
    /// The description shown the first time an item is seen (ZIL `FDESC`).
    public static let firstDescription = ItemPropertyID("firstDescription")

    /// The primary, detailed description (ZIL `LDESC`).
    public static let description = ItemPropertyID("description")

    /// The shorter description used in lists or brief mentions (ZIL `SDESC`).
    public static let shortDescription = ItemPropertyID("shortDescription")

    /// Text that can be read from an item (ZIL `RTEXT/TEXT`).
    public static let readText = ItemPropertyID("readText")

    /// Text that can be read from an item while holding it (ZILF `TEXT-HELD`).
    public static let readWhileHeldText = ItemPropertyID("readWhileHeldText")
}

// MARK: - Item Flags

extension ItemPropertyID {
    /// Is currently on fire or burning (ZIL: `FLAMEBIT`).
    public static let isBurning = ItemPropertyID("isBurning")

    /// Can be climbed (ZIL: `CLIMBBIT`).
    public static let isClimbable: ItemPropertyID = "isClimbable"

    /// Can hold other items (ZIL: `CONTBIT`).
    public static let isContainer = ItemPropertyID("isContainer")

    /// Can be turned on/off (ZILF specific) (ZIL: `DEVICEBIT`).
    public static let isDevice = ItemPropertyID("isDevice")

    /// Can be consumed as a liquid (ZIL: `DRINKBIT`).
    public static let isDrinkable = ItemPropertyID("isDrinkable")

    /// Can be eaten (ZIL: EDIBLEBIT / `FOODBIT`).
    public static let isEdible = ItemPropertyID("isEdible")

    /// Can be consumed by fire, like wood, paper, etc. (ZIL: `BURNBIT`).
    public static let isFlammable = ItemPropertyID("isFlammable")

    /// Can be inflated (like balloons, rafts, etc.).
    public static let isInflatable = ItemPropertyID("isInflatable")

    /// Is currently inflated.
    public static let isInflated = ItemPropertyID("isInflated")

    /// Not normally seen, i.e.object is invisible (ZIL: `INVISIBLE`).
    public static let isInvisible = ItemPropertyID("isInvisible")

    /// Provides light when active/on (ZIL: `LIGHTBIT`).
    public static let isLightSource = ItemPropertyID("isLightSource")

    /// Can be locked/unlocked, needs `lockKey` (ZIL: `LOCKBIT`).
    public static let isLockable = ItemPropertyID("isLockable")

    /// LOCKED: Is locked.
    public static let isLocked = ItemPropertyID("isLocked")

    /// Is currently switched on (ZIL: `ONBIT`).
    public static let isOn = ItemPropertyID("isOn")

    /// Whether a container item is currently open (ZIL: `OPENBIT`).
    public static let isOpen = ItemPropertyID("isOpen")

    /// Can be opened/closed by player (ZIL: `OPENABLEBIT`).
    public static let isOpenable = ItemPropertyID("isOpenable")

    /// Grammatically plural (ZIL: `PLURALBIT`).
    public static let isPlural = ItemPropertyID("isPlural")

    /// Can be read, implies text content (ZIL: `READBIT`).
    public static let isReadable = ItemPropertyID("isReadable")

    /// Can be searched (ZIL: `SEARCHBIT`).
    public static let isSearchable = ItemPropertyID("isSearchable")

    /// Can self-ignite without an external ignition source (like matches).
    public static let isSelfIgnitable = ItemPropertyID("isSelfIgnitable")

    /// Items can be placed *on* it (ZIL: `SURFACEBIT`).
    public static let isSurface = ItemPropertyID("isSurface")

    /// Can be picked up (ZIL: `TAKEBIT`).
    public static let isTakable = ItemPropertyID("isTakable")

    /// Is a tool, specific game logic (ZIL: `TOOLBIT`).
    public static let isTool = ItemPropertyID("isTool")

    /// Player has interacted with the item, used for brief mode descriptions (ZIL: `TOUCHBIT`).
    public static let isTouched = ItemPropertyID("isTouched")

    /// Contents are visible even if closed (ZIL: `TRANSBIT`).
    public static let isTransparent = ItemPropertyID("isTransparent")

    /// Is a vehicle (ZIL: `VEHBIT`).
    public static let isVehicle = ItemPropertyID("isVehicle")

    /// Is a weapon (ZIL: `WEAPONBIT`).
    public static let isWeapon = ItemPropertyID("isWeapon")

    /// Can be worn (ZIL: `WEARBIT`).
    public static let isWearable = ItemPropertyID("isWearable")

    /// Is currently being worn (ZIL: `WORNBIT`).
    public static let isWorn = ItemPropertyID("isWorn")

    /// Omit default article, i.e. "a" and "the" (ZIL: `NARTICLEBIT`).
    public static let omitArticle = ItemPropertyID("omitArticle")

    /// Omit automatic description in room contents (ZIL: `NDESCBIT`).
    public static let omitDescription = ItemPropertyID("omitDescription")

    /// Needs special check before taking (ZIL: `TRYTAKEBIT`).
    public static let requiresTryTake = ItemPropertyID("requiresTryTake")
}
