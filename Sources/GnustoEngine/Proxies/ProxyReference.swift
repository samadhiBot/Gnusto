import Foundation

/// Represents a reference to an object that can be the target of commands, using proxy types
/// for better ergonomics in action handlers.
///
/// This is similar to `EntityReference` but provides pre-resolved proxy objects instead of raw IDs,
/// allowing for more convenient access to dynamic properties and behaviors in action handlers.
/// The proxy objects handle dynamic property resolution through the game engine automatically.
public enum ProxyReference: Hashable, Sendable {
    /// Reference to an item via its proxy, providing dynamic property access.
    case item(ItemProxy)

    /// Reference to a location via its proxy, providing dynamic property access.
    case location(LocationProxy)

    /// Reference to the player.
    case player(PlayerProxy)

    /// Reference to a universal object (abstract concepts like "self", "all", etc.).
    case universal(Universal)

    /// Creates a new ProxyReference from an EntityReference using the specified game engine.
    ///
    /// This initializer converts raw entity references into proxy references that provide
    /// dynamic property access and convenient methods for use in action handlers.
    ///
    /// - Parameters:
    ///   - entityReference: The entity reference to convert into a proxy reference.
    ///   - engine: The game engine to use for creating proxy objects.
    public init(
        from entityReference: EntityReference,
        with engine: GameEngine
    ) async {
        switch entityReference {
        case .item(let item):
            self = .item(
                ItemProxy(item: item, engine: engine)
            )
        case .location(let location):
            self = .location(
                LocationProxy(location: location, engine: engine)
            )
        case .player:
            self = .player(
                await PlayerProxy(with: engine)
            )
        case .universal(let universal):
            self = .universal(universal)
        }
    }

    /// Returns the ItemProxy if this is an item reference, otherwise nil.
    ///
    /// This provides type-safe access to the underlying item proxy when you know
    /// the reference points to an item. Use this for item-specific operations.
    public var itemProxy: ItemProxy? {
        if case .item(let proxy) = self {
            return proxy
        }
        return nil
    }

    /// Returns the LocationProxy if this is a location reference, otherwise nil.
    ///
    /// This provides type-safe access to the underlying location proxy when you know
    /// the reference points to a location. Use this for location-specific operations.
    public var locationProxy: LocationProxy? {
        if case .location(let proxy) = self {
            return proxy
        }
        return nil
    }

    /// Returns true if this reference points to an item.
    ///
    /// Use this to check the reference type before accessing item-specific properties
    /// or performing item-specific operations.
    public var isItem: Bool {
        if case .item = self { return true }
        return false
    }

    /// Returns true if this reference points to a location.
    ///
    /// Use this to check the reference type before accessing location-specific properties
    /// or performing location-specific operations.
    public var isLocation: Bool {
        if case .location = self { return true }
        return false
    }

    /// Returns true if this reference points to the player.
    ///
    /// Use this to check if the reference represents the player character before
    /// performing player-specific operations.
    public var isPlayer: Bool {
        if case .player = self { return true }
        return false
    }

    /// Returns true if this reference points to a universal object.
    ///
    /// Universal objects represent abstract concepts like "self", "all", etc.
    /// Use this to check for special command targets that aren't physical entities.
    public var isUniversal: Bool {
        if case .universal = self { return true }
        return false
    }
}

extension ProxyReference {
    /// The associated EntityReference for this proxy reference.
    ///
    /// This provides access to the underlying entity reference that was used to create
    /// this proxy reference. Useful when you need the raw entity data or ID.
    public var entityReference: EntityReference {
        switch self {
        case .item(let proxy): .item(proxy.item)
        case .location(let proxy): .location(proxy.location)
        case .player: .player
        case .universal(let universal): .universal(universal)
        }
    }
}

// MARK: - Conformances

extension ProxyReference: Comparable {
    public static func < (lhs: ProxyReference, rhs: ProxyReference) -> Bool {
        switch (lhs, rhs) {
        case (.item(let lhsProxy), .item(let rhsProxy)):
            lhsProxy.id < rhsProxy.id
        case (.location(let lhsProxy), .location(let rhsProxy)):
            lhsProxy.id < rhsProxy.id
        case (.universal(let lhsUniversal), .universal(let rhsUniversal)):
            lhsUniversal.rawValue < rhsUniversal.rawValue
        default:
            false
        }
    }
}

extension ProxyReference: CustomStringConvertible {
    public var description: String {
        switch self {
        case .item(let item):
            item.id.rawValue
        case .location(let location):
            location.id.rawValue
        case .player:
            ".player"
        case .universal(let universalObject):
            ".universal(.\(universalObject))"
        }
    }
}

extension ProxyReference: Equatable {
    public static func == (lhs: ProxyReference, rhs: ProxyReference) -> Bool {
        switch (lhs, rhs) {
        case (.item(let lhsProxy), .item(let rhsProxy)):
            lhsProxy.id == rhsProxy.id
        case (.location(let lhsProxy), .location(let rhsProxy)):
            lhsProxy.id == rhsProxy.id
        case (.player, .player):
            true
        case (.universal(let lhsUniversal), .universal(let rhsUniversal)):
            lhsUniversal == rhsUniversal
        default:
            false
        }
    }
}

// MARK: - Entity

extension ProxyReference {
    /// The reference's name with a definite article ("the") prepended.
    ///
    /// Returns an appropriate definite article form for use in natural language output.
    /// For items and locations, this delegates to their respective proxy implementations.
    /// For the player, returns "yourself". For universal objects, returns "the [object]".
    public var withDefiniteArticle: String {
        get async {
            switch self {
            case .item(let itemProxy):
                await itemProxy.withDefiniteArticle
            case .location(let locationProxy):
                await locationProxy.withDefiniteArticle
            case .player:
                "yourself"
            case .universal(let universalObject):
                "the \(universalObject)"
            }
        }
    }
}
