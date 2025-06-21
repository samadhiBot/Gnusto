import Foundation

/// Handles the LOOK UNDER verb.
///
/// The ZIL equivalent is the `V-LOOK-UNDER` routine. This action represents the player
/// attempting to look underneath an object.
public struct LookUnderActionHandler: ActionHandler {
    /// Validates that the action can be performed.
    ///
    /// - Parameter context: The `ActionContext` containing the command and game state.
    /// - Returns: An `ActionResult` indicating validation success or failure.
    public func validate(context: ActionContext) async throws {
        guard let indirectObjectRef = context.command.indirectObject else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.doWhat(verb: .lookUnder)
            )
        }

        guard case .item(let targetItemID) = indirectObjectRef else {
            let message = context.message.cannotActOnThat(verb: "look under")
            throw ActionResponse.prerequisiteNotMet(message)
        }

        // Check if item exists and is reachable
        guard (try? await context.engine.item(targetItemID)) != nil else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    }

    /// Processes the look under action.
    ///
    /// - Parameter context: The `ActionContext` containing the command and game state.
    /// - Returns: An `ActionResult` with the action outcome.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard case .item(let targetItemID) = context.command.indirectObject else {
            throw ActionResponse.internalEngineError(
                "LookUnder: indirectObject was not an item in process."
            )
        }

        let targetItem = try await context.engine.item(targetItemID)

        // Default behavior: You can't see anything of interest under most things
        return ActionResult(
            message: "You find nothing of interest under \(targetItem.withDefiniteArticle).",
            changes: [
                await context.engine.setFlag(.isTouched, on: targetItem),
                await context.engine.updatePronouns(to: targetItem),
            ]
        )
    }
}
