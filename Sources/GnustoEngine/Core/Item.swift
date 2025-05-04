import Foundation // Needed for Codable conformance for classes

/// A closure that dynamically generates a description string for an Item based on its state and the overall GameState.
public typealias ItemDescriptionHandler = @MainActor @Sendable (Item, GameState) async -> String?

/// Represents an interactable object within the game world.
/// Note: Marked @unchecked Sendable due to the type-erased `dynamicProperties` dictionary.
/// Care must be taken if accessing/mutating this dictionary concurrently.
public struct Item: Codable, Identifiable, Sendable {
    // --- Stored Properties (Alphabetical) ---

    /// Adjectives associated with the item (e.g., ["brass", "small"]). Used for disambiguation.
    public var adjectives: Set<String>

    /// The maximum total size of items this item can contain. -1 signifies unlimited capacity (ZILF default).
    public var capacity: Int

    /// Storage for state values and flags, potentially with associated dynamic behavior
    /// (computation/validation) defined externally in the `DynamicPropertyRegistry`.
    ///
    /// Use this for mutable state (e.g., open/closed status, charge level) and inherent
    /// boolean flags (e.g., is it a container, wearable, etc.). Values are keyed by `PropertyID`.
    ///
    /// This dictionary represents the *current state* of the item's dynamic aspects and
    /// fundamental flags. Access and modification should typically go through `GameEngine`
    /// helper methods (like `getDynamicItemValue`, `setDynamicItemValue`) or convenience
    /// accessors like `flag(_:)` to ensure any associated logic is correctly applied.
    ///
    /// Values are typically represented using the `StateValue` enum (e.g., `.string`, `.bool`, `.int`).
    public var dynamicValues: [PropertyID: StateValue]

    // Action handler - Placeholder.
    // var actionHandlerID: String?

    /// Represents the unique identifier for this item.
    public let id: ItemID

    /// The key needed to lock/unlock this item (if `.lockable`).
    public var lockKey: ItemID? = nil

    /// The primary noun used to refer to the item (e.g., "lantern").
    public var name: String

    /// The entity that currently contains or supports this item.
    public var parent: ParentEntity

    /// The item's size, influencing carrying capacity and container limits. Defaults to 5 per ZILF docs.
    public var size: Int

    /// Synonyms for the item's name (e.g., ["lamp", "light"]).
    public var synonyms: Set<String>

    // MARK: - Initializer

    public init(
        id: ItemID,
        name: String,
        adjectives: String...,
        synonyms: String...,
        shortDescription: String? = nil,
        firstDescription: String? = nil,
        longDescription: String? = nil,
        readText: String? = nil,
        heldText: String? = nil,
        dynamicValues: [PropertyID: StateValue] = [:],
        size: Int = 5,
        capacity: Int = -1,
        parent: ParentEntity = .nowhere,
        lockKey: ItemID? = nil,
        // actionHandlerID: String? = nil,

        // Common Flags (Migrated from ItemProperty)
        isCombatReady: Bool = false,
        isContainer: Bool = false,
        isDevice: Bool = false,
        isDoor: Bool = false,
        isEdible: Bool = false,
        isEquippable: Bool = false,
        isFemale: Bool = false,
        isFixed: Bool = false,
        isFlammable: Bool = false,
        isInvisible: Bool = false,
        isKey: Bool = false,
        isLightSource: Bool = false,
        isLockable: Bool = false,
        isLocked: Bool = false,
        suppressArticle: Bool = false,
        suppressDescription: Bool = false,
        isOn: Bool = false,
        isOpenable: Bool = false,
        isPerson: Bool = false,
        isPlural: Bool = false,
        isReadable: Bool = false,
        isSearchable: Bool = false,
        isSurface: Bool = false,
        isTakable: Bool = true, // Default to takable unless specified otherwise
        itemTouched: Bool = false,
        isTransparent: Bool = false,
        requiresTryTake: Bool = false,
        startsWithVowel: Bool = false, // Should be computed ideally
        isWearable: Bool = false,
        isWorn: Bool = false
    ) {
        self.id = id
        self.name = name
        self.adjectives = Set(adjectives)
        self.synonyms = Set(synonyms)
        self.size = size
        self.capacity = capacity
        self.parent = parent
        self.lockKey = lockKey
        // self.actionHandlerID = actionHandlerID

        // Initialize dynamic values from parameters and flags
        var initialValues = dynamicValues
        if let shortDescription { initialValues[.shortDescription] = .string(shortDescription) }
        if let firstDescription { initialValues[.itemFirstDescription] = .string(firstDescription) }
        if let longDescription { initialValues[.longDescription] = .string(longDescription) }
        if let readText { initialValues[.itemReadText] = .string(readText) }
        if let heldText { initialValues[.itemHeldText] = .string(heldText) }

        // Set boolean flags
        if isCombatReady { initialValues[.isCombatReady] = .bool(true) }
        if isContainer { initialValues[.isContainer] = .bool(true) }
        if isDevice { initialValues[.isDevice] = .bool(true) }
        if isDoor { initialValues[.isDoor] = .bool(true) }
        if isEdible { initialValues[.isEdible] = .bool(true) }
        if isEquippable { initialValues[.isEquippable] = .bool(true) }
        if isFemale { initialValues[.isFemale] = .bool(true) }
        if isFixed { initialValues[.isFixed] = .bool(true) }
        if isFlammable { initialValues[.isFlammable] = .bool(true) }
        if isInvisible { initialValues[.isInvisible] = .bool(true) }
        if isKey { initialValues[.isKey] = .bool(true) }
        if isLightSource { initialValues[.isLightSource] = .bool(true) }
        if isLockable { initialValues[.isLockable] = .bool(true) }
        if isLocked { initialValues[.isLocked] = .bool(true) }
        if suppressArticle { initialValues[.suppressArticle] = .bool(true) }
        if suppressDescription { initialValues[.suppressDescription] = .bool(true) }
        if isOn { initialValues[.isOn] = .bool(true) }
        if isOpenable { initialValues[.isOpenable] = .bool(true) }
        if isPerson { initialValues[.isPerson] = .bool(true) }
        if isPlural { initialValues[.isPlural] = .bool(true) }
        if isReadable { initialValues[.isReadable] = .bool(true) }
        if isSearchable { initialValues[.isSearchable] = .bool(true) }
        if isSurface { initialValues[.isSurface] = .bool(true) }
        if isTakable { initialValues[.isTakable] = .bool(true) } else { initialValues[.isTakable] = .bool(false) } // Explicitly set false if not takable
        if itemTouched { initialValues[.itemTouched] = .bool(true) }
        if isTransparent { initialValues[.isTransparent] = .bool(true) }
        if requiresTryTake { initialValues[.requiresTryTake] = .bool(true) }
        if startsWithVowel { initialValues[.startsWithVowel] = .bool(true) }
        if isWearable { initialValues[.isWearable] = .bool(true) }
        if isWorn { initialValues[.isWorn] = .bool(true) }

        self.dynamicValues = initialValues
    }

    // MARK: - Codable Conformance

    private enum CodingKeys: String, CodingKey {
        // Removed 'properties'
        case id, name, adjectives, synonyms, size, capacity, parent, lockKey, dynamicValues
    }

    // init(from:) and encode(to:) implicitly handle dynamicValues
    // No changes needed here unless we want custom logic beyond default Codable behavior.

    // MARK: - Convenience Accessors

    /// Checks if a boolean flag is set in the item's `dynamicValues`.
    /// - Parameter id: The `PropertyID` of the flag to check.
    /// - Returns: `true` if the flag exists and is set to `true`, `false` otherwise.
    public func flag(_ id: PropertyID) -> Bool {
        dynamicValues[id] == .bool(true)
    }

    // Removed addProperty, removeProperty, hasProperty methods
}

// MARK: - Equatable Conformance

// Equatable conformance will be synthesized

// MARK: - Comparable conformance

extension Item: Comparable {
    public static func < (lhs: Item, rhs: Item) -> Bool {
        lhs.id < rhs.id
    }
}
