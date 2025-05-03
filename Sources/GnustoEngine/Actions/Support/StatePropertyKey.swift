import Foundation

/// Defines the specific state property being modified.
public enum StatePropertyKey: Codable, Sendable, Hashable {
    // Item Properties
    case itemAdjectives
    case itemCapacity
    case itemName
    case itemParent
    case itemProperties
    case itemSize
    case itemSynonyms
    case itemValue

    // Location Properties
    case locationDescription
    case locationExits
    case locationName
    case locationProperties

    // Dynamic Values (Stored in Item/Location, logic in Registry)
    case itemDynamicValue(key: PropertyID)
    case locationDynamicValue(key: PropertyID)

    // Player Properties
    case playerHealth
    case playerInventoryLimit
    case playerLocation
    case playerMoves
    case playerScore
    case playerStrength

    // Global/Misc Properties
    case setFlag(_ id: FlagID)
    case clearFlag(_ id: FlagID)
    case gameSpecificState(key: GameStateKey)
    case pronounReference(pronoun: String)

    // Fuse & Daemon State (Managed via GameEngine helpers typically)
    case addActiveDaemon(daemonId: DaemonID)
    case addActiveFuse(fuseId: Fuse.ID, initialTurns: Int)
    case removeActiveDaemon(daemonId: DaemonID)
    case removeActiveFuse(fuseId: Fuse.ID)
    case updateFuseTurns(fuseId: Fuse.ID)
}

// MARK: - CustomStringConvertible
extension StatePropertyKey: CustomStringConvertible {
    public var description: String {
        switch self {
        case .addActiveDaemon(let id): "addActiveDaemon(\(id))"
        case .addActiveFuse(let id, _): "addActiveFuse(\(id))"
        case .itemDynamicValue(let key): "itemDynamicValue(\(key.rawValue))"
        case .setFlag(let id): "setFlag(\(id.rawValue))"
        case .clearFlag(let id): "clearFlag(\(id.rawValue))"
        case .gameSpecificState(let key): "gameSpecificState(\(key.rawValue))"
        case .itemAdjectives: "itemAdjectives"
        case .itemCapacity: "itemCapacity"
        case .itemName: "itemName"
        case .itemParent: "itemParent"
        case .itemProperties: "itemProperties"
        case .itemSize: "itemSize"
        case .itemSynonyms: "itemSynonyms"
        case .itemValue: "itemValue"
        case .locationDescription: "locationDescription"
        case .locationExits: "locationExits"
        case .locationName: "locationName"
        case .locationProperties: "locationProperties"
        case .locationDynamicValue(let key): "locationDynamicValue(\(key.rawValue))"
        case .playerHealth: "playerHealth"
        case .playerInventoryLimit: "playerInventoryLimit"
        case .playerLocation: "playerLocation"
        case .playerMoves: "playerMoves"
        case .playerScore: "playerScore"
        case .playerStrength: "playerStrength"
        case .pronounReference(let p): "pronounReference(\(p))"
        case .removeActiveDaemon(let id): "removeActiveDaemon(\(id))"
        case .removeActiveFuse(let id): "removeActiveFuse(\(id))"
        case .updateFuseTurns(let id): "updateFuseTurns(\(id))"
        }
    }
}
