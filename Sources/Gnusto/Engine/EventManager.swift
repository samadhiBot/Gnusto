import Foundation

/// Manages the scheduling and execution of game events.
public class EventManager {
    /// The events currently scheduled in the game
    private var events: [Event] = []

    /// The initial delays for repeating events
    private var initialDelays: [Event.ID: Int] = [:]

    /// Schedule a new event to run after the specified number of turns
    /// - Parameters:
    ///   - id: The event's unique identifier
    ///   - delay: The number of turns before the event executes
    ///   - isRepeating: Whether this event repeats indefinitely
    ///   - data: Additional data associated with this event
    /// - Returns: True if the event was scheduled, false if an event with this ID already exists
    public func scheduleEvent(
        id: Event.ID,
        delay: Int,
        isRepeating: Bool = false,
        data: [String: String] = [:]
    ) -> Bool {
        // Don't schedule duplicate events
        if events.contains(where: { $0.id.rawValue == id.rawValue }) {
            return false
        }

        // Create the event
        let event = Event(id: id, turnsRemaining: delay, isRepeating: isRepeating, data: data)
        events.append(event)

        // Store the initial delay for repeating events
        if isRepeating {
            initialDelays[id] = delay
        }

        return true
    }

    /// Cancel a scheduled event
    /// - Parameter id: The ID of the event to cancel
    /// - Returns: True if the event was found and cancelled, false otherwise
    public func cancelEvent(id: Event.ID) -> Bool {
        let initialCount = events.count
        events.removeAll { $0.id.rawValue == id.rawValue }
        initialDelays.removeValue(forKey: id)
        return events.count < initialCount
    }

    /// Check if an event is currently scheduled
    /// - Parameter id: The ID of the event to check
    /// - Returns: True if the event is scheduled, false otherwise
    public func isEventScheduled(id: Event.ID) -> Bool {
        events.contains { $0.id.rawValue == id.rawValue }
    }

    /// Get a scheduled event by ID
    /// - Parameter id: The ID of the event to get
    /// - Returns: The event if found, nil otherwise
    public func getEvent(id: Event.ID) -> Event? {
        events.first { $0.id.rawValue == id.rawValue }
    }

    /// Process events for the current turn, executing any that are due
    /// - Returns: The IDs of events that should be executed this turn
    public func processEvents() -> [Event.ID] {
        var eventsToExecute: [Event.ID] = []

        // Process each event
        for i in (0..<events.count).reversed() {
            var event = events[i]

            // Check if this event should execute
            if event.decrementTurns() {
                eventsToExecute.append(event.id)

                // Handle repeating events
                if event.isRepeating, let initialDelay = initialDelays[event.id] {
                    event.resetIfRepeating(initialDelay: initialDelay)
                    events[i] = event
                } else {
                    // Remove non-repeating events that have executed
                    events.remove(at: i)
                    initialDelays.removeValue(forKey: event.id)
                }
            } else {
                // Update the event with decremented turns
                events[i] = event
            }
        }

        return eventsToExecute
    }

    /// Get all currently scheduled events
    public var scheduledEvents: [Event] {
        events
    }
}
