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
    /// Use `PropertyID` constants (e.g., `.longDescription`) as keys.
    /// Values are typically `StateValue.string` for descriptions.
    public var dynamicValues: [PropertyID: StateValue]

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

    // --- Initialization ---
    public init(
        id: LocationID,
        name: String,
        longDescription: String? = nil,
        shortDescription: String? = nil,
        exits: [Direction : Exit] = [:],
        properties: LocationProperty...,
        globals: ItemID...
        // actionHandlerID: String? = nil // Placeholder
    ) {
        self.id = id
        self.name = name
        self.exits = exits
        self.properties = Set(properties)
        self.globals = globals
        // self.actionHandlerID = actionHandlerID

        // Initialize dynamic values
        var initialValues = [PropertyID: StateValue]()
        if let value = longDescription { initialValues[.longDescription] = .string(value) }
        if let value = shortDescription { initialValues[.shortDescription] = .string(value) }
        self.dynamicValues = initialValues
    }

    // MARK: - Codable Conformance

    private enum CodingKeys: String, CodingKey {
        case id, name, exits, properties, globals, dynamicValues
        // Note: Removed keys for old description properties
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(LocationID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        exits = try container.decode([Direction: Exit].self, forKey: .exits)
        properties = try container.decode(Set<LocationProperty>.self, forKey: .properties)
        globals = try container.decode([ItemID].self, forKey: .globals)
        dynamicValues = try container.decode([PropertyID: StateValue].self, forKey: .dynamicValues)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(exits, forKey: .exits)
        try container.encode(properties, forKey: .properties)
        try container.encode(globals, forKey: .globals)
        try container.encode(dynamicValues, forKey: .dynamicValues)
    }

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

// MARK: - Equatable Conformance

// Equatable conformance should still be synthesized correctly
