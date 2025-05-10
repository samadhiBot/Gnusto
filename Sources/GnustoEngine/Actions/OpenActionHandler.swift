import Foundation

/// Handles the "OPEN" context.command.
public struct OpenActionHandler: ActionHandler {
    public func validate(context: ActionContext) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = context.command.directObject else {
            throw ActionError.prerequisiteNotMet("Open what?")
        }

        // 2. Check if item exists and is accessible using ScopeResolver
        guard let targetItem = await context.engine.item(targetItemID) else {
            // If snapshot is nil, it implies item doesn't exist in current state.
            // ScopeResolver checks typically operate on existing items.
            // Let's use the standard not accessible error.
            throw ActionError.itemNotAccessible(targetItemID)
        }

        // Use ScopeResolver to determine reachability
        let reachableItems = await context.engine.scopeResolver.itemsReachableByPlayer()
        guard reachableItems.contains(targetItemID) else {
            throw ActionError.itemNotAccessible(targetItemID)
        }

        // 3. Check if item is openable
        guard targetItem.hasFlag(.isOpenable) else {
            throw ActionError.itemNotOpenable(targetItemID)
        }

        // 4. Check if locked
        if targetItem.hasFlag(.isLocked) {
            throw ActionError.itemIsLocked(targetItemID)
        }
    }

    public func process(context: ActionContext) async throws -> ActionResult {
        guard let targetItemID = context.command.directObject else {
            // Should be caught by validate, but defensive check.
            throw ActionError.internalEngineError("Open context.command reached process without direct object.")
        }
        guard let targetItem = await context.engine.item(targetItemID) else {
            // Should be caught by validate.
            throw ActionError.internalEngineError("Open context.command target item disappeared between validate and process.")
        }

        // Check if already open using dynamic property
        if try await context.engine.fetch(targetItemID, .isOpen) {
            throw ActionError.itemAlreadyOpen(targetItemID)
        }

        // Set the dynamic value for 'isOpen' to true
        // This function call applies the state change internally but returns Void.
        try await context.engine.setDynamicItemValue(
            itemID: targetItemID,
            key: .isOpen,
            newValue: true,
        )

        // Update the 'touched' flag - Create a state change if not already touched
        var stateChanges: [StateChange] = []
        if let addTouchedFlag = await context.engine.flag(targetItem, with: .isTouched) {
            stateChanges.append(addTouchedFlag)
        }

        // Update pronoun
        if let updatePronoun = await context.engine.updatePronouns(to: targetItem) {
            stateChanges.append(updatePronoun)
        }

        // Prepare the result
        return ActionResult(
            success: true,
            message: "You open the \(targetItem.name).",
            // Only includes touched change if it happened. The open change is applied by setDynamicItemValue.
            stateChanges: stateChanges
        )
    }

    // Rely on default postProcess to print the message.
    // Engine's execute method handles applying the stateChanges.
}

// TODO: Add/verify ActionError cases: .itemNotOpenable, .itemAlreadyOpen, .itemIsLocked
