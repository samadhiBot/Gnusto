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

    // Player Properties
    case playerHealth
    case playerInventoryLimit
    case playerLocation
    case playerMoves
    case playerScore
    case playerStrength

    // Global/Misc Properties
    case flag(key: String)
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
        case .flag(let key): "flag(\(key))"
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
