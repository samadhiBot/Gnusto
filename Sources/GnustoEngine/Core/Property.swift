import Foundation

/// Represents a property of a game object.
public protocol Property: Codable, Equatable, Identifiable, Sendable {
    var rawValue: StateValue { get }
}
