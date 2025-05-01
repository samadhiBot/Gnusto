/// Represents a change in game state.
public struct StateChange: Codable, Sendable, Equatable {
    /// The entity being changed (can be Item, Location, Player, or Global context).
    public let entityId: EntityID

    /// The specific property being modified.
    public let propertyKey: StatePropertyKey

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
