import Foundation

/// Handles the "KICK" command for kicking objects.
/// Implements kicking mechanics following ZIL patterns for physical interactions.
public struct KickActionHandler: ActionHandler {
    public init() {}

    /// Validates the "KICK" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (what to kick).
    /// 2. The target item exists and is reachable.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
    public func validate(context: ActionContext) async throws {
        // Kick requires a direct object (what to kick)
        guard let directObjectRef = context.command.directObject else {
            let message = context.message.kickWhat()
            throw ActionResponse.prerequisiteNotMet(message)
        }
        guard case .item(let targetItemID) = directObjectRef else {
            let message = context.message.cannotActOnThat(verb: "kick")
            throw ActionResponse.prerequisiteNotMet(message)
        }

        // Check if target exists and is reachable
        _ = try await context.engine.item(targetItemID)
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    }

    /// Processes the "KICK" command.
    ///
    /// Handles kicking attempts on different types of objects.
    /// Generally provides humorous or dismissive responses following ZIL traditions.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate kicking message and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject,
            case .item(let targetItemID) = directObjectRef
        else {
            throw ActionResponse.internalEngineError(
                "KickActionHandler: directObject was not an item in process.")
        }

        let targetItem = try await context.engine.item(targetItemID)

        // Determine appropriate response based on object type
        let message =
            if targetItem.hasFlag(.isCharacter) {
                // Kicking characters is generally not advisable
                context.message.kickCharacter(character: targetItem.withDefiniteArticle)
            } else {
                // Generic kicking response for objects
                context.message.kickLargeObject(item: targetItem.withDefiniteArticle)
            }

        return ActionResult(
            message: message,
            changes: [
                await context.engine.setFlag(.isTouched, on: targetItem),
                await context.engine.updatePronouns(to: targetItem),
            ]
        )
    }

    /// Performs any post-processing after the kick action completes.
    ///
    /// Currently no post-processing is needed for basic kicking.
    ///
    /// - Parameter context: The action context for the current action.
    public func postProcess(context: ActionContext) async throws {
        // No post-processing needed for kick
    }
}
