import Foundation

@testable import GnustoEngine

/// A mock implementation of the `ActionHandler` protocol for testing purposes.
actor MockActionHandler: ActionHandler {
    // MARK: - ActionHandler Protocol Properties

    nonisolated let verbID: Verb

    nonisolated let syntax: [SyntaxRule]

    nonisolated let synonyms: [Verb]

    nonisolated let requiresLight: Bool

    // MARK: - Mock Properties

    /// A closure to execute when `process` is called. Allows custom logic or error throwing.
    let processHandler: (@Sendable (Command, GameEngine) async throws -> ActionResult)?

    /// A predefined error to throw immediately when `process` (or `validate`) is called.
    let errorToThrow: ActionResponse?

    /// A flag to record if `validate` was called.
    private(set) var validateCalled: Bool = false

    /// A flag to record if `process` was called.
    private(set) var processCalled: Bool = false

    /// The command received by the last call to `process` (or `validate`).
    private(set) var lastCommandReceived: Command? = nil

    // Initializer for the actor
    init(
        verbID: Verb = .take,
        syntax: [SyntaxRule] = [.match(.verb, .directObject)],
        synonyms: [Verb] = [],
        requiresLight: Bool = true,
        processHandler: (@Sendable (Command, GameEngine) async throws -> ActionResult)? = nil,
        errorToThrow: ActionResponse? = nil
    ) {
        self.verbID = verbID
        self.syntax = syntax
        self.synonyms = synonyms.isEmpty ? [verbID] : synonyms
        self.requiresLight = requiresLight
        self.processHandler = processHandler
        self.errorToThrow = errorToThrow
    }

    func process(context: ActionContext) async throws -> ActionResult {
        processCalled = true
        lastCommandReceived = context.command

        if let processHandler {
            return try await processHandler(context.command, context.engine)
        } else if let error = errorToThrow {
            throw error
        }

        // Default success result if no handler or error
        return ActionResult("Mock action succeeded.")
    }

    func postProcess(command: Command, engine: GameEngine, result: ActionResult) async throws {
        // Implementation needed
    }

    /// Resets the recorded call state.
    func reset() {
        validateCalled = false
        processCalled = false
        lastCommandReceived = nil
    }
}
