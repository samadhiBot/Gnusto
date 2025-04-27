import Foundation

/// Result of an action execution with enhanced information.
public struct ActionResult {
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
public struct StateChange: Codable {
    /// The object being changed (can be Item, Location, Player, etc. - needs clarification).
    /// Using ItemID for now as per the doc, but this might need to be more generic.
    public let objectId: ItemID

    /// The property being modified.
    public let property: String

    /// The old value (optional, for tracking/undo).
    public let oldValue: AnyCodable?

    /// The new value.
    public let newValue: AnyCodable

    /// Creates a new state change record.
    /// - Parameters:
    ///   - objectId: The ID of the object being changed.
    ///   - property: The name of the property being modified.
    ///   - oldValue: The value of the property before the change (optional).
    ///   - newValue: The value of the property after the change.
    public init(
        objectId: ItemID,
        property: String,
        oldValue: AnyCodable? = nil, // Default to nil if not provided
        newValue: AnyCodable
    ) {
        self.objectId = objectId
        self.property = property
        self.oldValue = oldValue
        self.newValue = newValue
    }
}

/// Represents a side effect of an action (e.g., starting a fuse, running a daemon).
public struct SideEffect {
    /// The type of side effect.
    public let type: SideEffectType

    /// The target of the effect (often an ItemID, but could be LocationID, etc.).
    /// Using ItemID for now.
    public let targetId: ItemID

    /// Any additional parameters specific to the side effect type.
    public let parameters: [String: AnyCodable]

    /// Creates a new side effect record.
    /// - Parameters:
    ///   - type: The type of side effect.
    ///   - targetId: The ID of the object targeted by the side effect.
    ///   - parameters: Additional data required for the side effect.
    public init(
        type: SideEffectType,
        targetId: ItemID,
        parameters: [String: AnyCodable] = [:] // Default to empty dictionary
    ) {
        self.type = type
        self.targetId = targetId
        self.parameters = parameters
    }
}

/// Enumerates the types of possible side effects.
public enum SideEffectType: String, Codable, Sendable {
    case startFuse
    case stopFuse
    case runDaemon
    case stopDaemon
    case scheduleEvent // e.g., for delayed messages or actions
    // Add more as needed
}
