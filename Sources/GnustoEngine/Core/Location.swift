import Foundation

/// Represents a distinct place or room within the game world that the player can visit.
///
/// Each `Location` has a unique `id` (`LocationID`) and a collection of `attributes` that
/// define its current state and characteristics (e.g., its name, description, exits to
/// other locations, and whether it's lit).
///
/// Game developers define locations by providing a `LocationID` and a list of initial
/// `LocationAttribute`s. Common attributes (like `name`, `description`, `exits`)
/// have convenience computed properties for easy access. The raw state of all attributes
/// is stored in the `attributes` dictionary using `AttributeID` as keys.
///
/// Locations are a fundamental part of the `GameState` and form the map through which
/// the player navigates.
public struct Location: Codable, Identifiable, Equatable, Sendable {
    /// The location's unique `LocationID`, serving as its primary key within the game.
    public let id: LocationID

    /// A dictionary holding the current state of all attributes for this location.
    ///
    /// Each key is an `AttributeID` (e.g., `.name`, `.description`, `.isLit`, `.exits`)
    /// and the value is a `StateValue` wrapper containing the actual typed data for that attribute.
    /// Game logic typically interacts with these attributes via convenience accessors on `Location`
    /// (for reading) or through `GameEngine` methods (for modifications).
    public var attributes: [AttributeID: StateValue]

    // MARK: - Initializer

    /// Creates a new `Location` instance with a given ID and initial attributes.
    ///
    /// The `attributes` parameter takes a variadic list of `LocationAttribute` instances.
    /// `LocationAttribute` is a helper enum that encapsulates both the `AttributeID` (the key)
    /// and the initial `StateValue` for an attribute.
    ///
    /// Example:
    /// ```swift
    /// let livingRoom = Location(
    ///     id: "livingRoom",
    ///     .name("Living Room"),
    ///     .description("A comfortably furnished living room. There are exits to the north and east."),
    ///     .exits([.north: .to("garden"), .east: .to("kitchen")]),
    ///     .setFlag(.isLit) // e.g., if lit by default
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - id: The location's unique `LocationID`.
    ///   - attributes: A variadic list of `LocationAttribute`s defining the location's initial state.
    public init(
        id: LocationID,
        _ attributes: LocationAttribute...
    ) {
        self.id = id
        self.attributes = Dictionary(
            uniqueKeysWithValues: attributes.map { ($0.id, $0.rawValue) }
        )
    }

    // MARK: - Convenience Accessors

    /// A dictionary defining the exits from this location, mapping a `Direction` to an `Exit` object.
    /// The `Exit` object contains the `LocationID` of the destination and potentially other
    /// properties like conditions for using the exit or custom messages.
    /// Defaults to an empty dictionary if the `.exits` attribute is not set.
    public var exits: [Direction: Exit] {
        attributes[.exits]?.toLocationExits ?? [:]
    }

    /// Checks if a specific boolean attribute (a flag) is set to `true` on this location.
    ///
    /// For example, `location.hasFlag(.isLit)` would return `true` if the `.isLit` attribute
    /// exists for this location and its value is `true`.
    ///
    /// - Parameter id: The `AttributeID` of the flag to check (e.g., `.isLit`, `.isVisited`).
    /// - Returns: `true` if the flag attribute exists and is `true`, `false` otherwise.
    public func hasFlag(_ id: AttributeID) -> Bool {
        attributes[id] == true
    }

    /// Checks whether the location is inherently lit (e.g., an outdoor location during the day)
    /// based on the `.inherentlyLit` attribute.
    ///
    /// This does not consider light from items (like a lantern). The `GameEngine` typically combines
    /// this with checks for lit items in scope to determine if the player can see.
    /// Defaults to `false` if the `.inherentlyLit` attribute is not set.
    ///
    /// - Returns: `true` if the location is inherently lit, `false` otherwise.
    public func isInherentlyLit() -> Bool {
        attributes[.inherentlyLit]?.toBool ?? false
    }

    /// A set of `ItemID`s for items that are considered "globally" present or relevant to this
    /// location, even if not physically located within it according to their `parent` attribute.
    /// This is similar to ZIL's `GLOBAL` objects that could be scoped to rooms.
    ///
    /// Examples include a distant mountain visible from a clearing, the sky, or an omnipresent narrator.
    /// Items in `localGlobals` are typically considered in scope for parsing and actions.
    /// Defaults to an empty set if the `.localGlobals` attribute is not set.
    public var localGlobals: Set<ItemID> {
        attributes[.localGlobals]?.toItemIDs ?? []
    }

    /// The display name of the location (e.g., "West of House", "Forest Path").
    /// This is typically shown in the status line and as the heading for room descriptions.
    /// Corresponds to the ZIL `DESC` or room name property.
    /// Defaults to the `id.rawValue` if the `.name` attribute is not set.
    public var name: String {
        attributes[.name]?.toString ?? id.rawValue
    }
}
