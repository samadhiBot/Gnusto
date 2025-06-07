import Foundation

/// Handles the CLIMB ON verb (synonyms: SIT ON, STAND ON).
///
/// The ZIL equivalent is the `V-CLIMB-ON` routine. This action represents the player
/// attempting to climb onto or sit on an object.
public struct ClimbOnActionHandler: ActionHandler {
    /// Validates that the action can be performed.
    ///
    /// - Parameter context: The `ActionContext` containing the command and game state.
    /// - Returns: An `ActionResult` indicating validation success or failure.
    public func validate(context: ActionContext) async throws -> ActionResult? {
        guard let indirectObjectRef = context.command.indirectObject else {
            return ActionResult("Climb on what?")
        }

        guard case .item(let targetItemID) = indirectObjectRef else {
            return ActionResult("You can only climb on items.")
        }

        // Check if item exists and is reachable
        guard (try? await context.engine.item(targetItemID)) != nil else {
            return ActionResult("I don't see that here.")
        }

        guard await context.engine.playerCanReach(targetItemID) else {
            return ActionResult("You can't reach that.")
        }

        return nil // Validation passed
    }

    /// Processes the climb on action.
    ///
    /// - Parameter context: The `ActionContext` containing the command and game state.
    /// - Returns: An `ActionResult` with the action outcome.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard case .item(let targetItemID) = context.command.indirectObject else {
            throw ActionResponse.internalEngineError("ClimbOn: indirectObject was not an item in process.")
        }

        let targetItem = try await context.engine.item(targetItemID)

        // Default behavior: You can't climb on most things
        return ActionResult("You can't climb on \(targetItem.withDefiniteArticle).")
    }
}
