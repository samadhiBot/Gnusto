import Foundation

/// A component that tracks an object's location in the world.
public struct LocationComponent: Component, Codable, Sendable {
    public static let type: ComponentType = .location

    /// The ID of the parent object (room or container) that contains this object.
    public var parentID: Object.ID?

    /// Creates a new location component.
    ///
    /// - Parameter parentID: The ID of the associated object's parent.
    public init(in parentID: Object.ID?) {
        self.parentID = parentID
    }
}

extension Object {
    /// Whether the object is directly inside a specified room or container.
    ///
    /// - Parameter parentID: The room or container's unique identifier.
    /// - Returns: Whether the object is directly inside the specified room or container.
    public func isDirectlyInside(_ parentID: Object.ID) -> Bool {
        if let locationComponent = find(LocationComponent.self) {
            locationComponent.parentID == parentID
        } else {
            false
        }
    }
    
    /// Returns the object's current location.
    public var location: Object.ID? {
        find(LocationComponent.self)?.parentID
    }
}
