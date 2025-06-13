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
            throw ActionResponse.prerequisiteNotMet("You can only chomp on items.")
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
              case .item(let targetItemID) = directObjectRef else {
            let responses = [
                "You chomp your teeth together menacingly.",
                "You gnash your teeth with determination.",
                "You bite the air with gusto.",
                "Your chomping echoes through the area.",
                "You practice your chomping technique."
            ]
            return ActionResult(responses.randomElement()!)
        }

        let targetItem = try await context.engine.item(targetItemID)

                // Special responses for different types of items
        let message: String

        if targetItem.hasFlag(.isEdible) {
            message = "You take a big bite. Delicious!"
        } else if targetItem.hasFlag(.isPerson) || targetItem.hasFlag(.isCharacter) {
            message = "That would be rather rude, not to mention dangerous."
        } else if targetItem.hasFlag(.isWearable) {
            message = "Chewing on clothing is not recommended for your dental health."
        } else if targetItem.hasFlag(.isContainer) {
            message = "You'd probably break your teeth on that."
        } else if targetItem.hasFlag(.isWeapon) {
            message = "That seems like a good way to hurt yourself."
        } else {
            // Generic responses for other objects
            let responses = [
                "You give \(targetItem.name) a tentative nibble. It tastes terrible.",
                "You chomp on \(targetItem.name) experimentally. Not very satisfying.",
                "You bite \(targetItem.name). Your teeth don't make much of an impression.",
                "You gnaw on \(targetItem.name) briefly before giving up.",
                "You take a bite of \(targetItem.name). It's not very appetizing."
            ]
            message = responses.randomElement()!
        }

        // Mark item as touched and update pronouns
        return ActionResult(
            message: message,
            changes:
                await context.engine.setFlag(.isTouched, on: targetItem),
                await context.engine.updatePronouns(to: targetItem)
        )
    }
}
