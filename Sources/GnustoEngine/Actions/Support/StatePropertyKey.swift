import Foundation

/// Defines the specific state property being modified.
public enum StatePropertyKey: Codable, Sendable, Hashable {
    // Item Properties
    case itemParent
    case itemProperties
    case itemSize
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
        case .addActiveDaemon(let id): return "addActiveDaemon(\(id))"
        case .addActiveFuse(let id, _): return "addActiveFuse(\(id))"
        case .flag(let key): return "flag(\(key))"
        case .gameSpecificState(let key): return "gameSpecificState(\(key.rawValue))"
        case .itemParent: return "itemParent"
        case .itemProperties: return "itemProperties"
        case .itemSize: return "itemSize"
        case .itemValue: return "itemValue"
        case .locationDescription: return "locationDescription"
        case .locationExits: return "locationExits"
        case .locationName: return "locationName"
        case .locationProperties: return "locationProperties"
        case .playerHealth: return "playerHealth"
        case .playerInventoryLimit: return "playerInventoryLimit"
        case .playerLocation: return "playerLocation"
        case .playerMoves: return "playerMoves"
        case .playerScore: return "playerScore"
        case .playerStrength: return "playerStrength"
        case .pronounReference(let p): return "pronounReference(\(p))"
        case .removeActiveDaemon(let id): return "removeActiveDaemon(\(id))"
        case .removeActiveFuse(let id): return "removeActiveFuse(\(id))"
        case .updateFuseTurns(let id): return "updateFuseTurns(\(id))"
        }
    }
}
