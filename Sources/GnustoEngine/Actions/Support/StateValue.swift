/// Represents the possible types of values that can be tracked in state changes.
/// Ensures values are both Codable and Sendable.
public enum StateValue: Codable, Sendable, Equatable {
    case bool(Bool)
    case int(Int)
    case itemID(ItemID)
    case itemIDSet(Set<ItemID>)
    case itemPropertySet(Set<ItemProperty>)
    case locationExits([Direction: Exit])
    case locationID(LocationID)
    case locationPropertySet(Set<LocationProperty>)
    case parentEntity(ParentEntity)
    case string(String)
    case stringSet(Set<String>)
}

// MARK: - Public casting helpers

extension StateValue {
    /// Returns the `StateValue` underlying value as a `Bool`, or `nil` if the type does not match.
    public var toBool: Bool? {
        underlyingValue as? Bool
    }

    /// Returns the `StateValue` underlying value as a `Int`, or `nil` if the type does not match.
    public var toInt: Int? {
        underlyingValue as? Int
    }

    /// Returns the `StateValue` underlying value as a `Set<String>`, or `nil` if the type
    /// does not match.
    public var toItemAdjectives: Set<String>? {
        underlyingValue as? Set<String>
    }

    /// Returns the `StateValue` underlying value as a `String`, or `nil` if the type does
    /// not match.
    public var toItemDescription: String? {
        underlyingValue as? String
    }

    /// Returns the `StateValue` underlying value as a `ItemID`, or `nil` if the type does
    /// not match.
    public var toItemID: ItemID? {
        underlyingValue as? ItemID
    }

    /// Returns the `StateValue` underlying value as a `Set<ItemID>`, or `nil` if the type
    /// does not match.
    public var toItemIDSet: Set<ItemID>? {
        underlyingValue as? Set<ItemID>
    }

    /// Returns the `StateValue` underlying value as a `Set<ItemProperty>`, or `nil` if the
    /// type does not match.
    public var toItemProperties: Set<ItemProperty>? {
        underlyingValue as? Set<ItemProperty>
    }

    /// Returns the `StateValue` underlying value as a `Set<String>`, or `nil` if the type
    /// does not match.
    public var toItemSynonyms: Set<String>? {
        underlyingValue as? Set<String>
    }

    /// Returns the `StateValue` underlying value as a `[Direction: Exit]`, or `nil` if the
    /// type does not match.
    public var toLocationExits: [Direction: Exit]? {
        underlyingValue as? [Direction: Exit]
    }

    /// Returns the `StateValue` underlying value as a `LocationID`, or `nil` if the type does
    /// not match.
    public var toLocationID: LocationID? {
        underlyingValue as? LocationID
    }

    /// Returns the `StateValue` underlying value as a `Set<LocationProperty>`, or `nil` if
    /// the type does not match.
    public var toLocationProperties: Set<LocationProperty>? {
        underlyingValue as? Set<LocationProperty>
    }

    /// Returns the `StateValue` underlying value as a `ParentEntity`, or `nil` if the type
    /// does not match.
    public var toParentEntity: ParentEntity? {
        underlyingValue as? ParentEntity
    }

    /// Returns the `StateValue` underlying value as a `String`, or `nil` if the type does
    /// not match.
    public var toString: String? {
        underlyingValue as? String
    }
}

// MARK: - Private helpers

extension StateValue {
    /// Helper to get underlying value if needed, though direct switching is often better.
    private var underlyingValue: Any {
        switch self {
        case .bool(let value): value
        case .int(let value): value
        case .itemID(let value): value
        case .itemIDSet(let value): value
        case .itemPropertySet(let value): value
        case .locationExits(let value): value
        case .locationID(let value): value
        case .locationPropertySet(let value): value
        case .parentEntity(let value): value
        case .string(let value): value
        case .stringSet(let value): value
        }
    }
}
