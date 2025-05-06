import Foundation

/// Handles the "DROP" context.command and its synonyms (e.g., "PUT DOWN").
public struct DropActionHandler: EnhancedActionHandler {

    public init() {}

    // MARK: - EnhancedActionHandler

    public func validate(context: ActionContext) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = context.command.directObject else {
            throw ActionError.prerequisiteNotMet("Drop what?")
        }

        // 2. Check if item exists
        guard let targetItem = await context.engine.item(targetItemID) else {
            // If parser resolved it, but it's gone, treat as inaccessible/not held.
            // For DROP, the more specific error is relevant.
            throw ActionError.itemNotHeld(targetItemID) // Or should this be itemNotAccessible?
        }

        // 3. Check if player is holding the item
        guard targetItem.parent == .player else {
            // Don't throw, let process handle the specific message
            return
        }

        // 4. Check if item is droppable (not fixed)
        if targetItem.hasFlag(.isFixed) {
            throw ActionError.itemNotDroppable(targetItemID)
        }
    }

    public func process(context: ActionContext) async throws -> ActionResult {
        guard let targetItemID = context.command.directObject else {
            throw ActionError.internalEngineError("Drop context.command reached process without direct object.")
        }
        guard let targetItem = await context.engine.item(targetItemID) else {
            // Should be caught by validate.
            throw ActionError.internalEngineError("Drop context.command target item disappeared between validate and process.")
        }

        // Handle "not holding" case detected (but not thrown) in validate
        if targetItem.parent != .player {
            return ActionResult(success: false, message: "You aren't holding the \(targetItem.name).")
        }

        // --- Calculate State Changes ---
        let currentLocationID = await context.engine.gameState.player.currentLocationID
        var stateChanges: [StateChange] = []

        // Change 1: Parent
        let parentChange = StateChange(
            entityID: .item(targetItemID),
            attributeKey: .itemParent,
            oldValue: .parentEntity(.player),
            newValue: .parentEntity(.location(currentLocationID))
        )
        stateChanges.append(parentChange)

        // Change 2: Ensure `.isTouched` is true
        if targetItem.attributes[.isTouched] != true {
            let touchedChange = StateChange(
                entityID: .item(targetItemID),
                attributeKey: .itemAttribute(.isTouched),
                oldValue: targetItem.attributes[.isTouched] ?? false,
                newValue: true,
            )
            stateChanges.append(touchedChange)
        }

        // Change 3: Ensure `.isWorn` is false
        if targetItem.attributes[.isWorn] == true { // Only add change if it was worn
            let wornChange = StateChange(
                entityID: .item(targetItemID),
                attributeKey: .itemAttribute(.isWorn),
                oldValue: true,
                newValue: false
            )
            stateChanges.append(wornChange)
        }

        // Dropping usually doesn't affect pronouns unless maybe it was the last thing referred to?
        // For simplicity, let's not change pronouns on drop for now.
        // We could potentially clear the pronoun if it referred *only* to the dropped item.

        // --- Prepare Result ---
        return ActionResult(
            success: true,
            message: "Dropped.", // Zork 1 message
            stateChanges: stateChanges
        )
    }

    // Rely on default postProcess to print the message.
}
