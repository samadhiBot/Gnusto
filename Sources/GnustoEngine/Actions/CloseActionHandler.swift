import Foundation

/// Handles the "CLOSE" context.command.
public struct CloseActionHandler: ActionHandler {
    public func validate(context: ActionContext) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = context.command.directObject else {
            throw ActionError.prerequisiteNotMet("Close what?")
        }

        // 2. Check if item exists
        guard let targetItem = await context.engine.item(targetItemID) else {
            // Standard approach: If parser resolved it, but it's gone, treat as inaccessible.
            throw ActionError.itemNotAccessible(targetItemID)
        }

        // 3. Check reachability using ScopeResolver
        let reachableItems = await context.engine.scopeResolver.itemsReachableByPlayer()
        guard reachableItems.contains(targetItemID) else {
            throw ActionError.itemNotAccessible(targetItemID)
        }

        // 4. Check if item is closable (using .openable for symmetry)
        guard targetItem.hasFlag(.isOpenable) else {
            throw ActionError.itemNotClosable(targetItemID)
        }

        // 5. Check if already closed (using dynamic property)
        let isOpen: Bool = try await context.engine.fetch(targetItemID, .isOpen)
        guard isOpen else {
            // Don't throw, let process handle the specific message "That's already closed."
            return
        }

        // Note: Closing doesn't usually depend on locked status.
    }

    public func process(context: ActionContext) async throws -> ActionResult {
        guard let targetItemID = context.command.directObject else {
            // Should be caught by validate, but defensive check.
            throw ActionError.internalEngineError("Close context.command reached process without direct object.")
        }
        guard let targetItem = await context.engine.item(targetItemID) else {
            // Should be caught by validate.
            throw ActionError.internalEngineError("Close context.command target item disappeared between validate and process.")
        }

        // Handle "already closed" case detected (but not thrown) in validate
        let isOpen: Bool = try await context.engine.fetch(targetItemID, .isOpen)
        if !isOpen {
            return ActionResult(
                success: false,
                message: "\(targetItem.withDefiniteArticle.capitalizedFirst) is already closed."
            )
        }

        // --- Calculate State Changes ---
        var stateChanges: [StateChange] = []

        // Change 1: Set dynamic property isOpen to false
        // This call applies the state change internally.
        // NOTE: The state change for `isOpen` is generated *inside* setDynamicItemValue.
        // We only need to manually create the change for `.isTouched` here.
        try await context.engine.setDynamicItemValue(
            itemID: targetItemID,
            key: .isOpen,
            newValue: false
        )

        // --- State Change: Mark as Touched ---
        if let touchedStateChange = await context.engine.flag(targetItem, with: .isTouched) {
            stateChanges.append(touchedStateChange)
        }

        // --- State Change: Update pronoun ---
        if let pronounStateChange = await context.engine.pronounStateChange(for: targetItem) {
            stateChanges.append(pronounStateChange)
        }

        // --- Prepare Result ---
        return ActionResult(
            success: true,
            message: "Closed.", // Standard Zork message
            stateChanges: stateChanges, // Only includes touched change if needed
            sideEffects: []
        )
    }

    // Rely on default postProcess to print the message.
}

// TODO: Add/verify ActionError cases: .itemNotClosable, .itemAlreadyClosed
