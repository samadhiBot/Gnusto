import Foundation

/// Represents a complete turn of combat including both player and enemy combat events.
public struct CombatTurn: Sendable {
    /// The player's action this turn (if any).
    public let playerEvent: CombatEvent?

    /// The enemy's reaction or counter-action (if any).
    public let enemyEvent: CombatEvent?

    /// Any additional events that occurred this turn.
    public var additionalEvents: [CombatEvent]

    /// Creates a combat turn with the specified events.
    ///
    /// - Parameters:
    ///   - playerEvent: The player's action for this turn. Defaults to `nil` if the player takes no action.
    ///   - enemyEvent: The enemy's reaction or counter-action for this turn. Defaults to `nil` if the enemy takes no action.
    ///   - additionalEvents: Any supplementary events that occur during this turn, such as status effects or environmental changes. Defaults to an empty array.
    public init(
        playerEvent: CombatEvent? = nil,
        enemyEvent: CombatEvent? = nil,
        additionalEvents: [CombatEvent] = []
    ) {
        self.playerEvent = playerEvent
        self.enemyEvent = enemyEvent
        self.additionalEvents = additionalEvents
    }

    /// Adds an additional event to this turn.
    /// - Parameter event: The combat event to add to the turn's additional events.
    public mutating func addEvent(_ event: CombatEvent) {
        additionalEvents.append(event)
    }

    /// All events that occurred this turn, in order.
    public var allEvents: [CombatEvent] {
        ([playerEvent, enemyEvent] + additionalEvents).compactMap(\.self)
    }
}
