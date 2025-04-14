import Foundation

/// Represents an object that can provide light
public struct LightSourceComponent: Component {
    public static let type: ComponentType = .lightSource

    /// Whether the light source is currently on
    public var isOn: Bool

    /// The range of the light source in rooms (0 means only the current room)
    public let range: Int

    /// Initialize with default values
    public init(
        isOn: Bool = false,
        range: Int = 0
    ) {
        self.isOn = isOn
        self.range = range
    }
}

// MARK: - Object helpers

extension Object {
    /// Turn on a light source.
    public func turnOn() {
        modify(LightSourceComponent.self) { component in
            component.isOn = true
        }
    }

    /// Turn off a light source.
    public func turnOff() {
        modify(LightSourceComponent.self) { component in
            component.isOn = false
        }
    }
}
