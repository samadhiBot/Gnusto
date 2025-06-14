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
        return ActionResult(
            message: """
                Brief mode is now on. Location descriptions will be
                shown only when you first enter a location.
                """,
            changes: [
                await context.engine.setGlobal(.isBriefMode, to: true),
                await context.engine.clearGlobal(.isVerboseMode),
            ]
        )
    }
}
