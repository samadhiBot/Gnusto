import Foundation

/// Defines the specific state property being modified.
public enum AttributeKey: Codable, Sendable, Hashable {
    // Item Properties
    case itemAdjectives
    case itemCapacity
    case itemName
    case itemParent
    case itemSize
    case itemSynonyms
    case itemValue

    // Location Properties
    case locationDescription
    case locationExits
    case locationName

    // Dynamic Values (Stored in Item/Location, logic in Registry)
    case itemAttribute(AttributeID)
    case locationAttribute(AttributeID)

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
    case addActiveDaemon(daemonID: DaemonID)
    case addActiveFuse(fuseID: FuseID, initialTurns: Int)
    case removeActiveDaemon(daemonID: DaemonID)
    case removeActiveFuse(fuseID: FuseID)
    case updateFuseTurns(fuseID: FuseID)
}

// MARK: - CustomStringConvertible
extension AttributeKey: CustomStringConvertible {
    public var description: String {
        switch self {
        case .addActiveDaemon(let id): "addActiveDaemon(\(id))"
        case .addActiveFuse(let id, _): "addActiveFuse(\(id))"
        case .itemAttribute(let key): "itemAttribute(\(key.rawValue))"
        case .setFlag(let id): "setFlag(\(id.rawValue))"
        case .clearFlag(let id): "clearFlag(\(id.rawValue))"
        case .gameSpecificState(let key): "gameSpecificState(\(key.rawValue))"
        case .itemAdjectives: "itemAdjectives"
        case .itemCapacity: "itemCapacity"
        case .itemName: "itemName"
        case .itemParent: "itemParent"
        case .itemSize: "itemSize"
        case .itemSynonyms: "itemSynonyms"
        case .itemValue: "itemValue"
        case .locationDescription: "locationDescription"
        case .locationExits: "locationExits"
        case .locationName: "locationName"
        case .locationAttribute(let key): "locationAttribute(\(key.rawValue))"
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
