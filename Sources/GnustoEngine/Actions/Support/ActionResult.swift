import Foundation

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
        }
    }
}

/// Defines the specific state property being modified.
public enum StatePropertyKey: Codable, Sendable, Hashable {
    // Item Properties
    case itemParent
    case itemProperties     // The entire Set<ItemProperty>
    case itemSize           // Int
    case itemCapacity       // Int
    case itemName           // String
    case itemAdjectives     // Set<String>
    case itemSynonyms       // Set<String>
    case itemDescription    // Added
    // TODO: Add itemShortDesc, itemLongDesc, itemText etc. if mutable descriptions needed

    // Location Properties
    case locationProperties // The entire Set<LocationProperty>
    case locationName       // String
    case locationExits      // Added
    case locationDescription // Added
    // TODO: Add locationExits, locationDesc etc. if needed

    // Player Properties
    case playerScore        // Int
    case playerMoves        // Int
    case playerCapacity     // Int
    case playerLocation     // Added
    // TODO: Add playerLocation if changing location needs to be a StateChange

    // Global State
    case globalFlag(key: String)
    case pronounReference(pronoun: String)
    // Fuse & Daemon State (Applies to EntityID.global)
    case addActiveFuse(fuseId: FuseID, initialTurns: Int)
    case removeActiveFuse(fuseId: FuseID)
    case updateFuseTurns(fuseId: FuseID) // newValue is Int
    case addActiveDaemon(daemonId: DaemonID)
    case removeActiveDaemon(daemonId: DaemonID)

    // Game Specific State
    case gameSpecificState(key: String) // Uses .bool/int/string
}

/// Identifies the specific entity whose state is being changed.
public enum EntityID: Codable, Sendable, Hashable {
    /// Refers to an item via its unique ID.
    case item(ItemID)

    /// Refers to a location via its unique ID.
    case location(LocationID)

    /// Refers to the player entity.
    case player

    /// Refers to global state not tied to a specific item or location (e.g., flags, pronouns).
    case global
}

/// Result of an action execution with enhanced information.
public struct ActionResult: Sendable {
    /// Whether the action was successful.
    public let success: Bool

    /// Message to display to the player.
    public let message: String

    /// Any state changes that occurred.
    public let stateChanges: [StateChange]

    /// Any side effects that need to be processed.
    public let sideEffects: [SideEffect]

    /// Creates a new action result.
    /// - Parameters:
    ///   - success: Whether the action was successful.
    ///   - message: Message to display to the player.
    ///   - stateChanges: Any state changes that occurred.
    ///   - sideEffects: Any side effects to be processed.
    public init(
        success: Bool,
        message: String,
        stateChanges: [StateChange] = [],
        sideEffects: [SideEffect] = []
    ) {
        self.success = success
        self.message = message
        self.stateChanges = stateChanges
        self.sideEffects = sideEffects
    }
}

/// Represents a change in game state.
public struct StateChange: Codable, Sendable, Equatable {
    /// The entity being changed (can be Item, Location, Player, or Global context).
    public let entityId: EntityID

    /// The specific property being modified.
    public let propertyKey: StatePropertyKey // Changed from String

    /// The value of the property before the change (optional).
    public let oldValue: StateValue?

    /// The value of the property after the change.
    public let newValue: StateValue

    /// Creates a new state change record.
    /// - Parameters:
    ///   - entityId: The ID of the entity being changed.
    ///   - propertyKey: The name of the property being modified.
    ///   - oldValue: The value of the property before the change (optional).
    ///   - newValue: The value of the property after the change.
    public init(
        entityId: EntityID,
        propertyKey: StatePropertyKey,
        oldValue: StateValue? = nil,
        newValue: StateValue
    ) {
        self.entityId = entityId
        self.propertyKey = propertyKey
        self.oldValue = oldValue
        self.newValue = newValue
    }
}

/// Represents a side effect of an action (e.g., starting a fuse, running a daemon).
public struct SideEffect: Sendable, Equatable {
    /// The type of side effect.
    public let type: SideEffectType

    /// The target of the effect (often an ItemID, but could be LocationID, etc.).
    /// Using ItemID for now.
    public let targetId: ItemID

    /// Any additional parameters specific to the side effect type.
    public let parameters: [String: StateValue]

    /// Creates a new side effect record.
    /// - Parameters:
    ///   - type: The type of side effect.
    ///   - targetId: The ID of the object targeted by the side effect.
    ///   - parameters: Additional data required for the side effect.
    public init(
        type: SideEffectType,
        targetId: ItemID,
        parameters: [String: StateValue] = [:]
    ) {
        self.type = type
        self.targetId = targetId
        self.parameters = parameters
    }
}

/// Enumerates the types of possible side effects.
public enum SideEffectType: String, Codable, Sendable, Equatable {
    case startFuse
    case stopFuse
    case runDaemon
    case stopDaemon
    case scheduleEvent // e.g., for delayed messages or actions
    // Add more as needed
}
