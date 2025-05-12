import Foundation

/// Type alias for a closure that handles object-specific actions.
///
/// - Parameters:
///   - engine: The `GameEngine` instance.
///   - command: The command to handle.
/// - Returns: An `ActionResult` if the handler handled the action (potentially blocking default
///            behavior), `nil` otherwise. The result can include state changes and a message.
/// - Throws: Allows handlers to throw errors if needed.
public typealias ItemActionHandler = @Sendable (GameEngine, Command) async throws -> ActionResult?
