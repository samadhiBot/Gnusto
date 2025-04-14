import Foundation

/// Defines attributes for a game object.
public struct ObjectComponent: Component {
    public static let type: ComponentType = .object

    /// Flags that define this object's properties
    public var flags: Set<Flag>

    /// Whether this object is currently being worn
    public var isWorn: Bool

    public init(flags: Set<Flag> = [], isWorn: Bool = false) {
        self.flags = flags
        self.isWorn = isWorn
    }

    public init(flags: Flag..., isWorn: Bool = false) {
        self.flags = Set(flags)
        self.isWorn = isWorn
    }
}

// MARK: - Object helpers

extension Object {
    /// <#Description#>
    /// - Parameter flag: <#flag description#>
    /// - Returns: <#description#>
    func hasFlag(_ flag: Flag) -> Bool {
        find(ObjectComponent.self)?.flags.contains(flag) ?? false
    }
    
    /// <#Description#>
    /// - Parameter flag: <#flag description#>
    func removeFlag(_ flag: Flag) {
        modify(ObjectComponent.self) {
            $0.flags.remove(flag)
        }
    }
    
    /// <#Description#>
    /// - Parameter flag: <#flag description#>
    func setFlag(_ flag: Flag) {
        modify(ObjectComponent.self) {
            $0.flags.insert(flag)
        }
    }
}
