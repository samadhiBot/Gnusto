import Foundation

/// Represents the runtime state of an active daemon, including any custom state
/// data that persists between daemon executions.
///
/// This structure allows daemons to maintain context-specific information across
/// game turns. For example, a wandering NPC daemon can store visited locations,
/// or a weather system daemon can track current conditions and duration, preventing
/// the need to read and write to global state for daemon-specific data.
public struct DaemonState: Codable, Sendable, Equatable, Hashable {
    /// Type-safe codable payload containing custom state data for this daemon instance.
    /// This can store any `Codable & Sendable` type, providing compile-time type safety
    /// and eliminating the need for string-based key lookups in global state.
    public var payload: AnyCodableSendable?

    /// The number of times this daemon has executed since being activated.
    /// This value is incremented each time the daemon's action runs.
    public var executionCount: Int

    /// The turn number when this daemon was last executed.
    /// This allows daemons to track timing and calculate intervals.
    public var lastExecutionTurn: Int

    // MARK: - Initializers

    /// Initializes a new daemon state with a type-safe payload.
    ///
    /// - Parameters:
    ///   - payload: Optional strongly-typed payload data for the daemon.
    ///   - executionCount: The number of times this daemon has executed (defaults to 0).
    ///   - lastExecutionTurn: The turn when this daemon was last executed (defaults to 0).
    /// - Throws: An error if the payload cannot be encoded to JSON.
    public init<T: Codable & Sendable>(
        payload: T?,
        executionCount: Int = 0,
        lastExecutionTurn: Int = 0
    ) throws {
        self.payload = try payload.map(AnyCodableSendable.init)
        self.executionCount = executionCount
        self.lastExecutionTurn = lastExecutionTurn
    }

    /// Initializes a new daemon state with no payload data.
    ///
    /// - Parameters:
    ///   - executionCount: The number of times this daemon has executed (defaults to 0).
    ///   - lastExecutionTurn: The turn when this daemon was last executed (defaults to 0).
    public init(executionCount: Int = 0, lastExecutionTurn: Int = 0) {
        self.payload = nil
        self.executionCount = executionCount
        self.lastExecutionTurn = lastExecutionTurn
    }

    /// Internal initializer that takes a payload directly without re-encoding.
    /// Used by the engine for operations like daemon state updates.
    ///
    /// - Parameters:
    ///   - payload: The payload to use directly.
    ///   - executionCount: The number of times this daemon has executed.
    ///   - lastExecutionTurn: The turn when this daemon was last executed.
    internal init(
        payload: AnyCodableSendable?,
        executionCount: Int,
        lastExecutionTurn: Int
    ) {
        self.payload = payload
        self.executionCount = executionCount
        self.lastExecutionTurn = lastExecutionTurn
    }

    // MARK: - Type-Safe Payload Access

    /// Retrieves the payload as the specified type.
    ///
    /// - Parameter type: The type to decode the payload as.
    /// - Returns: The decoded payload of the specified type, or `nil` if no payload
    ///           exists or the type doesn't match.
    public func getPayload<T: Codable & Sendable>(as type: T.Type) -> T? {
        return payload?.tryDecode(as: type)
    }

    /// Checks if the payload contains data of the specified type.
    ///
    /// - Parameter type: The type to check for.
    /// - Returns: `true` if the payload exists and can be decoded as the specified type.
    public func hasPayload<T: Codable & Sendable>(ofType type: T.Type) -> Bool {
        return getPayload(as: type) != nil
    }

    // MARK: - State Management Helpers

    /// Creates a new daemon state with updated execution tracking.
    ///
    /// - Parameter currentTurn: The current game turn number.
    /// - Returns: A new DaemonState with incremented execution count and updated last execution turn.
    public func incrementingExecution(currentTurn: Int) -> DaemonState {
        return DaemonState(
            payload: self.payload,
            executionCount: self.executionCount + 1,
            lastExecutionTurn: currentTurn
        )
    }

    /// Creates a new daemon state with the same execution tracking but updated payload.
    ///
    /// - Parameter newPayload: The new payload to store.
    /// - Returns: A new DaemonState with the updated payload.
    /// - Throws: An error if the payload cannot be encoded.
    public func updatingPayload<T: Codable & Sendable>(_ newPayload: T?) throws -> DaemonState {
        return try DaemonState(
            payload: newPayload,
            executionCount: self.executionCount,
            lastExecutionTurn: self.lastExecutionTurn
        )
    }
}

// MARK: - Common Payload Types

extension DaemonState {

    /// A structured payload for daemons that control NPC movement and behavior.
    /// Tracks visited locations and movement patterns.
    public struct NPCMovementPayload: Codable, Sendable, Equatable, Hashable {
        public let npcID: ItemID
        public var visitedLocations: [LocationID]
        public var currentTarget: LocationID?
        public var movementCooldown: Int

        public init(
            npcID: ItemID,
            visitedLocations: [LocationID] = [],
            currentTarget: LocationID? = nil,
            movementCooldown: Int = 0
        ) {
            self.npcID = npcID
            self.visitedLocations = visitedLocations
            self.currentTarget = currentTarget
            self.movementCooldown = movementCooldown
        }
    }

    /// A structured payload for environmental system daemons.
    /// Tracks environmental conditions and their durations.
    public struct EnvironmentalPayload: Codable, Sendable, Equatable, Hashable {
        public var currentCondition: String
        public var intensity: Int
        public var durationRemaining: Int
        public var parameters: [String: String]

        public init(
            currentCondition: String,
            intensity: Int = 1,
            durationRemaining: Int = 1,
            parameters: [String: String] = [:]
        ) {
            self.currentCondition = currentCondition
            self.intensity = intensity
            self.durationRemaining = durationRemaining
            self.parameters = parameters
        }
    }

    /// A structured payload for resource management daemons.
    /// Tracks player or NPC resource levels like hunger, thirst, fatigue, etc.
    public struct ResourceLevelsPayload: Codable, Sendable, Equatable, Hashable {
        public var levels: [String: Int]
        public var thresholds: [String: Int]

        public init(levels: [String: Int] = [:], thresholds: [String: Int] = [:]) {
            self.levels = levels
            self.thresholds = thresholds
        }

        public mutating func adjustLevel(_ resource: String, by amount: Int) {
            levels[resource, default: 0] += amount
        }

        public func isAboveThreshold(_ resource: String) -> Bool {
            let currentLevel = levels[resource, default: 0]
            let threshold = thresholds[resource, default: Int.max]
            return currentLevel > threshold
        }
    }

    /// A structured payload for event scheduling daemons.
    /// Manages timing and probability of random or scheduled events.
    public struct EventSchedulerPayload: Codable, Sendable, Equatable, Hashable {
        public var scheduledEvents: [String: Int]  // event name -> turn when it should trigger
        public var cooldowns: [String: Int]  // event name -> turns until it can trigger again
        public var probabilities: [String: Double]  // event name -> probability per check

        public init(
            scheduledEvents: [String: Int] = [:],
            cooldowns: [String: Int] = [:],
            probabilities: [String: Double] = [:]
        ) {
            self.scheduledEvents = scheduledEvents
            self.cooldowns = cooldowns
            self.probabilities = probabilities
        }
    }
}

// MARK: - Convenience Constructors

extension DaemonState {

    /// Creates a daemon state with NPC movement payload data.
    ///
    /// - Parameters:
    ///   - npcID: The ID of the NPC this daemon controls.
    ///   - visitedLocations: Previously visited locations.
    ///   - currentTarget: Current movement target, if any.
    ///   - movementCooldown: Turns remaining before next movement.
    ///   - executionCount: The number of times this daemon has executed.
    ///   - lastExecutionTurn: The turn when this daemon was last executed.
    /// - Throws: An error if the payload cannot be encoded.
    public static func npcMovement(
        npcID: ItemID,
        visitedLocations: [LocationID] = [],
        currentTarget: LocationID? = nil,
        movementCooldown: Int = 0,
        executionCount: Int = 0,
        lastExecutionTurn: Int = 0
    ) throws -> DaemonState {
        let payload = NPCMovementPayload(
            npcID: npcID,
            visitedLocations: visitedLocations,
            currentTarget: currentTarget,
            movementCooldown: movementCooldown
        )
        return try DaemonState(
            payload: payload,
            executionCount: executionCount,
            lastExecutionTurn: lastExecutionTurn
        )
    }

    /// Creates a daemon state with environmental payload data.
    ///
    /// - Parameters:
    ///   - currentCondition: The current environmental condition.
    ///   - intensity: The intensity level of the condition.
    ///   - durationRemaining: Turns remaining for this condition.
    ///   - parameters: Additional parameters for the condition.
    ///   - executionCount: The number of times this daemon has executed.
    ///   - lastExecutionTurn: The turn when this daemon was last executed.
    /// - Throws: An error if the payload cannot be encoded.
    public static func environmental(
        currentCondition: String,
        intensity: Int = 1,
        durationRemaining: Int = 1,
        parameters: [String: String] = [:],
        executionCount: Int = 0,
        lastExecutionTurn: Int = 0
    ) throws -> DaemonState {
        let payload = EnvironmentalPayload(
            currentCondition: currentCondition,
            intensity: intensity,
            durationRemaining: durationRemaining,
            parameters: parameters
        )
        return try DaemonState(
            payload: payload,
            executionCount: executionCount,
            lastExecutionTurn: lastExecutionTurn
        )
    }

    /// Creates a daemon state with resource levels payload data.
    ///
    /// - Parameters:
    ///   - levels: Initial resource levels.
    ///   - thresholds: Thresholds for resource warnings.
    ///   - executionCount: The number of times this daemon has executed.
    ///   - lastExecutionTurn: The turn when this daemon was last executed.
    /// - Throws: An error if the payload cannot be encoded.
    public static func resourceLevels(
        levels: [String: Int] = [:],
        thresholds: [String: Int] = [:],
        executionCount: Int = 0,
        lastExecutionTurn: Int = 0
    ) throws -> DaemonState {
        let payload = ResourceLevelsPayload(levels: levels, thresholds: thresholds)
        return try DaemonState(
            payload: payload,
            executionCount: executionCount,
            lastExecutionTurn: lastExecutionTurn
        )
    }

    /// Creates a daemon state with event scheduler payload data.
    ///
    /// - Parameters:
    ///   - scheduledEvents: Events scheduled for specific turns.
    ///   - cooldowns: Cooldowns for repeatable events.
    ///   - probabilities: Probabilities for random events.
    ///   - executionCount: The number of times this daemon has executed.
    ///   - lastExecutionTurn: The turn when this daemon was last executed.
    /// - Throws: An error if the payload cannot be encoded.
    public static func eventScheduler(
        scheduledEvents: [String: Int] = [:],
        cooldowns: [String: Int] = [:],
        probabilities: [String: Double] = [:],
        executionCount: Int = 0,
        lastExecutionTurn: Int = 0
    ) throws -> DaemonState {
        let payload = EventSchedulerPayload(
            scheduledEvents: scheduledEvents,
            cooldowns: cooldowns,
            probabilities: probabilities
        )
        return try DaemonState(
            payload: payload,
            executionCount: executionCount,
            lastExecutionTurn: lastExecutionTurn
        )
    }
}
