import Foundation

/// Represents a single, atomic proposed or applied modification to the game state.
///
/// `StateChange` objects are the fundamental mechanism by which the game world evolves.
/// Typically, an `ActionHandler` or other game logic will create one or more `StateChange`
/// instances to describe how an action should affect the game (e.g., moving an item,
/// changing a player's score, setting a flag).
///
/// These `StateChange` objects are then processed by the `GameEngine`, which validates them
/// (often using the `oldValue`) and applies them to the `GameState`. Each successful change
/// is also recorded in the `GameState.changeHistory`.
public struct StateChange: Codable, Sendable {
    /// The unique identifier of the game entity (e.g., an item, location, the player, or a global
    /// context) that this state change targets.
    public let entityID: EntityID

    /// The specific characteristic or property of the `entityID` that is being modified
    /// (e.g., `.itemParent`, `.playerScore`, `.setFlag`).
    public let attributeKey: AttributeKey

    /// The expected value of the `attributeKey` for the `entityID` *before* this change is applied.
    /// This property is optional. If provided, the `GameEngine` uses it to ensure that the game
    /// state hasn't been unexpectedly altered by another process between the time this change
    /// was created and when it's applied. This helps prevent race conditions or unintended
    /// consequences.
    public let oldValue: StateValue?

    /// The new, intended value for the `attributeKey` of the `entityID` *after* this change
    /// is applied.
    public let newValue: StateValue

    /// The date and time when this `StateChange` instance was created.
    /// This is used for ordering changes chronologically, particularly in the `changeHistory`.
    public let created: Date

    /// Creates a new `StateChange` record, describing a proposed modification to the game state.
    ///
    /// When you create a `StateChange`, you specify which entity is affected, which of its
    /// attributes should change, and what the new value should be. Optionally, you can provide
    /// the `oldValue` for validation purposes.
    ///
    /// - Parameters:
    ///   - entityID: The `EntityID` of the game entity to be modified.
    ///   - attributeKey: The `AttributeKey` identifying the specific property to change.
    ///   - oldValue: Optional. The expected current value of the attribute before the change.
    ///               If provided, the `GameEngine` will validate this against the actual current
    ///               state before applying the change.
    ///   - newValue: The `StateValue` that the attribute should be set to.
    public init(
        entityID: EntityID,
        attributeKey: AttributeKey,
        oldValue: StateValue? = nil,
        newValue: StateValue
    ) {
        self.entityID = entityID
        self.attributeKey = attributeKey
        self.oldValue = oldValue
        self.newValue = newValue
        self.created = .now
    }
}

// MARK: - Conformances

extension StateChange: Comparable {
    /// Compares two `StateChange` objects based on their `created` timestamps.
    ///
    /// This allows `StateChange` instances to be sorted chronologically, which is primarily
    /// used for ordering the `GameState.changeHistory`.
    /// - Returns: `true` if `lhs` was created before `rhs`; otherwise, `false`.
    public static func < (lhs: StateChange, rhs: StateChange) -> Bool {
        lhs.created < rhs.created
    }
}

extension StateChange: Equatable {
    /// Determines if two `StateChange` objects are equal based on their core properties.
    ///
    /// Two `StateChange` instances are considered equal if they target the same `entityID`
    /// and `attributeKey`, and have the same `oldValue` and `newValue`.
    /// The `created` timestamp is not considered in this comparison.
    /// - Returns: `true` if the core properties of `lhs` and `rhs` are identical; otherwise, `false`.
    public static func == (lhs: StateChange, rhs: StateChange) -> Bool {
        lhs.entityID == rhs.entityID
        && lhs.attributeKey == rhs.attributeKey
        && lhs.oldValue == rhs.oldValue
        && lhs.newValue == rhs.newValue
    }
}
