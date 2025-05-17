import Foundation

/// Handles the "CLOSE" context.command.
public struct CloseActionHandler: ActionHandler {
    public func validate(context: ActionContext) async throws {
        // 1. Ensure we have a direct object and it's an item
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet("Close what?")
        }
        guard case .item(let targetItemID) = directObjectRef else {
            // TODO: Consider a more specific message if the entity is known.
            throw ActionResponse.prerequisiteNotMet("You can't close that.")
        }

        // 2. Check if item exists
        guard let targetItem = try? await context.engine.item(targetItemID) else {
            // Standard approach: If parser resolved it, but it's gone, treat as inaccessible.
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // 3. Check reachability using ScopeResolver
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // 4. Check if item is closable (using .openable for symmetry)
        guard targetItem.hasFlag(.isOpenable) else {
            throw ActionResponse.itemNotClosable(targetItemID)
        }

        // 5. Check if already closed (using dynamic property)
        guard try await context.engine.fetch(targetItemID, .isOpen) else {
            // Let process handle the specific message "That's already closed."
            return
        }

        // Note: Closing doesn't usually depend on locked status.
    }

    public func process(context: ActionContext) async throws -> ActionResult {
        guard
            let directObjectRef = context.command.directObject,
            case .item(let targetItemID) = directObjectRef
        else {
            // This case should ideally be caught by the validate function.
            return ActionResult("You can't close that.")
        }

        let targetItem = try await context.engine.item(targetItemID)

        // Handle "already closed" case detected (but not thrown) in validate
        guard try await context.engine.fetch(targetItem.id, .isOpen) else {
            return ActionResult(
                "\(targetItem.withDefiniteArticle.capitalizedFirst) is already closed."
            )
        }

        // --- Calculate State Changes ---
        var stateChanges: [StateChange] = []

        // Change 1: Set dynamic property isOpen to false
        if let update = await context.engine.clearFlag(.isOpen, on: targetItem) {
            stateChanges.append(update)
        }

        // --- State Change: Mark as Touched ---
        if let update = await context.engine.setFlag(.isTouched, on: targetItem) {
            stateChanges.append(update)
        }

        // --- State Change: Update pronouns ---
        if let update = await context.engine.updatePronouns(to: targetItem) {
            stateChanges.append(update)
        }

        // --- Prepare Result ---
        return ActionResult(
            message: "Closed.", // Standard Zork message
            stateChanges: stateChanges
        )
    }

    // Rely on default postProcess to print the message.
}

// TODO: Add/verify ActionResponse cases: .itemNotClosable, .itemAlreadyClosed
