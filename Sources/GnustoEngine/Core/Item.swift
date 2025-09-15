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

    /// Checks whether the item has a specific boolean flag property set to `true`.
    ///
    /// This is a convenience method for testing boolean properties on items. If the property
    /// exists and has a value of `.bool(true)`, this method returns `true`. If the property
    /// doesn't exist or has any other value (including `.bool(false)`), it returns `false`.
    ///
    /// Common use cases include checking flags like `.isTakable`, `.isOpenable`, `.isOn`, etc.
    ///
    /// > Important: This should *only* be used in an `ItemComputer` or `LocationComputer` context,
    /// when an `ItemProxy` is not available. This returns a static `GameState` value, and bypasses
    /// any dynamic property calculation.
    ///
    /// - Parameter itemPropertyID: The `ItemPropertyID` of the boolean flag to check.
    /// - Returns: `true` if the property exists and is set to `.bool(true)`, `false` otherwise.
    public func hasFlag(_ itemPropertyID: ItemPropertyID) -> Bool {
        if let value = properties[itemPropertyID] {
            value == .bool(true)
        } else {
            false
        }
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
    public func proxy(_ engine: GameEngine) async throws -> ItemProxy {
        try await engine.item(id)
    }
}

// MARK: - Comparable conformance

extension Item: Comparable {
    public static func < (lhs: Item, rhs: Item) -> Bool {
        lhs.id < rhs.id
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
