
/// A type-safe enumeration that represents the various kinds of values that game state
/// properties can hold.
///
/// `StateValue` is used extensively throughout the Gnusto engine, particularly in:
/// - `StateChange` objects, to define the old and new values of a modified property.
/// - `GameState.globalState`, for storing arbitrary game-specific global data.
/// - Custom attributes in `Item` and `Location` objects.
///
/// It ensures that different data types (like booleans, integers, strings, entity IDs, etc.)
/// can be handled in a consistent and type-safe manner. You will often encounter `StateValue`
/// when defining or reacting to changes in your game's world.
public enum StateValue: Codable, Sendable, Hashable {
    /// Represents a boolean value (e.g., for a flag like `isOpen` or `isLit`).
    case bool(Bool)

    /// Represents an integer value (e.g., for a score, count, or size).
    case int(Int)

    /// Represents a unique identifier for an item (`ItemID`).
    case itemID(ItemID)

    /// Represents a set of unique item identifiers (`Set<ItemID>`).
    case itemIDSet(Set<ItemID>)

    /// Represents an optional set of `EntityReference`s, often used for pronoun resolution
    /// (e.g., what "it" or "them" currently refers to). `nil` can indicate no current reference.
    case entityReferenceSet(Set<EntityReference>?)

    /// Represents the exits from a location, mapping a `Direction` to `Exit` details.
    case exits([Direction: Exit])

    /// Represents a unique identifier for a location (`LocationID`).
    case locationID(LocationID)

    /// Represents the parent entity of an item, indicating where it is located (e.g., in a
    /// location, held by the player, or inside another item).
    case parentEntity(ParentEntity)

    /// Represents a string value (e.g., for a name, description, or custom text property).
    case string(String)

    /// Represents a set of unique string values (e.g., for adjectives or synonyms).
    case stringSet(Set<String>)

    /// Represents an explicitly undefined, uninitialized, or intentionally absent value.
    /// This can be distinct from `nil` when a property might optionally hold a typed value
    /// or be truly undefined.
    case undefined
}

// MARK: - Public casting helpers

extension StateValue {
    /// Attempts to cast and return the underlying value as a `Bool`.
    /// - Returns: The `Bool` value if this `StateValue` is a `.bool` case; otherwise, `nil`.
    public var toBool: Bool? {
        underlyingValue as? Bool
    }

    /// Attempts to cast and return the underlying value as an `Int`.
    /// - Returns: The `Int` value if this `StateValue` is an `.int` case; otherwise, `nil`.
    public var toInt: Int? {
        underlyingValue as? Int
    }

    /// Attempts to cast and return the underlying value as an `ItemID`.
    /// - Returns: The `ItemID` value if this `StateValue` is an `.itemID` case; otherwise, `nil`.
    public var toItemID: ItemID? {
        underlyingValue as? ItemID
    }

    /// Attempts to cast and return the underlying value as a `Set<ItemID>`.
    /// - Returns: The `Set<ItemID>` if this `StateValue` is an `.itemIDSet` case; otherwise, `nil`.
    public var toItemIDs: Set<ItemID>? {
        underlyingValue as? Set<ItemID>
    }

    /// Attempts to cast and return the underlying value as a dictionary of location exits
    /// (`[Direction: Exit]`).
    /// - Returns: The `[Direction: Exit]` value if this `StateValue` is an `.exits` case;
    ///   otherwise, `nil`.
    public var toLocationExits: [Direction: Exit]? {
        underlyingValue as? [Direction: Exit]
    }

    /// Attempts to cast and return the underlying value as a `LocationID`.
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

    /// Returns the `StateValue` underlying value as a `Set<EntityReference>`, or `nil` if the type
    /// does not match.
    public var toEntityReferenceSet: Set<EntityReference>? {
        underlyingValue as? Set<EntityReference>
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
        case .entityReferenceSet(let value): value as Any
        case .exits(let value): value
        case .locationID(let value): value
        case .parentEntity(let value): value
        case .string(let value): value
        case .stringSet(let value): value
        case .undefined: "⚠️ undefined ⚠️"
        }
    }
}

// MARK: - Literal Conformances

extension StateValue: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = String

    /// Enables initializing a `StateValue` as a `.stringSet` directly from an array literal
    /// of strings.
    ///
    /// For example:
    /// ```swift
    /// let adjectives: StateValue = ["heavy", "brass", "old"]
    /// // adjectives is now StateValue.stringSet(["heavy", "brass", "old"])
    /// ```
    /// - Parameter elements: A variadic list of `String` elements to include in the set.
    public init(arrayLiteral elements: ArrayLiteralElement...) {
        self = .stringSet(Set(elements))
    }
}

extension StateValue: ExpressibleByBooleanLiteral {
    /// Enables initializing a `StateValue` as a `.bool` directly from a boolean literal.
    ///
    /// For example:
    /// ```swift
    /// let isOpen: StateValue = true
    /// // isOpen is now StateValue.bool(true)
    /// ```
    /// - Parameter value: The `Bool` literal.
    public init(booleanLiteral value: BooleanLiteralType) {
        self = .bool(value)
    }
}

extension StateValue: ExpressibleByIntegerLiteral {
    /// Enables initializing a `StateValue` as an `.int` directly from an integer literal.
    ///
    /// For example:
    /// ```swift
    /// let score: StateValue = 100
    /// // score is now StateValue.int(100)
    /// ```
    /// - Parameter value: The `Int` literal.
    public init(integerLiteral value: IntegerLiteralType) {
        self = .int(value)
    }
}

extension StateValue: ExpressibleByStringLiteral {
    /// Enables initializing a `StateValue` as a `.string` directly from a string literal.
    ///
    /// For example:
    /// ```swift
    /// let itemName: StateValue = "magic wand"
    /// // itemName is now StateValue.string("magic wand")
    /// ```
    /// - Parameter value: The `String` literal.
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

// MARK: - Debugging Support

extension StateValue: CustomStringConvertible {
    /// Provides a custom string representation for `StateValue`.
    public var description: String {
        switch self {
        case .bool(let bool):
            "\(bool)"
        case .int(let int):
            "\(int)"
        case .itemID(let itemID):
            ".\(itemID)"
        case .itemIDSet(let itemIDSet):
            itemIDSet.map(\.description).joined(separator: ", ")
        case .entityReferenceSet(let entityReferenceSet):
            entityReferenceSet?.map(\.description).joined(separator: ", ") ?? "[]"
        case .exits(let exits):
            exits.map {
                "\n\($0): \($1)"
            }.joined().indent()
        case .locationID(let locationID):
            ".\(locationID)"
        case .parentEntity(let parentEntity):
            parentEntity.description
        case .string(let string):
            string.multiline()
        case .stringSet(let stringSet):
            stringSet.map { "'\($0)'" }.joined(separator: ", ")
        case .undefined:
            ".undefined"
        }
    }
}
