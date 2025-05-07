import Foundation

/// Action handler for the THINK ABOUT verb (based on Cloak of Darkness).
public struct ThinkAboutActionHandler: ActionHandler {
    public func validate(context: ActionContext) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = context.command.directObject else {
            throw ActionError.customResponse("Think about what?")
        }

        // 2. Skip further checks if thinking about self (PLAYER)
        if targetItemID.rawValue == "player" { return }

        // 3. Check if item exists
        guard await context.engine.item(targetItemID) != nil else {
            throw ActionError.unknownItem(targetItemID)
        }

        // 4. Check reachability
        let isReachable = await context.engine.scopeResolver.itemsReachableByPlayer().contains(targetItemID)
        guard isReachable else {
            throw ActionError.itemNotAccessible(targetItemID)
        }
    }

    public func process(context: ActionContext) async throws -> ActionResult {
        guard let targetItemID = context.command.directObject else {
            // Should be caught by validate
            throw ActionError.internalEngineError("THINK ABOUT context.command reached process without direct object.")
        }

        let message: String
        var stateChanges: [StateChange] = []

        // Handle thinking about player
        if targetItemID.rawValue == "player" {
            message = "Yes, yes, you're very important."
        } else {
            // Handle thinking about an item
            guard let targetItem = await context.engine.item(targetItemID) else {
                 // Should be caught by validate
                throw ActionError.internalEngineError("Target item '\(targetItemID)' disappeared between validate and process.")
            }

            // Mark as touched if not already
            if targetItem.attributes[.isTouched] != true {
                let change = StateChange(
                    entityID: .item(targetItemID),
                    attributeKey: .itemAttribute(.isTouched),
                    oldValue: targetItem.attributes[.isTouched] ?? false,
                    newValue: true,
                )
                stateChanges.append(change)
            }

            // Set the standard message
            message = "You contemplate the \(targetItem.name) for a bit, but nothing fruitful comes to mind."
        }

        // Create result
        return ActionResult(
            success: true,
            message: message,
            stateChanges: stateChanges
        )
    }
}
