import Foundation

/// Handles the CHOMP verb for biting, gnawing, or chewing actions.
///
/// This is a humorous command that provides entertaining responses to player attempts
/// to bite or chew on things. Based on ZIL tradition of atmospheric commands.
public struct ChompActionHandler: ActionHandler {
    public init() {}

    public func validate(
        context: ActionContext
    ) async throws {
        // CHOMP without object is always valid (general chomping)
        guard let directObjectRef = context.command.directObject else {
            return
        }

        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.canOnlyActOnItems(verb: "chomp")
            )
        }

        // Check if item exists (engine.item() will throw if not found)
        let _ = try await context.engine.item(targetItemID)

        // Check reachability
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    }

    public func process(
        context: ActionContext
    ) async throws -> ActionResult {
        // Handle general chomping (no object)
        guard let directObjectRef = context.command.directObject,
            case .item(let targetItemID) = directObjectRef
        else {
            // Get random response from message provider
            return ActionResult(
                context.message.chompResponse()
            )
        }

        let targetItem = try await context.engine.item(targetItemID)

        // Special responses for different types of items
        let message: String

        if targetItem.hasFlag(.isEdible) {
            message = context.message.chompEdible(item: targetItem.withIndefiniteArticle)
        } else if targetItem.hasFlag(.isPerson) || targetItem.hasFlag(.isCharacter) {
            message = context.message.chompPerson()
        } else if targetItem.hasFlag(.isWearable) {
            message = context.message.chompWearable()
        } else if targetItem.hasFlag(.isContainer) {
            message = context.message.chompContainer()
        } else if targetItem.hasFlag(.isWeapon) {
            message = context.message.chompWeapon()
        } else {
            // Generic responses for other objects
            let theItem = targetItem.withDefiniteArticle
            message = context.message.chompTargetResponse(item: theItem)
        }

        // Mark item as touched and update pronouns
        return ActionResult(
            message: message,
            changes: [
                await context.engine.setFlag(.isTouched, on: targetItem),
                await context.engine.updatePronouns(to: targetItem),
            ]
        )
    }
}
