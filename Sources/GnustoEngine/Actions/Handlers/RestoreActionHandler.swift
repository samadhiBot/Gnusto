import Foundation

/// Handles the "RESTORE" command for restoring saved game state.
/// Provides game restore functionality following ZIL traditions.
public struct RestoreActionHandler: ActionHandler {
    public init() {}

    /// Validates the "RESTORE" command.
    /// Restore requires no specific validation and always proceeds.
    public func validate(context: ActionContext) async throws {
        // No validation needed for RESTORE
    }

    /// Processes the "RESTORE" command.
    ///
    /// Attempts to restore a previously saved game state. The actual restore mechanism
    /// is handled by the GameEngine's restore functionality.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing restore confirmation or error message.
    public func process(context: ActionContext) async throws -> ActionResult {
        do {
            // Request the engine to restore the game
            try await context.engine.restoreGame()
            let message = context.message.gameRestored()
            return ActionResult(message)
        } catch {
            // If restore fails, provide appropriate error message
            let message = context.message.restoreFailed(error: error.localizedDescription)
            return ActionResult(message)
        }
    }

    /// Performs any post-processing after the restore action completes.
    ///
    /// Currently no post-processing is needed for restore.
    ///
    /// - Parameter context: The action context for the current action.
    public func postProcess(context: ActionContext) async throws {
        // No post-processing needed for restore
    }
}
