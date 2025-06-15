import Foundation

/// Handles the "KISS" command for kissing objects or characters.
/// Implements kissing mechanics following ZIL patterns for social interactions.
public struct KissActionHandler: ActionHandler {
    public init() {}

    /// Validates the "KISS" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (what to kiss).
    /// 2. The target item exists and is reachable.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
    public func validate(context: ActionContext) async throws {
        // Kiss requires a direct object (what to kiss)
        guard let directObjectRef = context.command.directObject else {
            let message = context.message(.kissWhat)
            throw ActionResponse.prerequisiteNotMet(message)
        }
        guard case .item(let targetItemID) = directObjectRef else {
            let message = context.message(.cannotActOnThat(verb: "kiss"))
            throw ActionResponse.prerequisiteNotMet(message)
        }

        // Check if target exists and is reachable
        _ = try await context.engine.item(targetItemID)
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    }

    /// Processes the "KISS" command.
    ///
    /// Handles kissing attempts on different types of objects and characters.
    /// Generally provides humorous or appropriate responses following ZIL traditions.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate kissing message and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.internalEngineError(
                "KissActionHandler: directObject was not an item in process."
            )
        }

        if case .player = directObjectRef {
            return ActionResult(context.message(.kissSelf))
        }

        guard case .item(let targetItemID) = directObjectRef else {
            return ActionResult(
                context.message(.kissWhat)
            )
        }

        let targetItem = try await context.engine.item(targetItemID)

        // Determine appropriate response based on object type
        let message =
            if targetItem.hasFlag(.isCharacter) {
                // Kissing characters
                context.message(.kissCharacter(character: targetItem.withDefiniteArticle))
            } else {
                // Kissing objects - generic response
                context.message(.kissObject(item: targetItem.withDefiniteArticle))
            }

        return ActionResult(
            message: message,
            changes: [
                await context.engine.setFlag(.isTouched, on: targetItem),
                await context.engine.updatePronouns(to: targetItem),
            ]
        )
    }
}
