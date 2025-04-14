import Foundation
// No import Gnusto needed if Component/ComponentType are top-level

/// Represents an object that can be read.
public struct ReadableComponent: Component, Codable, Sendable {
    /// The unique identifier for this component type.
    public static let type: ComponentType = .custom("readable") // Use ComponentType

    /// The text content of the object.
    public var text: String

    /// Whether the object has been read by the player.
    public var hasBeenRead: Bool = false

    /// If true, `hasBeenRead` will be set to true automatically when the `ReadHandler` processes this.
    public var markAsReadOnRead: Bool = true

    /// Initializes a new readable component.
    ///
    /// - Parameters:
    ///   - text: The text content.
    ///   - hasBeenRead: Initial read status (defaults to false).
    ///   - markAsReadOnRead: Whether to automatically mark as read (defaults to true).
    public init(
        text: String,
        hasBeenRead: Bool = false,
        markAsReadOnRead: Bool = true
    ) {
        self.text = text
        self.hasBeenRead = hasBeenRead
        self.markAsReadOnRead = markAsReadOnRead
    }
}
