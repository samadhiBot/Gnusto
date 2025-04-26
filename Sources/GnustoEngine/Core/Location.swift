import Foundation // Needed for Codable conformance for classes

/// Represents a distinct location within the game world. Modeled as a class for reference semantics.
public final class Location: Codable, Identifiable {

    // --- Stored Properties (Alphabetical) ---

    // Action handler - Placeholder.
    // public var actionHandlerID: String?

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
    }

    // --- Codable Conformance ---
    // Classes require explicit implementation

    enum CodingKeys: String, CodingKey {
        case longDescription
        case exits
        case globals
        case id
        case name
        case properties
        case shortDescription // Added
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Decode as DescriptionHandler?
        longDescription = try container.decodeIfPresent(DescriptionHandler.self, forKey: .longDescription)
        exits = try container.decode([Direction: Exit].self, forKey: .exits)
        globals = try container.decode([ItemID].self, forKey: .globals)
        id = try container.decode(LocationID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        properties = try container.decode(Set<LocationProperty>.self, forKey: .properties)
        // Decode as DescriptionHandler?
        shortDescription = try container.decodeIfPresent(DescriptionHandler.self, forKey: .shortDescription)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // Encode as DescriptionHandler?
        try container.encodeIfPresent(longDescription, forKey: .longDescription)
        try container.encode(exits, forKey: .exits)
        try container.encode(globals, forKey: .globals)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(properties, forKey: .properties)
        // Encode as DescriptionHandler?
        try container.encodeIfPresent(shortDescription, forKey: .shortDescription)
    }

    // --- Convenience Accessors ---

    /// Checks if the location has a specific property.
    /// - Parameter property: The `LocationProperty` to check for.
    /// - Returns: `true` if the location has the property, `false` otherwise.
    public func hasProperty(_ property: LocationProperty) -> Bool {
        properties.contains(property)
    }

    /// Adds a property to the location.
    /// - Parameter property: The `LocationProperty` to add.
    public func addProperty(_ property: LocationProperty) {
        properties.insert(property)
    }

    /// Removes a property from the location.
    /// - Parameter property: The `LocationProperty` to remove.
    public func removeProperty(_ property: LocationProperty) {
        properties.remove(property)
    }
}
