import Foundation

/// Handles the "BRIEF" command for setting brief description mode.
/// Controls verbosity of location descriptions following ZIL traditions.
public struct BriefActionHandler: ActionHandler {
    public init() {}

    /// Validates the "BRIEF" command.
    /// Brief requires no specific validation and always proceeds.
    public func validate(context: ActionContext) async throws {
        // No validation needed for BRIEF
    }

    /// Processes the "BRIEF" command.
    ///
    /// Sets the game to brief mode, where location descriptions are only shown
    /// when entering a location for the first time or when explicitly looking.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing confirmation message and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        var stateChanges: [StateChange] = []

        // Set the brief mode flag
        let briefChange = await context.engine.setGlobal(.isBriefMode, to: true)
        stateChanges.append(briefChange)

        // Clear verbose mode if it was set
        if await context.engine.hasGlobal(.isVerboseMode) {
            if let verboseChange = await context.engine.clearGlobal(.isVerboseMode) {
                stateChanges.append(verboseChange)
            }
        }

        return ActionResult(
            message: """
                Brief mode is now on. Location descriptions will be
                shown only when you first enter a location.
                """,
            stateChanges: stateChanges
        )
    }
}
