import Foundation

/// Represents an object that can contain other objects.
public struct ContainerComponent: Component {
    public static let type: ComponentType = .container

    /// Whether this container is currently open
    public var isOpen: Bool

    /// Whether this container is transparent (contents visible when closed)
    public var isTransparent: Bool

    /// The maximum number of items this container can hold, or nil for unlimited
    public var capacity: Int?

    /// The ID of the object that can lock/unlock this container, if applicable.
    public var keyID: Object.ID?

    public init(
        isOpen: Bool = true,
        isTransparent: Bool = false,
        capacity: Int? = nil,
        keyID: Object.ID? = nil
    ) {
        self.isOpen = isOpen
        self.isTransparent = isTransparent
        self.capacity = capacity
        self.keyID = keyID
    }
}
