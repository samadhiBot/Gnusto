import Foundation

/// Defines the base protocol for all components.
public protocol Component: Sendable {
    /// The type identifier for this component.
    static var type: ComponentType { get }
}

// MARK: - ComponentType

/// A unique identifier for component types.
public enum ComponentType: Hashable, Sendable {
    case container
    case description
    case globalState
    case lightSource
    case location
    case object
    case player
    case response
    case room
    case roomHooks
    case state
    case custom(String)
}
