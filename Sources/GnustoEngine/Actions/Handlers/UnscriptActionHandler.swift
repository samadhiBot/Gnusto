import Foundation

/// Handles the "UNSCRIPT" command for stopping transcript recording.
/// Implements transcript recording mechanics following ZIL patterns.
public struct UnscriptActionHandler: ActionHandler {
    public init() {}

    /// Validates the "UNSCRIPT" command.
    ///
    /// UNSCRIPT requires that scripting is currently active.
    public func validate(context: ActionContext) async throws {
        // Check if scripting is currently active
        if !(await context.engine.hasGlobal(.isScripting)) {
            throw ActionResponse.prerequisiteNotMet("Scripting is not currently on.")
        }
    }

    /// Processes the "UNSCRIPT" command.
    ///
    /// Stops recording the transcript of the game session.
    /// In a full implementation, this would close the transcript file and stop recording.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing confirmation message and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        var stateChanges: [StateChange] = []

        // Clear the scripting flag
        if let scriptChange = await context.engine.clearGlobal(.isScripting) {
            stateChanges.append(scriptChange)
        }

        // In a full implementation, this would:
        // 1. Close the transcript file
        // 2. Stop recording input/output
        // 3. Provide feedback about the saved transcript
        // For now, we just clear the flag and provide feedback

        return ActionResult(
            message: "[Transcript recording ended]",
            stateChanges: stateChanges
        )
    }

    /// Performs any post-processing after the unscript command.
    ///
    /// Currently no post-processing is needed for unscript.
    ///
    /// - Parameter context: The action context for the current action.
    public func postProcess(context: ActionContext, result: ActionResult) async throws {
        // No post-processing needed for unscript
    }
}
