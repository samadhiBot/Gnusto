import Foundation

/// Represents an attribute of a game object.
public protocol Attribute: Codable, Equatable, Identifiable, Sendable {
    var id: AttributeID { get }
    var rawValue: StateValue { get }

    init(id: AttributeID, rawValue: StateValue)
}

// MARK: - Explicit getters

extension Attribute {
    /// Returns the raw value as a `Bool`, or `nil` if the type does not match.
    public var bool: Bool? {
        underlyingValue as? Bool
    }

    /// Returns the raw value as a `Int`, or `nil` if the type does not match.
    public var int: Int? {
        underlyingValue as? Int
    }

    /// Returns the raw value as a `ItemID`, or `nil` if the type does not match.
    public var itemID: ItemID? {
        underlyingValue as? ItemID
    }

    /// Returns the raw value as a `Set<ItemID>`, or `nil` if the type does not match.
    public var itemIDs: Set<ItemID>? {
        underlyingValue as? Set<ItemID>
    }

    /// Returns the raw value as a `[Direction: Exit]`, or `nil` if the type does not match.
    public var locationExits: [Direction: Exit]? {
        underlyingValue as? [Direction: Exit]
    }

    /// Returns the raw value as a `LocationID`, or `nil` if the type does not match.
    public var locationID: LocationID? {
        underlyingValue as? LocationID
    }

    /// Returns the raw value as a `ParentEntity`, or `nil` if the type does not match.
    public var parentEntity: ParentEntity? {
        underlyingValue as? ParentEntity
    }

    /// Returns the raw value as a `String`, or `nil` if the type does not match.
    public var string: String? {
        underlyingValue as? String
    }

    /// Returns the raw value as a `Set<String>`, or `nil` if the type does not match.
    public var strings: Set<String>? {
        underlyingValue as? Set<String>
    }
}

// MARK: - Implicit getters

extension Attribute {
    func get() -> Bool {
        bool ?? false
    }

    func get() -> Int? {
        int
    }

    public func get() -> ItemID? {
        itemID
    }

    public func get() -> Set<ItemID>? {
        itemIDs
    }

    public func get() -> [Direction: Exit]? {
        locationExits
    }

    public func get() -> LocationID? {
        locationID
    }

    public func get() -> ParentEntity? {
        parentEntity
    }

    public func get() -> String? {
        string
    }

    public func get() -> Set<String>? {
        strings
    }
}

// MARK: - Private helpers

extension Attribute {
    private var underlyingValue: Any {
        switch rawValue {
        case .bool(let value): value
        case .int(let value): value
        case .itemID(let value): value
        case .itemIDSet(let value): value
        case .locationExits(let value): value
        case .locationID(let value): value
        case .parentEntity(let value): value
        case .string(let value): value
        case .stringSet(let value): value
        case .undefined: Int.min
        }
    }
}
