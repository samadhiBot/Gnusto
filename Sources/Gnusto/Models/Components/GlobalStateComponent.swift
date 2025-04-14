import Foundation

/// A component that stores global game state values.
/// Typically attached to the World object to track game-wide conditions.
public struct GlobalStateComponent: Component {
    public static let type: ComponentType = .globalState

    /// Type-erased storage for arbitrary state values that ensures Sendable conformance.
    private var storage: [String: AnyValue] = [:]

    /// Creates a new global state component.
    public init() {
        self.storage = [:]
    }

    /// Sets a value for the specified key.
    /// - Parameters:
    ///   - value: The value to store. Must conform to Sendable.
    ///   - key: The key to associate with the value.
    public mutating func set<T: Sendable>(_ value: T, for key: String) {
        storage[key] = AnyValue(value)
    }

    /// Gets a value for the specified key.
    /// - Parameter key: The key to retrieve.
    /// - Returns: The value associated with the key, or nil if not found or type mismatch.
    public func get<T>(_ key: String) -> T? {
        return storage[key]?.get()
    }

    /// Checks if a value exists for the specified key.
    /// - Parameter key: The key to check.
    /// - Returns: True if a value exists for the key.
    public func has(_ key: String) -> Bool {
        return storage.keys.contains(key)
    }

    /// Removes a value for the specified key.
    /// - Parameter key: The key to remove.
    public mutating func remove(_ key: String) {
        storage.removeValue(forKey: key)
    }

    /// Clears all stored values.
    public mutating func clear() {
        storage.removeAll()
    }
}
