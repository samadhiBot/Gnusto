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

// MARK: - Standard Property IDs

public extension PropertyID {
    // --- General ---

    /// The current carrying capacity of a container item.
    /// Might be computed based on contents or other factors.
    static let currentCapacity = PropertyID("currentCapacity")

    /// Indicates whether an entity is currently considered "lit".
    /// Typically computed based on light sources in scope.
    static let isLit = PropertyID("isLit")

    /// Boolean state indicating whether a container item is currently open.
    static let isOpen = PropertyID("isOpen")

    // --- Descriptions ---

    /// The primary, detailed description (ZIL LDESC).
    static let longDescription = PropertyID("longDescription")

    /// The shorter description used in lists or brief mentions (ZIL SDESC).
    static let shortDescription = PropertyID("shortDescription")

    /// The description shown the first time an item is seen in a room (ZIL FDESC). (Item only)
    static let itemFirstDescription = PropertyID("itemFirstDescription")

    /// Text read from an item (ZIL RTEXT/TEXT). (Item only)
    static let itemReadText = PropertyID("itemReadText")

    /// Text read only when item is held (ZIL HTEXT). (Item only)
    static let itemHeldText = PropertyID("itemHeldText")

    // --- Item Flags (Migrated from ItemProperty) ---

    /// FIGHTBIT: Can participate in combat.
    static let isCombatReady = PropertyID("isCombatReady")
    /// CONTBIT: Can hold other items.
    static let isContainer = PropertyID("isContainer")
    /// DEVICEBIT: Can be turned on/off (ZILF specific).
    static let isDevice = PropertyID("isDevice")
    /// DOORBIT: Functions as a door.
    static let isDoor = PropertyID("isDoor")
    /// EDIBLEBIT: Can be eaten.
    static let isEdible = PropertyID("isEdible")
    /// Can be equipped (e.g., weapon, shield).
    static let isEquippable = PropertyID("isEquippable")
    /// FEMALEBIT: Grammatically female.
    static let isFemale = PropertyID("isFemale")
    /// Cannot be taken or moved (scenery).
    static let isFixed = PropertyID("isFixed")
    /// Can be burned.
    static let isFlammable = PropertyID("isFlammable")
    /// INVISIBLE: Not normally seen.
    static let isInvisible = PropertyID("isInvisible")
    /// Can be used to lock/unlock.
    static let isKey = PropertyID("isKey")
    /// LIGHTBIT: Provides light when active/on.
    static let isLightSource = PropertyID("isLightSource")
    /// Can be locked/unlocked (needs `lockKey`).
    static let isLockable = PropertyID("isLockable")
    /// LOCKEDBIT: Is locked.
    static let isLocked = PropertyID("isLocked")
    /// NARTICLEBIT: Suppress default article ("a", "the").
    static let suppressArticle = PropertyID("suppressArticle")
    /// NDESCBIT: Suppress automatic description in room contents.
    static let suppressDescription = PropertyID("suppressDescription")
    /// ONBIT: Is currently switched on.
    static let isOn = PropertyID("isOn") // Note: Potential overlap with computed isLit? Review needed.
    /// OPENABLEBIT: Can be opened/closed by player.
    static let isOpenable = PropertyID("isOpenable") // Note: Different from `isOpen` state.
    /// PERSONBIT: An NPC or the player.
    static let isPerson = PropertyID("isPerson")
    /// PLURALBIT: Grammatically plural.
    static let isPlural = PropertyID("isPlural")
    /// READBIT: Can be read (might have TEXT property). - Deprecated? Use `itemReadText` check.
    // static let isRead = PropertyID("isRead") // Consider if needed vs checking for itemReadText
    /// Can be read (implies text content).
    static let isReadable = PropertyID("isReadable")
    /// SEARCHBIT: Can be searched.
    static let isSearchable = PropertyID("isSearchable")
    /// SURFACEBIT: Items can be placed *on* it.
    static let isSurface = PropertyID("isSurface")
    /// TAKEBIT: Can be picked up.
    static let isTakable = PropertyID("isTakable")
    /// TOUCHBIT: Player has interacted with it (used for brief mode descriptions).
    static let itemTouched = PropertyID("itemTouched")
    /// TRANSBIT: Contents are visible even if closed.
    static let isTransparent = PropertyID("isTransparent")
    /// TRYTAKEBIT: Needs special check before taking.
    static let requiresTryTake = PropertyID("requiresTryTake")
    /// VOWELBIT: Name starts with vowel (for "an").
    static let startsWithVowel = PropertyID("startsWithVowel")
    /// WEARBIT: Can be worn.
    static let isWearable = PropertyID("isWearable")
    /// WORNBIT: Is currently being worn.
    static let isWorn = PropertyID("isWorn")

    // --- Location Flags (Migrated from LocationProperty) ---

    /// RLIGHTBIT: Location is inherently lit (e.g., outdoors).
    static let locationInherentlyLit = PropertyID("locationInherentlyLit")

    /// Location is currently lit (set by engine based on light sources or inherent lit status).
    static let locationIsLit = PropertyID("locationIsLit") // Note: Conflict with general `isLit`? Consider renaming/merging.

    /// Magic does not function here.
    static let locationNoMagic = PropertyID("locationNoMagic")

    /// Location is considered outdoors.
    static let locationIsOutside = PropertyID("locationIsOutside")

    /// Profanity is discouraged or disallowed here.
    static let locationIsSacred = PropertyID("locationIsSacred")

    /// RMUNGBIT: Room description has been changed.
    static let locationDescriptionChanged = PropertyID("locationDescriptionChanged")

    /// RLANDBIT: Room is land, not water/air.
    static let locationIsLand = PropertyID("locationIsLand")

    /// The player has visited this location previously.
    static let locationVisited = PropertyID("locationVisited")

    /// The location contains or is primarily composed of water.
    static let locationIsWater = PropertyID("locationIsWater")

    // Add other standard property IDs as needed, e.g., for lock states,
    // open/closed states, specific game mechanics, etc.
}
