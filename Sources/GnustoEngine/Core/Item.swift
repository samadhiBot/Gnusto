import Foundation

/// Represents an interactive object or entity within the game world, such as a brass lantern,
/// a rusty key, a treasure chest, or even a non-player character (NPC).
///
/// Each `Item` has a unique `id` (`ItemID`) and a collection of `properties` that define its
/// current state, characteristics, and behaviors (e.g., its name, description, location,
/// whether it's openable, takable, etc.).
///
/// Game developers define items by providing an `ItemID` and a list of initial
/// `ItemProperty`s. Many common properties (like `name`, `parent`, `adjectives`)
/// have convenience computed properties for easy access and modification through the `GameEngine`.
/// The raw state of all properties is stored in the `properties` dictionary using `PropertyID`
/// as keys.
///
/// Items are a fundamental part of the `GameState` and are manipulated by player commands
/// and game logic, often through `ActionHandler`s and `GameEngine` helper methods.
public struct Item: Codable, Hashable, Sendable {
    /// The item's unique `ItemID`, serving as its primary key within the game.
    public let id: ItemID

    /// A dictionary holding the current state of all properties for this item.
    ///
    /// Each key is a `PropertyID` (e.g., `.name`, `.description`, `.itemParent`) and the value
    /// is a `StateValue` wrapper containing the actual typed data for that property. While direct
    /// access is possible, game logic typically interacts with these properties via convenience
    /// accessors on `Item` (for reading) or through `GameEngine` methods (for modifications, which
    /// generate `StateChange`s).
    public var properties: [ItemPropertyID: StateValue]

    /// Creates a new `Item` instance with a given ID and initial properties.
    ///
    /// The `properties` parameter takes a variadic list of `ItemProperty` instances.
    /// `ItemProperty` is a helper enum that encapsulates both the `PropertyID` (the key)
    /// and the initial `StateValue` for a property.
    ///
    /// Example:
    /// ```swift
    /// let lantern = Item(
    ///     id: "brassLantern",
    ///     .name("brass lantern"),
    ///     .description("A tarnished brass lantern, surprisingly heavy."),
    ///     .synonyms(["lantern", "light"]),
    ///     .adjectives(["brass", "tarnished", "heavy"]),
    ///     .in(.livingRoom),
    ///     .isTakable,
    ///     .isDevice,
    ///     .isOn,
    ///     .size(10)
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - id: The item's unique `ItemID`.
    ///   - properties: A variadic list of `ItemProperty`s defining the item's initial state.
    public init(
        id: ItemID,
        _ properties: ItemProperty...
    ) {
        self.id = id
        self.properties = Dictionary(
            uniqueKeysWithValues: properties.map { ($0.id, $0.rawValue) }
        )
    }

    /// Creates a new `Item` with the given `id` and an empty set of properties.
    ///
    /// Use this initializer when you need to construct an item and populate its properties
    /// later (for example, during incremental setup or procedural generation). The created
    /// `Item` will start with no properties; properties can be added directly to the
    /// `properties` dictionary or via `GameEngine` methods which will generate tracked
    /// `StateChange`s and maintain game state consistency.
    ///
    /// - Parameter id: The unique `ItemID` for the item.
    public init(_ id: ItemID) {
        self.id = id
        self.properties = [:]
    }

    /// Creates an `ItemProxy` for this item using the provided game engine.
    ///
    /// An `ItemProxy` provides a convenient interface for reading and modifying item properties
    /// through the game engine, ensuring that all changes are properly tracked as `StateChange`s
    /// and maintaining game state consistency.
    ///
    /// This is the recommended way to interact with items during gameplay, as it provides
    /// type-safe access to properties and integrates with the engine's state management system.
    ///
    /// - Parameter engine: The `GameEngine` instance to use for creating the proxy.
    /// - Returns: An `ItemProxy` instance for this item.
    /// - Throws: Any errors that occur during proxy creation, typically if the item
    ///   doesn't exist in the current game state.
    public func proxy(_ engine: GameEngine) async -> ItemProxy {
        await engine.item(id)
    }
}

// MARK: - Comparable conformance

extension Item: Comparable {
    public static func < (lhs: Item, rhs: Item) -> Bool {
        lhs.id < rhs.id
    }
}

// MARK: - Chaining modifiers (value properties)

extension Item {
    /// Adjectives associated with an item, used for disambiguation and natural language parsing.
    ///
    /// - Parameter adjectives: Descriptive adjectives that can be used to refer to this item.
    /// - Returns: A modified `Item` with the adjectives property set.
    public func adjectives(_ adjectives: String...) -> Self {
        assigning(.adjectives, to: .stringSet(Set(adjectives)))
    }

    /// Character-specific attributes for NPCs and actors.
    ///
    /// - Parameter sheet: The character's behavioral and social attributes.
    /// - Returns: A modified `Item` with the characterSheet property set.
    public func characterSheet(_ sheet: CharacterSheet) -> Self {
        assigning(.characterSheet, to: .characterSheet(sheet))
    }

    /// The carrying capacity of a container item, measured in size units.
    ///
    /// - Parameter capacity: Maximum size units this container can hold.
    /// - Returns: A modified `Item` with the capacity property set.
    public func capacity(_ capacity: Int) -> Self {
        assigning(.capacity, to: .int(capacity))
    }

    /// The maximum damage this item can inflict when used as a weapon.
    ///
    /// - Parameter damage: Maximum damage points this weapon can inflict.
    /// - Returns: A modified `Item` with the damage property set.
    public func damage(_ damage: Int) -> Self {
        assigning(.damage, to: .int(damage))
    }

    /// The item's primary, detailed description shown when examining it.
    ///
    /// - Parameter description: The detailed examination text for this item.
    /// - Returns: A modified `Item` with the description property set.
    public func description(_ description: String) -> Self {
        assigning(.description, to: .string(description))
    }

    /// The description shown the first time an item is encountered in a location.
    ///
    /// - Parameter description: The initial encounter description for this item.
    /// - Returns: A modified `Item` with the firstDescription property set.
    public func firstDescription(_ description: String) -> Self {
        assigning(.firstDescription, to: .string(description))
    }

    /// The item's current parent entity - where it's currently located.
    ///
    /// - Parameter parent: Where this item is currently located.
    /// - Returns: A modified `Item` with the parentEntity property set.
    public func `in`(_ parent: ParentEntity) -> Self {
        assigning(.parentEntity, to: .parentEntity(parent))
    }

    /// Convenience method for placing an item directly in a location.
    ///
    /// - Parameter locationID: The location where this item should be placed.
    /// - Returns: A modified `Item` with the parentEntity property set to the location.
    public func `in`(_ locationID: LocationID) -> Self {
        assigning(.parentEntity, to: .parentEntity(.location(locationID)))
    }

    /// The specific key item needed to lock or unlock this item.
    ///
    /// - Parameter lockKey: The ItemID of the key required to operate this lock.
    /// - Returns: A modified `Item` with the lockKey property set.
    public func lockKey(_ lockKey: ItemID) -> Self {
        assigning(.lockKey, to: .itemID(lockKey))
    }

    /// Restricts which locations this item can exist in.
    ///
    /// - Parameter locations: LocationIDs where this item is allowed to exist.
    /// - Returns: A modified `Item` with the validLocations property set.
    public func validLocations(_ locations: LocationID...) -> Self {
        assigning(.validLocations, to: .locationIDSet(Set(locations)))
    }

    /// The primary name used to refer to the item in game text.
    ///
    /// - Parameter name: The primary display name for this item.
    /// - Returns: A modified `Item` with the name property set.
    public func name(_ name: String) -> Self {
        assigning(.name, to: .string(name))
    }

    /// Text content that can be read from this item.
    ///
    /// - Parameter text: The readable content of this item.
    /// - Returns: A modified `Item` with the readText property set.
    public func readText(_ text: String) -> Self {
        assigning(.readText, to: .string(text))
    }

    /// Alternative text displayed when reading this item while holding it.
    ///
    /// - Parameter text: The enhanced readable content available when holding this item.
    /// - Returns: A modified `Item` with the readWhileHeldText property set.
    public func readWhileHeldText(_ text: String) -> Self {
        assigning(.readWhileHeldText, to: .string(text))
    }

    /// A shorter description used in inventory lists and brief mentions.
    ///
    /// - Parameter description: A brief description of this item.
    /// - Returns: A modified `Item` with the shortDescription property set.
    public func shortDescription(_ description: String) -> Self {
        assigning(.shortDescription, to: .string(description))
    }

    /// The item's size in abstract units, affecting inventory and container management.
    ///
    /// - Parameter size: The size units this item occupies.
    /// - Returns: A modified `Item` with the size property set.
    public func size(_ size: Int) -> Self {
        assigning(.size, to: .int(size))
    }

    /// Alternative names the player can use to refer to this item in commands.
    ///
    /// - Parameter synonyms: Alternative names players can use for this item.
    /// - Returns: A modified `Item` with the synonyms property set.
    public func synonyms(_ synonyms: String...) -> Self {
        assigning(.synonyms, to: .stringSet(Set(synonyms)))
    }

    /// The item's inherent value, typically monetary worth or game score contribution.
    ///
    /// - Parameter value: The item's inherent worth or point value.
    /// - Returns: A modified `Item` with the value property set.
    public func value(_ value: Int) -> Self {
        assigning(.value, to: .int(value))
    }

    /// A mutable value that can change during gameplay for dynamic item properties.
    ///
    /// - Parameter tmpValue: The initial temporary value for this item.
    /// - Returns: A modified `Item` with the tmpValue property set.
    public func tmpValue(_ tmpValue: Int) -> Self {
        assigning(.tmpValue, to: .int(tmpValue))
    }
}

// MARK: - Chaining modifiers (flag properties)

extension Item {
    /// The item is currently on fire or burning.
    public var isBurning: Self {
        assigning(.isBurning, to: true)
    }

    /// The item can be climbed by the player.
    public var isClimbable: Self {
        assigning(.isClimbable, to: true)
    }

    /// The item can contain other items.
    public var isContainer: Self {
        assigning(.isContainer, to: true)
    }

    /// The item is a device that can be turned on or off.
    public var isDevice: Self {
        assigning(.isDevice, to: true)
    }

    /// The item can be consumed as a liquid.
    public var isDrinkable: Self {
        assigning(.isDrinkable, to: true)
    }

    /// The item can be eaten by the player.
    public var isEdible: Self {
        assigning(.isEdible, to: true)
    }

    /// The item can catch fire and be destroyed by flames.
    public var isFlammable: Self {
        assigning(.isFlammable, to: true)
    }

    /// The item can be inflated with air or gas.
    public var isInflatable: Self {
        assigning(.isInflatable, to: true)
    }

    /// The item is currently in an inflated state.
    public var isInflated: Self {
        assigning(.isInflated, to: true)
    }

    /// The item is invisible and not normally described in rooms.
    public var isInvisible: Self {
        assigning(.isInvisible, to: true)
    }

    /// The item provides illumination when activated.
    public var isLightSource: Self {
        assigning(.isLightSource, to: true)
    }

    /// The item can be locked and unlocked with the appropriate key.
    public var isLockable: Self {
        assigning(.isLockable, to: true)
    }

    /// The item is currently in a locked state.
    public var isLocked: Self {
        assigning(.isLocked, to: true)
    }

    /// The item is currently switched on or activated.
    public var isOn: Self {
        assigning(.isOn, to: true)
    }

    /// The container is currently open, revealing its contents.
    public var isOpen: Self {
        assigning(.isOpen, to: true)
    }

    /// The item can be opened and closed by the player.
    public var isOpenable: Self {
        assigning(.isOpenable, to: true)
    }

    /// The item uses plural grammatical forms.
    public var isPlural: Self {
        assigning(.isPlural, to: true)
    }

    /// The item contains readable text content.
    public var isReadable: Self {
        assigning(.isReadable, to: true)
    }

    /// The item can be searched for hidden contents or details.
    public var isSearchable: Self {
        assigning(.isSearchable, to: true)
    }

    /// The item can ignite itself without requiring an external flame source.
    public var isSelfIgnitable: Self {
        assigning(.isSelfIgnitable, to: true)
    }

    /// Items can be placed on top of this object.
    public var isSurface: Self {
        assigning(.isSurface, to: true)
    }

    /// The item can be picked up and carried by the player.
    public var isTakable: Self {
        assigning(.isTakable, to: true)
    }

    /// The item is classified as a tool for game logic purposes.
    public var isTool: Self {
        assigning(.isTool, to: true)
    }

    /// The player has previously interacted with this item.
    public var isTouched: Self {
        assigning(.isTouched, to: true)
    }

    /// The container's contents are visible even when closed.
    public var isTransparent: Self {
        assigning(.isTransparent, to: true)
    }

    /// The item is a vehicle that can transport the player.
    public var isVehicle: Self {
        assigning(.isVehicle, to: true)
    }

    /// The item is a weapon that can be used in combat.
    public var isWeapon: Self {
        assigning(.isWeapon, to: true)
    }

    /// The item can be worn by the player.
    public var isWearable: Self {
        assigning(.isWearable, to: true)
    }

    /// The item is currently being worn by the player.
    public var isWorn: Self {
        assigning(.isWorn, to: true)
    }

    /// Suppress default articles in generated text.
    public var omitArticle: Self {
        assigning(.omitArticle, to: true)
    }

    /// Suppress automatic description in room content listings.
    public var omitDescription: Self {
        assigning(.omitDescription, to: true)
    }

    /// Requires special validation before the item can be taken.
    public var requiresTryTake: Self {
        assigning(.requiresTryTake, to: true)
    }
}

// MARK: - Helper method

extension Item {
    /// Creates a copy of this item with the specified property modified.
    ///
    /// - Parameters:
    ///   - id: The property ID to modify.
    ///   - rawValue: The new value for the property.
    /// - Returns: A new `Item` with the specified property updated.
    public func assigning(
        _ id: ItemPropertyID,
        to rawValue: StateValue
    ) -> Self {
        var copy = self
        copy.properties[id] = rawValue
        return copy
    }
}

// MARK: - RoughValue

extension Item {
    public enum RoughValue: Hashable {
        case worthless
        case low
        case medium
        case high
        case priceless
    }
}
