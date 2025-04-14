import Foundation

/// A Sendable, immutable snapshot of a Location's state at a specific moment.
/// Used for safe data transfer from the GameEngine actor.
public struct LocationSnapshot: Identifiable, Sendable {
    // --- Properties (Copy relevant ones from Location) ---
    public let id: LocationID
    public let name: String
    public let description: String
    public let exits: [Direction: Exit] // Exit itself is Sendable
    public let properties: Set<LocationProperty> // LocationProperty is Sendable
    public let globals: [ItemID] // ItemID is Sendable
    // Note: We don't copy items here; get item snapshots separately via engine

    // --- Initialization ---
    /// Creates a snapshot from a Location instance.
    /// Must be called within the actor context managing the Location.
    init(location: Location) {
        self.id = location.id
        self.name = location.name
        self.description = location.description
        self.exits = location.exits
        self.properties = location.properties
        self.globals = location.globals
    }
}
