import Foundation

/// Handles the "VERBOSE" command for setting verbose description mode.
/// Controls verbosity of location descriptions following ZIL traditions.
public struct VerboseActionHandler: ActionHandler {
    public init() {}

    /// Validates the "VERBOSE" command.
    /// Verbose requires no specific validation and always proceeds.
    public func validate(context: ActionContext) async throws {
        // No validation needed for VERBOSE
    }

    /// Processes the "VERBOSE" command.
    ///
    /// Sets the game to verbose mode, where full location descriptions are shown
    /// every time the player enters a location.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing confirmation message and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        var stateChanges: [StateChange] = []

        // Set the verbose mode flag
        let verboseChange = await context.engine.setGlobal(.isVerboseMode, to: true)
        stateChanges.append(verboseChange)

        // Clear brief mode if it was set
        if await context.engine.hasGlobal(.isBriefMode) {
            if let briefChange = await context.engine.clearGlobal(.isBriefMode) {
                stateChanges.append(briefChange)
            }
        }

        return ActionResult(
            message: "Verbose mode is now on. Full location descriptions will be shown every time you enter a location.",
            stateChanges: stateChanges
        )
    }

    /// Performs any post-processing after the verbose action completes.
    ///
    /// Currently no post-processing is needed for verbose.
    ///
    /// - Parameter context: The action context for the current action.
    public func postProcess(context: ActionContext) async throws {
        // No post-processing needed for verbose
    }
}
