import Foundation

/// Handles the "OPEN" context.command.
public struct OpenActionHandler: ActionHandler {
    public func validate(context: ActionContext) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet("Open what?")
        }

        // 2. Check if item exists and is accessible using ScopeResolver
        let targetItem = try await context.engine.item(targetItemID)

        // Use ScopeResolver to determine reachability
        let reachableItems = await context.engine.scopeResolver.itemsReachableByPlayer()
        guard reachableItems.contains(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // 3. Check if item is openable
        guard targetItem.hasFlag(.isOpenable) else {
            throw ActionResponse.itemNotOpenable(targetItemID)
        }

        // 4. Check if locked
        if targetItem.hasFlag(.isLocked) {
            throw ActionResponse.itemIsLocked(targetItemID)
        }
    }

    public func process(context: ActionContext) async throws -> ActionResult {
        let targetItem = try await context.engine.item(context.command.directObject)

        // Check if already open
        if try await context.engine.fetch(targetItem.id, .isOpen) {
            throw ActionResponse.itemAlreadyOpen(targetItem.id)
        }

        var stateChanges: [StateChange] = []

        if let update = await context.engine.flag(targetItem, with: .isOpen) {
            stateChanges.append(update)
        }

        if let update = await context.engine.flag(targetItem, with: .isTouched) {
            stateChanges.append(update)
        }

        // Update pronoun
        if let update = await context.engine.updatePronouns(to: targetItem) {
            stateChanges.append(update)
        }

        // Prepare the result
        return ActionResult(
            message: "You open the \(targetItem.name).",
            stateChanges: stateChanges
        )
    }

    // Rely on default postProcess to print the message.
    // Engine's execute method handles applying the stateChanges.
}

// TODO: Add/verify ActionResponse cases: .itemNotOpenable, .itemAlreadyOpen, .itemIsLocked
