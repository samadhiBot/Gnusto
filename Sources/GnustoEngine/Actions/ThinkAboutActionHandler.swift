import Foundation

/// Action handler for the THINK ABOUT verb (based on Cloak of Darkness).
public struct ThinkAboutActionHandler: ActionHandler {
    public func validate(context: ActionContext) async throws {
        // 1. Ensure we have a direct object
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.custom("Think about what?")
        }

        switch directObjectRef {
        case .player:
            return // Thinking about self is always valid.
        case .item(let targetItemID):
            // 2. Check if item exists
            let _ = try await context.engine.item(targetItemID) // Will throw if not found
            // 3. Check reachability
            guard await context.engine.playerCanReach(targetItemID) else {
                throw ActionResponse.itemNotAccessible(targetItemID)
            }
        case .location(_):
            // For now, only allow thinking about items or the player.
            // TODO: Consider if thinking about locations should have a custom response.
            throw ActionResponse.prerequisiteNotMet("You can only think about items or yourself.")
        }
    }

    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject else {
            // Should be caught by validate.
            throw ActionResponse.internalEngineError("ThinkAbout: directObject was nil in process.")
        }

        let message: String
        var stateChanges: [StateChange] = []

        switch directObjectRef {
        case .player:
            message = "Yes, yes, you're very important."
        case .item(let targetItemID):
            let targetItem = try await context.engine.item(targetItemID)
            // Mark as touched if not already
            if let addTouchedFlag = await context.engine.setFlag(.isTouched, on: targetItem) {
                stateChanges.append(addTouchedFlag)
            }
            // Update pronoun
            if let updatePronoun = await context.engine.updatePronouns(to: targetItem) {
                stateChanges.append(updatePronoun)
            }
            message = """
                You contemplate the \(targetItem.name) for a bit, \
                but nothing fruitful comes to mind.
                """
        case .location(_):
            // Should be caught by validate if we decide not to support thinking about locations.
            // If supported, a custom message would go here.
            message = "You ponder the location, but it remains stubbornly locational."
        }

        // Create result
        return ActionResult(
            message: message,
            stateChanges: stateChanges
        )
    }
}
