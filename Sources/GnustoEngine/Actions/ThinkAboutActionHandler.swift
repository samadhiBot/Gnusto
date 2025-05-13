import Foundation

/// Action handler for the THINK ABOUT verb (based on Cloak of Darkness).
public struct ThinkAboutActionHandler: ActionHandler {
    public func validate(context: ActionContext) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = context.command.directObject else {
            throw ActionResponse.custom("Think about what?")
        }

        // 2. Skip further checks if thinking about self (PLAYER)
        if targetItemID.rawValue == "player" { return }

        // 3. Check if item exists
        let _ = try await context.engine.item(targetItemID)

        // 4. Check reachability
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    }

    public func process(context: ActionContext) async throws -> ActionResult {
        let targetItem = try await context.engine.item(context.command.directObject)
        let message: String
        var stateChanges: [StateChange] = []

        // Handle thinking about player
        // TODO: command.directObject may need to be EntityID
        if targetItem.id.rawValue == "player" {
            message = "Yes, yes, you're very important."
        } else {
            // Mark as touched if not already
            if let addTouchedFlag = await context.engine.flag(targetItem, with: .isTouched) {
                stateChanges.append(addTouchedFlag)
            }

            // Set the standard message
            message = """
                You contemplate the \(targetItem.name) for a bit, \
                but nothing fruitful comes to mind.
                """
        }

        // Create result
        return ActionResult(
            message: message,
            stateChanges: stateChanges
        )
    }
}
