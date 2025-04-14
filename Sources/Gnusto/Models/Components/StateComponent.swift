import Foundation

/// Contains custom state data for an object.
public struct StateComponent: Component, Sendable {
    public static let type: ComponentType = .state

    private var values: [String: AnyValue]

    public init(_ values: [String: AnyValue] = [:]) {
        self.values = values
    }
    
    public func get<T: Sendable>(_ key: String) -> T? {
        values[key]?.get()
    }

    public mutating func set<T: Sendable>(_ key: String, _ value: T) {
        values[key] = AnyValue(value)
    }

    public mutating func remove(_ key: String) {
        values.removeValue(forKey: key)
    }
}
