import Foundation

/// An immutable snapshot of a `Location`'s state at a specific point in time.
/// Used for safe data transfer from the GameEngine actor.
public struct LocationSnapshot: Identifiable, Sendable {
    // --- Properties (Alphabetical) ---

    // Note: actionHandlerID is not typically needed in snapshots for description generation.

    /// The main description handler for the location (`LDESC`).
    public let longDescription: DescriptionHandler?

    /// A dictionary mapping directions to exit definitions.
    public let exits: [Direction: Exit]

    /// IDs of "global" items associated with this location.
    public let globals: [ItemID]

    /// The unique identifier for this location.
    public let id: LocationID

    /// The display name of the location.
    public let name: String

    /// A set of properties defining the location's characteristics.
    public let properties: Set<LocationProperty>

    /// The short description handler for the location.
    public let shortDescription: DescriptionHandler?

    // --- Initialization ---

    /// Creates a snapshot from a `Location` object.
    /// - Parameter location: The `Location` to snapshot.
    init(location: Location) {
        self.id = location.id
        self.name = location.name
        self.longDescription = location.longDescription
        self.shortDescription = location.shortDescription
        self.exits = location.exits
        self.properties = location.properties
        self.globals = location.globals
    }

    // --- Convenience Accessors ---

    /// Checks if the location snapshot has a specific property.
    /// - Parameter property: The `LocationProperty` to check for.
    /// - Returns: `true` if the location has the property, `false` otherwise.
    public func hasProperty(_ property: LocationProperty) -> Bool {
        properties.contains(property)
    }
}
