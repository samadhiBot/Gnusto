import Foundation

/// Represents an interactive object or entity within the game world, such as a brass lantern,
/// a rusty key, a treasure chest, or even a non-player character (NPC).
///
/// Each `Item` has a unique `id` (`ItemID`) and a collection of `attributes` that define its
/// current state, characteristics, and behaviors (e.g., its name, description, location,
/// whether it's openable, takable, etc.).
///
/// Game developers define items by providing an `ItemID` and a list of initial
/// `ItemAttribute`s. Many common attributes (like `name`, `parent`, `adjectives`)
/// have convenience computed properties for easy access and modification through the `GameEngine`.
/// The raw state of all attributes is stored in the `attributes` dictionary using `AttributeID` as keys.
///
/// Items are a fundamental part of the `GameState` and are manipulated by player commands
/// and game logic, often through `ActionHandler`s and `GameEngine` helper methods.
public struct Item: Codable, Identifiable, Sendable {
    /// The item's unique `ItemID`, serving as its primary key within the game.
    public let id: ItemID

    /// A dictionary holding the current state of all attributes for this item.
    ///
    /// Each key is an `AttributeID` (e.g., `.name`, `.description`, `.isLit`, `.itemParent`)
    /// and the value is a `StateValue` wrapper containing the actual typed data for that attribute.
    /// While direct access is possible, game logic typically interacts with these attributes
    /// via convenience accessors on `Item` (for reading) or through `GameEngine` methods
    /// (for modifications, which generate `StateChange`s).
    public var attributes: [AttributeID: StateValue]

    /// Creates a new `Item` instance with a given ID and initial attributes.
    ///
    /// The `attributes` parameter takes a variadic list of `ItemAttribute` instances.
    /// `ItemAttribute` is a helper enum that encapsulates both the `AttributeID` (the key)
    /// and the initial `StateValue` for an attribute.
    ///
    /// Example:
    /// ```swift
    /// let lantern = Item(
    ///     id: "brassLantern",
    ///     .name("brass lantern"),
    ///     .description("A tarnished brass lantern, surprisingly heavy."),
    ///     .synonyms(["lantern", "light"]),
    ///     .adjectives(["brass", "tarnished", "heavy"]),
    ///     .parent(.location("livingRoom")),
    ///     .setFlag(.isTakable),
    ///     .attribute(.size, .int(10))
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - id: The item's unique `ItemID`.
    ///   - attributes: A variadic list of `ItemAttribute`s defining the item's initial state.
    public init(
        id: ItemID,
        _ attributes: ItemAttribute...
    ) {
        self.id = id
        self.attributes = Dictionary(
            uniqueKeysWithValues: attributes.map { ($0.id, $0.rawValue) }
        )
    }

    // MARK: - Convenience Accessors

    /// A set of adjectives that can be used to describe or refer to the item (e.g., "brass",
    /// "small", "glowing"). These are typically used by the parser for disambiguation.
    /// Corresponds to the ZIL `ADJECTIVE` property.
    /// Defaults to an empty set if the `.adjectives` attribute is not set.
    public var adjectives: Set<String> {
        attributes[.adjectives]?.toStrings ?? []
    }

    /// The item's capacity, relevant if it's a container (i.e., has the `.isContainer` flag).
    /// It indicates how much "stuff" (sum of other items' `size`) it can hold.
    /// A capacity of -1 often means infinite capacity.
    /// Corresponds to the ZIL `CAPACITY` property.
    /// Defaults to `1000` if the `.capacity` attribute is not set (a large default).
    public var capacity: Int {
        attributes[.capacity]?.toInt ?? 1000
    }

    /// Checks if a specific boolean attribute (a flag) is set to `true` on this item.
    ///
    /// For example, `item.hasFlag(.isLit)` would return `true` if the `.isLit` attribute
    /// exists for this item and its value is `true`.
    ///
    /// - Parameter id: The `AttributeID` of the flag to check (e.g., `.isTakable`, `.isOpen`).
    /// - Returns: `true` if the flag attribute exists and is `true`, `false` otherwise.
    public func hasFlag(_ id: AttributeID) -> Bool {
        attributes[id] == true
    }

    /// The primary noun or noun phrase used to refer to the item (e.g., "brass lantern", "key").
    /// This is often displayed in room descriptions or inventory listings.
    /// Corresponds to the ZIL `DESC` property (often the short description).
    /// Defaults to the `id.rawValue` if the `.name` attribute is not set.
    public var name: String {
        attributes[.name]?.toString ?? id.rawValue
    }

    /// The `ParentEntity` that currently holds or contains this item. This determines the item's
    /// location in the game world (e.g., a specific `LocationID`, the `.player` inventory,
    /// or another `ItemID` if it's inside a container).
    /// Corresponds to the ZIL `IN` property.
    /// Defaults to `.nowhere` if the `.parentEntity` attribute is not set.
    public var parent: ParentEntity {
        attributes[.parentEntity]?.toParentEntity ?? .nowhere
    }

    /// The item's size or bulk, used for capacity calculations when placing it in containers
    /// or for determining if the player can carry it.
    /// Corresponds to the ZIL `SIZE` property.
    /// Defaults to `1` if the `.size` attribute is not set.
    public var size: Int {
        attributes[.size]?.toInt ?? 1
    }

    /// A set of alternative nouns or noun phrases that can be used to refer to the item.
    /// These are primarily used by the parser.
    /// Corresponds to the ZIL `SYNONYM` property.
    /// Defaults to an empty set if the `.synonyms` attribute is not set.
    public var synonyms: Set<String> {
        attributes[.synonyms]?.toStrings ?? []
    }
}

// MARK: - Comparable conformance

extension Item: Comparable {
    public static func < (lhs: Item, rhs: Item) -> Bool {
        lhs.id < rhs.id
    }
}
