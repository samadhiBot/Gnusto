import Foundation

/// Represents a change in game state.
public struct StateChange: Codable, Sendable {
    /// The entity being changed (can be Item, Location, Player, or Global context).
    public let entityId: EntityID

    /// The specific attribute being modified.
    public let attributeKey: AttributeKey

    /// The value of the attribute before the change (optional).
    public let oldValue: StateValue?

    /// The value of the attribute after the change.
    public let newValue: StateValue
    
    /// When the state change occurred.
    public let created: Date

    /// Creates a new state change record.
    /// - Parameters:
    ///   - entityId: The ID of the entity being changed.
    ///   - attributeKey: The name of the attribute being modified.
    ///   - oldValue: The value of the attribute before the change (optional).
    ///   - newValue: The value of the attribute after the change.
    public init(
        entityId: EntityID,
        attributeKey: AttributeKey,
        oldValue: StateValue? = nil,
        newValue: StateValue
    ) {
        self.entityId = entityId
        self.attributeKey = attributeKey
        self.oldValue = oldValue
        self.newValue = newValue
        self.created = .now
    }
}

// MARK: - Conformances

extension StateChange: Comparable {
    public static func < (lhs: StateChange, rhs: StateChange) -> Bool {
        lhs.created < rhs.created
    }
}

extension StateChange: Equatable {
    public static func == (lhs: StateChange, rhs: StateChange) -> Bool {
        lhs.entityId == rhs.entityId
        && lhs.attributeKey == rhs.attributeKey
        && lhs.oldValue == rhs.oldValue
        && lhs.newValue == rhs.newValue
    }
}
