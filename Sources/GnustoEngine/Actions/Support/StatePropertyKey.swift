/// Defines the specific state property being modified.
public enum StatePropertyKey: Codable, Sendable, Hashable {
    // Item Properties
    case itemParent // Uses .parentEntity
    case itemProperties
    case itemSize // Uses .int
    case itemValue // Uses .int

    // Location Properties
    case locationDescription // Uses .string
    case locationExits // Uses .exitMap
    case locationName // Uses .string
    case locationProperties // Uses .locationPropertySet

    // Player Properties
    case playerHealth // Uses .int // Example for future expansion
    case playerInventoryLimit // Uses .int
    case playerLocation // Uses .locationID
    case playerMoves // Uses .int
    case playerScore // Uses .int
    case playerStrength // Uses .int // Example for future expansion

    // Global/Misc Properties
    case flag(key: String) // Uses .bool - Reverted from FlagKey
    case gameSpecificState(key: GameStateKey) // Uses .bool/int/string - Reverted from GameStateKey
    case pronounIt // Uses .itemIDSet nullable - NOTE: Represents a Set<ItemID>
    case pronounThem // Uses .itemIDSet nullable - NOTE: Represents a Set<ItemID>
}

// MARK: - CustomStringConvertible
extension StatePropertyKey: CustomStringConvertible {
    public var description: String {
        switch self {
        case .flag(let key): "flag(\(key))"
        case .gameSpecificState(let key): "gameSpecificState(\(key))"
        case .itemParent: "itemParent"
        case .itemProperties: "itemProperties"
        case .itemSize: "itemSize"
        case .itemValue: "itemValue"
        case .locationDescription: "locationDescription"
        case .locationExits: "locationExits"
        case .locationName: "locationName"
        case .locationProperties: "locationProperties"
        case .playerHealth: "playerHealth"
        case .playerInventoryLimit: "playerInventoryLimit"
        case .playerLocation: "playerLocation"
        case .playerMoves: "playerMoves"
        case .playerScore: "playerScore"
        case .playerStrength: "playerStrength"
        case .pronounIt: "pronounIt"
        case .pronounThem: "pronounThem"
        }
    }
}
