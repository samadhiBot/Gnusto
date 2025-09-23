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
    ///
    /// Used by the engine for operations like daemon state updates.
    ///
    /// - Parameters:
    ///   - payload: The payload to use directly.
    ///   - executionCount: The number of times this daemon has executed.
    ///   - lastExecutionTurn: The turn when this daemon was last executed.
    init(
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
