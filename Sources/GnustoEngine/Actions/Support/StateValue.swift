/// Represents the possible types of values that can be tracked in state changes.
/// Ensures values are both Codable and Sendable.
public enum StateValue: Codable, Sendable, Equatable {
    case bool(Bool)
    case int(Int)
    case string(String)
    case itemID(ItemID)             // Represents an ItemID value itself
    case locationID(LocationID)      // Added
    case itemProperties(Set<ItemProperty>)
    case itemAdjectives(Set<String>)
    case itemSynonyms(Set<String>)
    case locationProperties(Set<LocationProperty>)
    case locationExits([Direction: Exit]) // Added
    case parentEntity(ParentEntity)
    case itemIDSet(Set<ItemID>)     // For pronoun references
    // case double(Double) // Add if needed
    // case stringArray([String]) // Add if needed
    case itemDescription(String)      // Added
    // TODO: Add itemShortDesc, itemLongDesc, itemText etc. if mutable descriptions needed
    case locationPropertySet(Set<LocationProperty>) // Added for GameState.apply
    case exitMap([Direction: Exit])                // Added for GameState.apply

    // Helper to get underlying value if needed, though direct switching is often better.
    var underlyingValue: Any {
        switch self {
        case .bool(let v): return v
        case .int(let v): return v
        case .string(let v): return v
        case .itemID(let v): return v
        case .locationID(let v): return v
        case .itemProperties(let v): return v
        case .itemAdjectives(let v): return v
        case .itemSynonyms(let v): return v
        case .locationProperties(let v): return v
        case .locationExits(let v): return v
        case .parentEntity(let v): return v
        case .itemIDSet(let v): return v
        case .itemDescription(let v): return v
        case .locationPropertySet(let v): return v
        case .exitMap(let v): return v
        }
    }
}
