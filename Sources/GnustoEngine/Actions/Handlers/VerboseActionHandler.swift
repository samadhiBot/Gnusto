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
        return ActionResult(
            message: context.message(.maximumVerbosity),
            changes: [
                await context.engine.setGlobal(.isVerboseMode, to: true),
                await context.engine.clearGlobal(.isBriefMode),
            ]
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
