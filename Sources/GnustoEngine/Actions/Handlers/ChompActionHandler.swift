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
                "You clench your fists and gnash your teeth.",
                "You chomp at the air for everyone to see.",
                "Sounds of your chomping echo around you.",
                "You practice your chomping technique.",
                "It feels good to get some chomping done.",
            ]
            return ActionResult(
                try await context.engine.randomElement(in: responses)
            )
        }

        let targetItem = try await context.engine.item(targetItemID)

                // Special responses for different types of items
        let message: String

        if targetItem.hasFlag(.isEdible) {
            message = "You take a bite. It tastes like \(targetItem.withIndefiniteArticle)."
        } else if targetItem.hasFlag(.isPerson) || targetItem.hasFlag(.isCharacter) {
            message = "That would be rude, not to mention dangerous."
        } else if targetItem.hasFlag(.isWearable) {
            message = "Chewing on clothing is not recommended for your dental health."
        } else if targetItem.hasFlag(.isContainer) {
            message = "You'd probably break your teeth on that."
        } else if targetItem.hasFlag(.isWeapon) {
            message = "That seems like a good way to hurt yourself."
        } else {
            // Generic responses for other objects
            let theItem = targetItem.withDefiniteArticle
            let responses = [
                "You give \(theItem) a tentative nibble. It tastes terrible.",
                "You chomp on \(theItem) experimentally. Not very satisfying.",
                "You bite \(theItem). Your teeth don't make much of an impression.",
                "You gnaw on \(theItem) briefly before giving up.",
                "You take a bite of \(theItem). It's not very appetizing."
            ]
            message = try await context.engine.randomElement(in: responses)
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
