import Foundation // Needed for Codable conformance for classes

/// A closure that dynamically generates a description string for a Location based on its state and the overall GameState.
public typealias LocationDescriptionHandler = @MainActor @Sendable (Location, GameState) async -> String?

/// Represents a distinct location within the game world.
public struct Location: Codable, Equatable, Identifiable, Sendable {

    // --- Stored Properties (Alphabetical) ---

    // Action handler - Placeholder.
    // public var actionHandlerID: String?

    /// Storage for state values that might have associated dynamic behavior (computation/validation)
    /// defined externally in the `DynamicPropertyRegistry`.
    public var dynamicValues: [PropertyID: StateValue]

    /// The main description of the location, shown upon entry or with `LOOK` (`LDESC`).
    /// Can be static text or dynamically generated.
    public var longDescription: DescriptionHandler?

    /// A dictionary mapping directions to exit definitions.
    public var exits: [Direction: Exit]

    /// IDs of "global" items associated with this location (like the rug in Cloak of Darkness).
    /// These are typically fixed scenery or items that aren't directly manipulated like normal items.
    public var globals: [ItemID]

    /// The unique identifier for this location. `let` because identity doesn't change.
    public let id: LocationID

    /// The display name of the location (e.g., "West of House").
    public var name: String

    /// A set of properties defining the location's characteristics (e.g., lit, outside).
    public var properties: Set<LocationProperty>

    /// The short description of the location, potentially used in specific contexts (e.g., brief summaries).
    /// Can be static text or dynamically generated.
    public var shortDescription: DescriptionHandler?

    // --- Initialization ---
    public init(
        id: LocationID,
        name: String,
        longDescription: DescriptionHandler? = nil,
        shortDescription: DescriptionHandler? = nil,
        exits: [Direction : Exit] = [:],
        properties: LocationProperty...,
        globals: ItemID...
        // actionHandlerID: String? = nil // Placeholder
    ) {
        self.id = id
        self.name = name
        self.longDescription = longDescription
        self.shortDescription = shortDescription
        self.exits = exits
        self.properties = Set(properties)
        self.globals = globals
        // self.actionHandlerID = actionHandlerID

        // Initialize dynamic values
        self.dynamicValues = [:] // Initialize as empty
    }

    // MARK: - Codable Conformance

    // Codable conformance will be synthesized (DescriptionHandler is Codable)

    // MARK: - Convenience Accessors

    /// Checks if the location has a specific property.
    /// - Parameter property: The `LocationProperty` to check for.
    /// - Returns: `true` if the location has the property, `false` otherwise.
    public func hasProperty(_ property: LocationProperty) -> Bool {
        properties.contains(property)
    }

    /// Adds a property to the location.
    /// - Parameter property: The `LocationProperty` to add.
    public mutating func addProperty(_ property: LocationProperty) {
        properties.insert(property)
    }

    /// Removes a property from the location.
    /// - Parameter property: The `LocationProperty` to remove.
    public mutating func removeProperty(_ property: LocationProperty) {
        properties.remove(property)
    }
}

// MARK: - Equatable Conformance (Manual)

// Equatable conformance will be synthesized (DescriptionHandler is Equatable)
