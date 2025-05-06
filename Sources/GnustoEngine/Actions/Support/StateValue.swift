/// Represents the possible types of values that can be tracked in state changes.
/// Ensures values are both Codable and Sendable.
public enum StateValue: Codable, Sendable, Equatable {
    case bool(Bool)
    case int(Int)
    case itemID(ItemID)
    case itemIDSet(Set<ItemID>)
    case locationExits([Direction: Exit])
    case locationID(LocationID)
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

    /// Returns the `StateValue` underlying value as a `ItemID`, or `nil` if the type does
    /// not match.
    public var toItemID: ItemID? {
        underlyingValue as? ItemID
    }

    /// Returns the `StateValue` underlying value as a `Set<ItemID>`, or `nil` if the type
    /// does not match.
    public var toItemIDs: Set<ItemID>? {
        underlyingValue as? Set<ItemID>
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

    /// Returns the `StateValue` underlying value as a `Set<String>`, or `nil` if the type
    /// does not match.
    public var toStrings: Set<String>? {
        underlyingValue as? Set<String>
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
        case .locationExits(let value): value
        case .locationID(let value): value
        case .parentEntity(let value): value
        case .string(let value): value
        case .stringSet(let value): value
        }
    }
}

// MARK: - Conformances

extension StateValue: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = String

    public init(arrayLiteral elements: ArrayLiteralElement...) {
        self = .stringSet(Set(elements))
    }
}

extension StateValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: BooleanLiteralType) {
        self = .bool(value)
    }
}

extension StateValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: IntegerLiteralType) {
        self = .int(value)
    }
}

extension StateValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

// MARK: - Codable Conformance

//extension StateValue {
//    private enum CodingKeys: String, CodingKey {
//        case type
//        case boolValue
//        case intValue
//        case stringValue
//        case stringSetValue
//        case itemIDValue
//        case itemIDSetValue
//        case locationIDValue
//        case locationExitsValue
//        case parentEntityValue
//    }
//
//    private enum ValueType: String, Codable {
//        case bool, int, string, stringSet, itemID, itemIDSet, locationID, locationExits, parentEntity
//    }
//
//    public init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        let type = try container.decode(ValueType.self, forKey: .type)
//
//        switch type {
//        case .bool: self = .bool(try container.decode(Bool.self, forKey: .boolValue))
//        case .int: self = .int(try container.decode(Int.self, forKey: .intValue))
//        case .string: self = .string(try container.decode(String.self, forKey: .stringValue))
//        case .stringSet: self = .stringSet(try container.decode(Set<String>.self, forKey: .stringSetValue))
//        case .itemID: self = .itemID(try container.decode(ItemID.self, forKey: .itemIDValue))
//        case .itemIDSet: self = .itemIDSet(try container.decode(Set<ItemID>.self, forKey: .itemIDSetValue))
//        case .locationID: self = .locationID(try container.decode(LocationID.self, forKey: .locationIDValue))
//        case .locationExits: self = .locationExits(try container.decode([Direction: Exit].self, forKey: .locationExitsValue))
//        case .parentEntity: self = .parentEntity(try container.decode(ParentEntity.self, forKey: .parentEntityValue))
//        }
//    }
//
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//
//        switch self {
//        case .bool(let value): try container.encode(ValueType.bool, forKey: .type); try container.encode(value, forKey: .boolValue)
//        case .int(let value): try container.encode(ValueType.int, forKey: .type); try container.encode(value, forKey: .intValue)
//        case .string(let value): try container.encode(ValueType.string, forKey: .type); try container.encode(value, forKey: .stringValue)
//        case .stringSet(let value): try container.encode(ValueType.stringSet, forKey: .type); try container.encode(value, forKey: .stringSetValue)
//        case .itemID(let value): try container.encode(ValueType.itemID, forKey: .type); try container.encode(value, forKey: .itemIDValue)
//        case .itemIDSet(let value): try container.encode(ValueType.itemIDSet, forKey: .type); try container.encode(value, forKey: .itemIDSetValue)
//        case .locationID(let value): try container.encode(ValueType.locationID, forKey: .type); try container.encode(value, forKey: .locationIDValue)
//        case .locationExits(let value): try container.encode(ValueType.locationExits, forKey: .type); try container.encode(value, forKey: .locationExitsValue)
//        case .parentEntity(let value): try container.encode(ValueType.parentEntity, forKey: .type); try container.encode(value, forKey: .parentEntityValue)
//        }
//    }
//}
