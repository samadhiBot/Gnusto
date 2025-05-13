import Foundation

/// Handles the "REMOVE" context.command and its synonyms (e.g., "DOFF", "TAKE OFF").
public struct RemoveActionHandler: ActionHandler {
    public func validate(context: ActionContext) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet("Remove what?")
        }

        // 2. Check if the item exists and is held by the player
        guard let targetItem = await context.engine.item(targetItemID),
              targetItem.parent == .player else
        {
            throw ActionResponse.itemNotHeld(targetItemID)
        }

        // 3. Check if the (held) item is currently worn
        guard targetItem.hasFlag(.isWorn) else {
            throw ActionResponse.itemIsNotWorn(targetItemID)
        }

        // 4. Check if the item is fixed scenery (e.g., the ground)
        guard !targetItem.hasFlag(.isScenery) else {
            throw ActionResponse.itemNotRemovable(targetItemID)
        }
    }

    public func process(context: ActionContext) async throws -> ActionResult {
        guard
            let targetItemID = context.command.directObject,
            let targetItem = await context.engine.item(targetItemID)
        else {
            throw ActionResponse.internalEngineError("Item snapshot disappeared!")
        }

        var stateChanges: [StateChange] = []

        // Change 1: Set `.isWorn` to false
        if let addTouchedFlag = await context.engine.flag(targetItem, remove: .isWorn) {
            stateChanges.append(addTouchedFlag)
        }

        // Change 2: Set `.isTouched` to true
        if let addTouchedFlag = await context.engine.flag(targetItem, with: .isTouched) {
            stateChanges.append(addTouchedFlag)
        }

        // Change 3: Update pronoun "it"
        if let updatePronoun = await context.engine.updatePronouns(to: targetItem) {
            stateChanges.append(updatePronoun)
        }

        // --- Prepare Result ---
        return ActionResult(
            message: "You take off the \(targetItem.name).",
            stateChanges: stateChanges
        )
    }
}
