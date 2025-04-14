import Foundation
@testable import GnustoEngine

/// A mock implementation of the `ActionHandler` protocol for testing purposes.
actor MockActionHandler: ActionHandler {

    /// A closure to execute when `perform` is called. Allows custom logic or error throwing.
    let performHandler: (@Sendable (Command, GameEngine) async throws -> Void)?

    /// A predefined error to throw immediately when `perform` is called, if `performHandler` is nil.
    let errorToThrow: ActionError?

    /// A flag to record if `perform` was called.
    private(set) var performCalled: Bool = false
    /// The command received by the last call to `perform`.
    private(set) var lastCommandReceived: Command? = nil

    // Initializer for the actor
    init(performHandler: (@Sendable (Command, GameEngine) async throws -> Void)? = nil, errorToThrow: ActionError? = nil) {
        self.performHandler = performHandler
        self.errorToThrow = errorToThrow
    }

    func perform(command: Command, engine: GameEngine) async throws {
        performCalled = true
        lastCommandReceived = command

        if let handler = performHandler {
            try await handler(command, engine)
        } else if let error = errorToThrow {
            throw error
        }
    }

    /// Resets the recorded call state (performCalled, lastCommandReceived).
    func reset() {
        performCalled = false
        lastCommandReceived = nil
    }

    // Add async accessors for tests to read recorded state
    nonisolated func getPerformCalled() async -> Bool {
        return await performCalled
    }
    nonisolated func getLastCommandReceived() async -> Command? {
        return await lastCommandReceived
    }
}
