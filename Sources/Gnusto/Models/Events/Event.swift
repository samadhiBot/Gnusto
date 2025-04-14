import Foundation

/// Represents a scheduled event in the game.
public struct Event: Equatable, Sendable {
    /// The unique identifier for this event
    public let id: Event.ID

    /// The number of turns remaining before the event executes
    public var turnsRemaining: Int

    /// Whether this event repeats indefinitely
    public let isRepeating: Bool

    /// Additional data associated with this event
    public let data: [String: String]

    /// Creates a new event
    /// - Parameters:
    ///   - id: The event's unique identifier
    ///   - turnsRemaining: The number of turns remaining before the event executes
    ///   - isRepeating: Whether this event repeats indefinitely
    ///   - data: Additional data associated with this event
    public init(
        id: Event.ID,
        turnsRemaining: Int,
        isRepeating: Bool = false,
        data: [String: String] = [:]
    ) {
        self.id = id
        self.turnsRemaining = turnsRemaining
        self.isRepeating = isRepeating
        self.data = data
    }

    /// Decrements the turns remaining for this event
    /// - Returns: True if the event should execute now, false otherwise
    public mutating func decrementTurns() -> Bool {
        turnsRemaining -= 1
        return turnsRemaining <= 0
    }

    /// Resets the turns remaining if this is a repeating event
    /// - Parameter initialDelay: The initial delay to reset to
    public mutating func resetIfRepeating(initialDelay: Int) {
        if isRepeating {
            turnsRemaining = initialDelay
        }
    }
}
