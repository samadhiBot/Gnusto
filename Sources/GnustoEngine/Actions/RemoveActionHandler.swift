import Foundation

/// Handles the "REMOVE" context.command and its synonyms (e.g., "DOFF", "TAKE OFF").
public struct RemoveActionHandler: ActionHandler {
    public func validate(context: ActionContext) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = context.command.directObject else {
            throw ActionError.prerequisiteNotMet("Remove what?")
        }

        // 2. Check if the item exists and is held by the player
        guard let targetItem = await context.engine.item(targetItemID),
              targetItem.parent == .player else
        {
            throw ActionError.itemNotHeld(targetItemID)
        }

        // 3. Check if the (held) item is currently worn
        guard targetItem.hasFlag(.isWorn) else {
            throw ActionError.itemIsNotWorn(targetItemID)
        }

        // 4. Check if the item is fixed (e.g., cursed amulet)
        guard !targetItem.hasFlag(.isFixed) else {
            throw ActionError.itemNotRemovable(targetItemID)
        }
    }

    public func process(context: ActionContext) async throws -> ActionResult {
        guard
            let targetItemID = context.command.directObject,
            let targetItem = await context.engine.item(targetItemID)
        else {
            throw ActionError.internalEngineError("Item snapshot disappeared!")
        }

        var stateChanges: [StateChange] = []

        // Change 1: Set `.isWorn` to false
        if let touchedStateChange = await context.engine.flag(targetItem, remove: .isWorn) {
            stateChanges.append(touchedStateChange)
        }

        // Change 2: Set `.isTouched` to true
        if let touchedStateChange = await context.engine.flag(targetItem, with: .isTouched) {
            stateChanges.append(touchedStateChange)
        }

        // Change 3: Update pronoun "it"
        if let pronounStateChange = await context.engine.pronounStateChange(for: targetItem) {
            stateChanges.append(pronounStateChange)
        }

        // --- Prepare Result ---
        let message = "You take off the \(targetItem.name)."
        return ActionResult(
            success: true,
            message: message,
            stateChanges: stateChanges
        )
    }

    // Remove the old perform method
    /*
    public func perform(context: ActionContext) async throws {
        // ... old implementation ...
    }
    */
}
