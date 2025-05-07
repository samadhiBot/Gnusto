import Foundation
@testable import GnustoEngine

/// A mock implementation of the `ActionHandler` protocol for testing purposes.
actor MockActionHandler: ActionHandler {

    /// A closure to execute when `process` is called. Allows custom logic or error throwing.
    let processHandler: (@Sendable (ActionContext) async throws -> ActionResult)?

    /// A predefined error to throw immediately when `process` (or `validate`) is called.
    let errorToThrow: ActionError?
    /// Where the error should be thrown from.
    let throwFrom: ThrowPhase

    enum ThrowPhase {
        case validate
        case process
    }

    /// A flag to record if `validate` was called.
    private(set) var validateCalled: Bool = false
    /// A flag to record if `process` was called.
    private(set) var processCalled: Bool = false
    /// The command received by the last call to `process` (or `validate`).
    private(set) var lastCommandReceived: Command? = nil

    // Initializer for the actor
    init(
        processHandler: (@Sendable (ActionContext) async throws -> ActionResult)? = nil,
        errorToThrow: ActionError? = nil,
        throwFrom: ThrowPhase = .process // Default to throwing from process
    ) {
        self.processHandler = processHandler
        self.errorToThrow = errorToThrow
        self.throwFrom = throwFrom
    }

    func validate(context: ActionContext) async throws {
        validateCalled = true
        lastCommandReceived = context.command
        if throwFrom == .validate, let error = errorToThrow {
            throw error
        }
        // Otherwise, default validation passes
    }

    func process(context: ActionContext) async throws -> ActionResult {
        processCalled = true
        lastCommandReceived = context.command

        if let handler = processHandler {
            return try await handler(context)
        } else if throwFrom == .process, let error = errorToThrow {
            throw error
        }

        // Default success result if no handler or error
        return ActionResult(success: true, message: "Mock action succeeded.")
    }

    func postProcess(context: ActionContext, result: ActionResult) async throws {
        // Implementation needed
    }

    /// Resets the recorded call state.
    func reset() {
        validateCalled = false
        processCalled = false
        lastCommandReceived = nil
    }

    // Add async accessors for tests to read recorded state
    nonisolated func getValidateCalled() async -> Bool {
        return await validateCalled
    }
    nonisolated func getProcessCalled() async -> Bool {
        return await processCalled
    }
    nonisolated func getLastCommandReceived() async -> Command? {
        return await lastCommandReceived
    }
}
