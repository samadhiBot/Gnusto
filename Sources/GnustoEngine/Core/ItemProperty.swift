import Foundation

// swiftlint:disable file_length

/// Represents a property of an `Item`, providing both descriptive attributes and behavioral flags.
///
/// `ItemProperty` serves as the foundation for defining item characteristics in the Gnusto engine.
/// Properties can be either value-based (strings, integers, complex types) or boolean flags that
/// control item behavior and interactions.
///
/// ## Usage
/// Properties are typically applied when creating items using a fluent syntax:
/// ```swift
/// let lamp = Item(
///     id: "lamp",
///     .name("brass lamp"),
///     .description("A shiny brass lamp with intricate engravings."),
///     .isTakable,
///     .isLightSource,
///     .isDevice
/// )
/// ```
///
/// ## ZIL Heritage
/// Many properties correspond to classic ZIL (Zork Implementation Language) flags and attributes,
/// maintaining compatibility with traditional interactive fiction conventions while providing
/// modern Swift expressiveness.
public struct ItemProperty: Property {
    public let id: ItemPropertyID
    public let rawValue: StateValue

    public init(
        id: ItemPropertyID,
        rawValue: StateValue
    ) {
        self.id = id
        self.rawValue = rawValue
    }
}

// MARK: - Value Properties

/// Properties that store descriptive or numeric values rather than simple boolean flags.
extension ItemProperty {
    /// Adjectives associated with an item, used for disambiguation and natural language parsing.
    ///
    /// These descriptive words help the parser distinguish between similar items when the player
    /// uses specific adjectives in commands. For example, "take brass lamp" vs "take rusty lamp".
    ///
    /// ## Usage
    /// ```swift
    /// .adjectives("brass", "shiny", "ornate")
    /// ```
    ///
    /// - Parameter adjectives: Descriptive adjectives that can be used to refer to this item.
    /// - Returns: An .adjectives property containing the specified adjectives.
    public static func adjectives(_ adjectives: String...) -> ItemProperty {
        ItemProperty(
            id: .adjectives,
            rawValue: .stringSet(Set(adjectives))
        )
    }

    /// Character-specific attributes for NPCs and actors.
    ///
    /// Defines behavioral and statistical properties for characters, including personality traits,
    /// dialogue preferences, and social interactions.
    ///
    /// - Parameter sheet: The character's behavioral and social attributes.
    /// - Returns: A .characterSheet property.
    public static func characterSheet(_ sheet: CharacterSheet) -> ItemProperty {
        ItemProperty(
            id: .characterSheet,
            rawValue: .characterSheet(sheet)
        )
    }

    /// The carrying capacity of a container item, measured in size units.
    ///
    /// Determines how many items (by total size) can fit inside this container. Only meaningful
    /// for items with the `.isContainer` flag. Items attempting to exceed this capacity will
    /// be rejected by the container logic.
    ///
    /// ## Usage
    /// ```swift
    /// .capacity(10)  // Can hold items totaling 10 size units
    /// ```
    ///
    /// - Parameter capacity: Maximum size units this container can hold.
    /// - Returns: A .capacity property.
    public static func capacity(_ capacity: Int) -> ItemProperty {
        ItemProperty(
            id: .capacity,
            rawValue: .int(capacity)
        )
    }

    /// The maximum damage this item can inflict when used as a weapon.
    ///
    /// Used by the combat system to calculate attack damage. Higher values indicate more
    /// dangerous weapons. Typically combined with `.isWeapon` flag for proper recognition
    /// by combat handlers.
    ///
    /// ## Usage
    /// ```swift
    /// .damage(15)  // Sword deals up to 15 damage
    /// .damage(3)   // Dagger deals up to 3 damage
    /// ```
    ///
    /// - Parameter damage: Maximum damage points this weapon can inflict.
    /// - Returns: A .damage property.
    public static func damage(_ damage: Int) -> ItemProperty {
        ItemProperty(
            id: .damage,
            rawValue: .int(damage)
        )
    }

    /// The item's primary, detailed description shown when examining it (ZIL `LDESC`).
    ///
    /// This is the main descriptive text displayed when the player examines an item closely.
    /// Should be rich and evocative, providing important details about the item's appearance,
    /// condition, and notable features.
    ///
    /// ## Usage
    /// ```swift
    /// .description("A brass lamp with intricate Celtic knotwork etched into its surface.")
    /// ```
    ///
    /// - Parameter description: The detailed examination text for this item.
    /// - Returns: A .description property.
    public static func description(_ description: String) -> ItemProperty {
        ItemProperty(
            id: .description,
            rawValue: .string(description)
        )
    }

    /// The description shown the first time an item is encountered in a location (ZIL `FDESC`).
    ///
    /// Used to provide a more detailed or dramatic introduction when the item first appears
    /// in room descriptions. After the first encounter, subsequent room descriptions typically
    /// use shorter, more mundane text.
    ///
    /// ## Usage
    /// ```swift
    /// .firstDescription("A magnificent brass lamp sits majestically on the marble pedestal.")
    /// ```
    ///
    /// - Parameter description: The initial encounter description for this item.
    /// - Returns: A .firstDescription property.
    public static func firstDescription(_ description: String) -> ItemProperty {
        ItemProperty(
            id: .firstDescription,
            rawValue: .string(description)
        )
    }

    /// The item's current parent entity - where it's currently located (ZIL `IN`).
    ///
    /// Specifies whether the item is in a location, held by the player, contained within
    /// another item, or worn by the player. This fundamental property determines the item's
    /// accessibility and interaction possibilities.
    ///
    /// ## Usage
    /// ```swift
    /// .in(.library)          // Item is in the library location
    /// .in(.player)           // Item is carried by the player
    /// .in(.item(.backpack))  // Item is inside the backpack
    /// ```
    ///
    /// - Parameter parent: Where this item is currently located.
    /// - Returns: A .parentEntity property.
    public static func `in`(_ parent: ParentEntity) -> ItemProperty {
        ItemProperty(
            id: .parentEntity,
            rawValue: .parentEntity(parent)
        )
    }

    /// Convenience method for placing an item directly in a location.
    ///
    /// A shorthand for `.in(.location(locationID))` that simplifies the common case
    /// of placing items in specific locations during initialization.
    ///
    /// ## Usage
    /// ```swift
    /// .in(.library)  // Item starts in the library location
    /// ```
    ///
    /// - Parameter locationID: The location where this item should be placed.
    /// - Returns: A .parentEntity property with the location as parent.
    public static func `in`(_ locationID: LocationID) -> ItemProperty {
        ItemProperty(
            id: .parentEntity,
            rawValue: .parentEntity(.location(locationID))
        )
    }

    /// The specific key item needed to lock or unlock this item.
    ///
    /// Only meaningful for items with the `.isLockable` flag. Specifies which key item
    /// the player must possess and use to operate this lock. The lock/unlock actions
    /// will verify the player has this specific key before allowing the operation.
    ///
    /// ## Usage
    /// ```swift
    /// .lockKey(.brassDoorKey)  // Requires the brass door key to operate
    /// ```
    ///
    /// - Parameter lockKey: The ItemID of the key required to operate this lock.
    /// - Returns: A .lockKey property.
    public static func lockKey(_ lockKey: ItemID) -> ItemProperty {
        ItemProperty(
            id: .lockKey,
            rawValue: .itemID(lockKey)
        )
    }

    /// Restricts which locations this item can exist in.
    ///
    /// Used for items that should only appear in specific locations due to game logic,
    /// physics, or narrative constraints. The engine can use this to prevent inappropriate
    /// item placement through teleportation or other means.
    ///
    /// ## Usage
    /// ```swift
    /// .validLocations(.underwater, .submarineInterior)  // Diving gear only works underwater
    /// ```
    ///
    /// - Parameter locations: LocationIDs where this item is allowed to exist.
    /// - Returns: A .validLocations property.
    public static func validLocations(_ locations: LocationID...) -> ItemProperty {
        ItemProperty(
            id: .validLocations,
            rawValue: .locationIDSet(Set(locations))
        )
    }

    /// The primary name used to refer to the item in game text (ZIL `DESC`).
    ///
    /// This is the canonical name displayed in room descriptions, inventory lists,
    /// and most game messages. Should be concise but descriptive enough for identification.
    /// Usually includes articles ("a brass lamp", "the ancient scroll").
    ///
    /// ## Usage
    /// ```swift
    /// .name("brass lamp")
    /// .name("the Crown Jewels")  // Unique items often include "the"
    /// ```
    ///
    /// - Parameter name: The primary display name for this item.
    /// - Returns: A .name property.
    public static func name(_ name: String) -> ItemProperty {
        ItemProperty(
            id: .name,
            rawValue: .string(name)
        )
    }

    /// Text content that can be read from this item (ZIL `RTEXT/TEXT`).
    ///
    /// Displayed when the player reads this item using commands like "read book" or
    /// "read inscription". Only meaningful for items with the `.isReadable` flag.
    /// Can contain important clues, story information, or flavor text.
    ///
    /// ## Usage
    /// ```swift
    /// .readText("Welcome to Zork! Your adventure begins now...")
    /// .readText("The ancient runes seem to shift before your eyes, revealing...")
    /// ```
    ///
    /// - Parameter text: The readable content of this item.
    /// - Returns: A .readText property.
    public static func readText(_ text: String) -> ItemProperty {
        ItemProperty(
            id: .readText,
            rawValue: .string(text)
        )
    }

    /// Alternative text displayed when reading this item while holding it (ZILF `TEXT-HELD`).
    ///
    /// Some items reveal different or additional information when examined closely
    /// in hand versus from a distance. This allows for more detailed inspection text
    /// that's only available when the item is in the player's possession.
    ///
    /// ## Usage
    /// ```swift
    /// .readWhileHeldText("Holding the scroll closer to the light, you can make out faded...")
    /// ```
    ///
    /// - Parameter text: The enhanced readable content available when holding this item.
    /// - Returns: A .readWhileHeldText property.
    public static func readWhileHeldText(_ text: String) -> ItemProperty {
        ItemProperty(
            id: .readWhileHeldText,
            rawValue: .string(text)
        )
    }

    /// A shorter description used in inventory lists and brief mentions (ZIL `SDESC`).
    ///
    /// Provides a more concise alternative to the main description for contexts where
    /// brevity is important, such as inventory listings or room contents in brief mode.
    /// Should still be clear but more economical with words.
    ///
    /// ## Usage
    /// ```swift
    /// .shortDescription("brass lamp")  // vs longer main description
    /// ```
    ///
    /// - Parameter description: A brief description of this item.
    /// - Returns: A .shortDescription property.
    public static func shortDescription(_ description: String) -> ItemProperty {
        ItemProperty(
            id: .shortDescription,
            rawValue: .string(description)
        )
    }

    /// The item's size in abstract units, affecting inventory and container management.
    ///
    /// Determines how much space this item occupies when carried or stored in containers.
    /// Items with larger sizes are harder to carry in quantity and take up more container
    /// capacity. Used by the engine to enforce realistic carrying limitations.
    ///
    /// ## Usage
    /// ```swift
    /// .size(1)   // Small items like coins or keys
    /// .size(5)   // Medium items like books or tools
    /// .size(20)  // Large items like furniture or armor
    /// ```
    ///
    /// - Parameter size: The size units this item occupies.
    /// - Returns: A .size property.
    public static func size(_ size: Int) -> ItemProperty {
        ItemProperty(
            id: .size,
            rawValue: .int(size)
        )
    }

    /// Alternative names the player can use to refer to this item in commands.
    ///
    /// Expands the vocabulary for interacting with items, allowing natural language
    /// variations. The parser will recognize any of these synonyms as referring to this item.
    /// Essential for intuitive gameplay and reducing player frustration.
    ///
    /// ## Usage
    /// ```swift
    /// .synonyms("lamp", "light", "lantern")  // All refer to the same lamp
    /// .synonyms("book", "tome", "manual", "volume")
    /// ```
    ///
    /// - Parameter synonyms: Alternative names players can use for this item.
    /// - Returns: A .synonyms property.
    public static func synonyms(_ synonyms: String...) -> ItemProperty {
        ItemProperty(
            id: .synonyms,
            rawValue: .stringSet(Set(synonyms))
        )
    }

    /// The item's inherent value, typically monetary worth or game score contribution.
    ///
    /// Used for treasures, trading systems, or score calculation. Represents the item's
    /// fixed, intrinsic worth that doesn't change during gameplay. For values that need
    /// to change at runtime, use `tmpValue` instead.
    ///
    /// ## Usage
    /// ```swift
    /// .value(100)  // A valuable gem worth 100 points
    /// .value(25)   // A silver coin worth 25 zorkmids
    /// ```
    ///
    /// - Parameter value: The item's inherent worth or point value.
    /// - Returns: A .value property.
    public static func value(_ value: Int) -> ItemProperty {
        ItemProperty(
            id: .value,
            rawValue: .int(value)
        )
    }

    /// A mutable value that can change during gameplay for dynamic item properties.
    ///
    /// Unlike the static `value` property, `tmpValue` is designed to be modified at runtime
    /// for items whose worth, power, or other numeric attributes change based on game events,
    /// player actions, or story progression.
    ///
    /// ## Usage
    /// ```swift
    /// .tmpValue(50)  // Starting value that might increase or decrease
    /// ```
    ///
    /// - Parameter tmpValue: The initial temporary value for this item.
    /// - Returns: A .tmpValue property.
    public static func tmpValue(_ tmpValue: Int) -> ItemProperty {
        ItemProperty(
            id: .tmpValue,
            rawValue: .int(tmpValue)
        )
    }
}

// MARK: - Flag Properties

/// Boolean properties that control item behavior and game mechanics.
/// Most correspond to classic ZIL flags, maintaining compatibility with traditional IF conventions.
extension ItemProperty {
    /// The item is currently on fire or burning (ZIL `FLAMEBIT`).
    ///
    /// Indicates active combustion. Items with this flag may spread fire to flammable
    /// objects, provide light, cause damage when touched, or be extinguished by water.
    public static var isBurning: ItemProperty {
        ItemProperty(id: .isBurning, rawValue: true)
    }

    /// The item can be climbed by the player (ZIL `CLIMBBIT`).
    ///
    /// Allows the "climb" action to succeed with this item. Typically used for
    /// trees, ladders, stairs, or other vertical structures that enable movement
    /// or provide access to new areas.
    public static var isClimbable: ItemProperty {
        ItemProperty(id: .isClimbable, rawValue: true)
    }

    /// The item can contain other items (ZIL `CONTBIT`).
    ///
    /// Enables container functionality, allowing other items to be placed inside.
    /// Should be combined with `capacity()` to set storage limits. Items inside
    /// containers may be hidden from room descriptions unless the container is open.
    public static var isContainer: ItemProperty {
        ItemProperty(id: .isContainer, rawValue: true)
    }

    /// The item is a device that can be turned on or off (ZILF `DEVICEBIT`).
    ///
    /// **Critical for light sources!** Required for `TurnOnActionHandler` to work properly.
    /// Enables "turn on" and "turn off" commands. Combine with `isLightSource` for
    /// lamps, torches, and other illumination devices.
    public static var isDevice: ItemProperty {
        ItemProperty(id: .isDevice, rawValue: true)
    }

    /// The item can be consumed as a liquid (ZIL `DRINKBIT`).
    ///
    /// Allows the "drink" action to succeed. Used for potions, beverages, water sources,
    /// and other liquid consumables. May trigger special effects or state changes when consumed.
    public static var isDrinkable: ItemProperty {
        ItemProperty(id: .isDrinkable, rawValue: true)
    }

    /// The item can be eaten by the player (ZIL `EDIBLEBIT`/`FOODBIT`).
    ///
    /// Enables the "eat" action for food items. May provide nourishment, trigger
    /// magical effects, or advance the story when consumed. Often causes the item
    /// to be removed from the game world.
    public static var isEdible: ItemProperty {
        ItemProperty(id: .isEdible, rawValue: true)
    }

    /// The item can be equipped by the player for combat or special abilities.
    ///
    /// Allows weapons, armor, shields, and magical items to be equipped for enhanced
    /// combat effectiveness or special powers. Equipped items typically modify the
    /// player's capabilities or provide ongoing benefits.

    /// The item can catch fire and be destroyed by flames (ZIL `BURNBIT`).
    ///
    /// Makes the item vulnerable to fire sources. Flammable items may ignite when
    /// exposed to flames, torches, or other burning objects, potentially being
    /// consumed in the process. Wood, paper, and cloth are typically flammable.
    public static var isFlammable: ItemProperty {
        ItemProperty(id: .isFlammable, rawValue: true)
    }

    /// The item can be inflated with air or gas.
    ///
    /// Enables inflation mechanics for balloons, rafts, flotation devices, and similar
    /// objects. Usually changes the item's properties when inflated, such as making
    /// a collapsed raft seaworthy or a deflated balloon buoyant.
    public static var isInflatable: ItemProperty {
        ItemProperty(id: .isInflatable, rawValue: true)
    }

    /// The item is currently in an inflated state.
    ///
    /// Indicates that an inflatable item has been filled with air or gas and is
    /// ready for use. An inflated raft might float, while an inflated balloon
    /// might provide lift or entertainment value.
    public static var isInflated: ItemProperty {
        ItemProperty(id: .isInflated, rawValue: true)
    }

    /// The item is invisible and not normally described in rooms (ZIL `INVISIBLE`).
    ///
    /// Hides the item from standard room descriptions and inventory lists. Invisible
    /// items can still be interacted with if the player knows their name, enabling
    /// hidden objects and secret mechanisms.
    public static var isInvisible: ItemProperty {
        ItemProperty(id: .isInvisible, rawValue: true)
    }

    /// The item functions as a key for locking and unlocking mechanisms.
    ///
    /// Enables this item to operate locks when used with the "unlock" or "lock"
    /// commands. The key must match the `lockKey` property of the target item
    /// for the operation to succeed.

    /// The item provides illumination when activated (ZIL `LIGHTBIT`).
    ///
    /// Light sources can illuminate dark areas, revealing hidden details and enabling
    /// normal interaction. **Must be combined with `isDevice`** for proper turn-on/off
    /// functionality. Battery life and fuel consumption may apply.
    public static var isLightSource: ItemProperty {
        ItemProperty(id: .isLightSource, rawValue: true)
    }

    /// The item can be locked and unlocked with the appropriate key (ZIL `LOCKBIT`).
    ///
    /// Enables locking mechanisms that prevent access or operation until unlocked.
    /// Must specify a `lockKey` property indicating which key item operates this lock.
    /// Commonly used for doors, containers, and secured devices.
    public static var isLockable: ItemProperty {
        ItemProperty(id: .isLockable, rawValue: true)
    }

    /// The item is currently in a locked state (ZIL `LOCKED`).
    ///
    /// Prevents certain actions until unlocked with the appropriate key. Locked
    /// containers cannot be opened, locked doors cannot be passed through, and
    /// locked devices cannot be operated.
    public static var isLocked: ItemProperty {
        ItemProperty(id: .isLocked, rawValue: true)
    }

    /// The item is currently switched on or activated (ZIL `ONBIT`).
    ///
    /// Indicates the active state for devices, light sources, and other switchable
    /// items. Light sources only provide illumination when on, and other devices
    /// may only function in their active state.
    public static var isOn: ItemProperty {
        ItemProperty(id: .isOn, rawValue: true)
    }

    /// The container is currently open, revealing its contents (ZIL `OPENBIT`).
    ///
    /// Open containers display their contents in room descriptions and allow items
    /// to be inserted or removed. Closed containers hide their contents unless
    /// they also have the `isTransparent` flag.
    public static var isOpen: ItemProperty {
        ItemProperty(id: .isOpen, rawValue: true)
    }

    /// The item can be opened and closed by the player (ZIL `OPENABLEBIT`).
    ///
    /// Enables "open" and "close" commands for containers, doors, and other
    /// openable objects. Items without this flag cannot be opened, even if
    /// they appear to be containers.
    public static var isOpenable: ItemProperty {
        ItemProperty(id: .isOpenable, rawValue: true)
    }

    /// The item uses plural grammatical forms (ZIL `PLURALBIT`).
    ///
    /// Affects verb agreement and article usage in generated text. Important for
    /// items that represent multiple objects ("coins", "keys") or inherently plural
    /// concepts ("scissors", "pants").
    public static var isPlural: ItemProperty {
        ItemProperty(id: .isPlural, rawValue: true)
    }

    /// The item contains readable text content (ZIL `READBIT`).
    ///
    /// Enables the "read" action and indicates the item has `readText` or
    /// `readWhileHeldText` properties. Used for books, signs, inscriptions,
    /// and any object with written information.
    public static var isReadable: ItemProperty {
        ItemProperty(id: .isReadable, rawValue: true)
    }

    /// The item can be searched for hidden contents or details (ZIL `SEARCHBIT`).
    ///
    /// Allows the "search" action to reveal hidden compartments, concealed items,
    /// or secret information. Searching may uncover clues, treasures, or
    /// mechanisms not visible through normal examination.
    public static var isSearchable: ItemProperty {
        ItemProperty(id: .isSearchable, rawValue: true)
    }

    /// The item can ignite itself without requiring an external flame source.
    ///
    /// Items with this flag can start fires through internal mechanisms - magical
    /// properties, chemical reactions, or built-in ignition systems. Unlike regular
    /// flammable items, these don't need matches or torches to catch fire.
    public static var isSelfIgnitable: ItemProperty {
        ItemProperty(id: .isSelfIgnitable, rawValue: true)
    }

    /// Items can be placed on top of this object (ZIL `SURFACEBIT`).
    ///
    /// Creates a surface that can support other items, like tables, desks, altars,
    /// or pedestals. Items placed on surfaces remain visible and accessible while
    /// being physically supported by the surface object.
    public static var isSurface: ItemProperty {
        ItemProperty(id: .isSurface, rawValue: true)
    }

    /// The item can be picked up and carried by the player (ZIL `TAKEBIT`).
    ///
    /// **Essential for portable items!** Without this flag, the player cannot
    /// take the item into inventory. Most tools, treasures, and interactive
    /// objects need this property for proper gameplay.
    public static var isTakable: ItemProperty {
        ItemProperty(id: .isTakable, rawValue: true)
    }

    /// The item is classified as a tool for game logic purposes (ZIL `TOOLBIT`).
    ///
    /// Marks items that serve utilitarian functions rather than being mere
    /// treasures or decorations. May affect puzzle-solving mechanics, crafting
    /// systems, or tool-specific interactions.
    public static var isTool: ItemProperty {
        ItemProperty(id: .isTool, rawValue: true)
    }

    /// The player has previously interacted with this item (ZIL `TOUCHBIT`).
    ///
    /// Tracks whether the player has examined, touched, or otherwise interacted
    /// with the item. Used to modify descriptions in brief mode, where touched
    /// items may receive shorter descriptions on subsequent encounters.
    public static var isTouched: ItemProperty {
        ItemProperty(id: .isTouched, rawValue: true)
    }

    /// The container's contents are visible even when closed (ZIL `TRANSBIT`).
    ///
    /// Transparent containers like glass boxes or crystal spheres reveal their
    /// contents regardless of their open/closed state. Players can see what's
    /// inside but may still need to open the container to access items.
    public static var isTransparent: ItemProperty {
        ItemProperty(id: .isTransparent, rawValue: true)
    }

    /// The item is a vehicle that can transport the player (ZIL `VEHBIT`).
    ///
    /// Enables transportation mechanics for boats, cars, flying carpets, and other
    /// conveyances. Vehicles may have special movement rules and can carry the
    /// player between locations with different travel mechanics than walking.
    public static var isVehicle: ItemProperty {
        ItemProperty(id: .isVehicle, rawValue: true)
    }

    /// The item is a weapon that can be used in combat (ZIL `WEAPONBIT`).
    ///
    /// Marks items that can be wielded for fighting. Weapons typically have
    /// `damage()` values and may be enhanced by combat attributes. Essential
    /// for items intended to participate in the combat system.
    public static var isWeapon: ItemProperty {
        ItemProperty(id: .isWeapon, rawValue: true)
    }

    /// The item can be worn by the player (ZIL `WEARBIT`).
    ///
    /// Enables "wear" and "remove" commands for clothing, jewelry, armor, and
    /// other wearable items. Worn items may provide protection, magical effects,
    /// or social status modifications while equipped on the player's body.
    public static var isWearable: ItemProperty {
        ItemProperty(id: .isWearable, rawValue: true)
    }

    /// The item is currently being worn by the player (ZIL `WORNBIT`).
    ///
    /// Indicates that a wearable item is actively equipped on the player's body.
    /// Worn items typically cannot be dropped until removed first, and may
    /// provide ongoing benefits or restrictions while worn.
    public static var isWorn: ItemProperty {
        ItemProperty(id: .isWorn, rawValue: true)
    }

    /// Suppress default articles in generated text (ZIL `NARTICLEBIT`).
    ///
    /// Prevents the engine from automatically adding "a", "an", or "the" before
    /// the item's name. Useful for proper nouns, unique items, or items whose
    /// names already include appropriate articles ("the Crown Jewels").
    public static var omitArticle: ItemProperty {
        ItemProperty(id: .omitArticle, rawValue: true)
    }

    /// Suppress automatic description in room content listings (ZIL `NDESCBIT`).
    ///
    /// Prevents the item from appearing in standard room descriptions. Useful
    /// for items that should be mentioned through custom location descriptions
    /// or special events rather than generic "You see X here" text.
    public static var omitDescription: ItemProperty {
        ItemProperty(id: .omitDescription, rawValue: true)
    }

    /// Requires special validation before the item can be taken (ZIL `TRYTAKEBIT`).
    ///
    /// Items with this flag trigger additional checks or custom handlers before
    /// being picked up. Used for items that need special conditions, warnings,
    /// or side effects when taken, such as cursed objects or dangerous materials.
    public static var requiresTryTake: ItemProperty {
        ItemProperty(id: .requiresTryTake, rawValue: true)
    }

    /// The item's name starts with a vowel sound for article selection (ZIL `VOWELBIT`).
    ///
    /// Helps the engine choose between "a" and "an" when generating text.
    /// Items starting with vowel sounds ("apple", "elegant dress") should have
    /// this flag to ensure proper grammatical article usage.

}

// swiftlint:enable file_length
