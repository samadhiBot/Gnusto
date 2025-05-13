import Foundation

/// Handles the "DROP" context.command and its synonyms (e.g., "PUT DOWN").
public struct DropActionHandler: ActionHandler {
    public func validate(context: ActionContext) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet("Drop what?")
        }

        // 2. Check if item exists
        let targetItem = try await context.engine.item(targetItemID)

        // 3. Check if player is holding the item
        guard targetItem.parent == .player else {
            // Don't throw, let process handle the specific message
            return
        }

        // 4. Check if item is droppable (not fixed scenery)
        if targetItem.hasFlag(.isScenery) {
            throw ActionResponse.itemNotDroppable(targetItemID)
        }
    }

    public func process(context: ActionContext) async throws -> ActionResult {
        let targetItem = try await context.engine.item(context.command.directObject)

        // Handle "not holding" case detected (but not thrown) in validate
        if targetItem.parent != .player {
            return ActionResult("You aren't holding the \(targetItem.name).")
        }

        // --- Calculate State Changes ---
        let currentLocationID = await context.engine.playerLocationID
        var stateChanges: [StateChange] = []

        // Change 1: Parent
        let update = await context.engine.move(targetItem, to: .location(currentLocationID))
        stateChanges.append(update)

        // Change 2: Ensure `.isTouched` is true
        if let update = await context.engine.flag(targetItem, with: .isTouched) {
            stateChanges.append(update)
        }

        // Change 3: Update pronoun
        if let update = await context.engine.updatePronouns(to: targetItem) {
            stateChanges.append(update)
        }

        // Change 4: Ensure `.isWorn` is false
        if targetItem.attributes[.isWorn] == true { // Only add change if it was worn
            let wornChange = StateChange(
                entityID: .item(targetItem.id),
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
            message: "Dropped.",
            stateChanges: stateChanges
        )
    }

    // Rely on default postProcess to print the message.
}
