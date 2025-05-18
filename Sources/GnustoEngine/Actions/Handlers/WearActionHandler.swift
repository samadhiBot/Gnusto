import Foundation

/// Handles the "WEAR" context.command and its synonyms (e.g., "DON").
public struct WearActionHandler: ActionHandler {
    public func validate(context: ActionContext) async throws {
        // 1. Ensure we have a direct object and it's an item
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet("Wear what?")
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can only wear items.")
        }

        // 2. Check if the item exists and is held by the player
        let targetItem = try await context.engine.item(targetItemID)

        guard await context.engine.playerIsHolding(targetItemID) else {
            throw ActionResponse.itemNotHeld(targetItemID)
        }

        // 3. Check if the (held) item is wearable
        guard targetItem.hasFlag(.isWearable) else {
            throw ActionResponse.itemNotWearable(targetItemID)
        }

        // 4. Check if already worn
        guard !targetItem.hasFlag(.isWorn) else {
            throw ActionResponse.itemIsAlreadyWorn(targetItemID)
        }
    }

    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject,
              case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.internalEngineError("Wear: directObject was not an item in process.")
        }
        let targetItem = try await context.engine.item(targetItemID)
        var stateChanges: [StateChange] = []

        // Change 1: Add .worn (if not already worn)
        if let update = await context.engine.setFlag(.isWorn, on: targetItem) {
            stateChanges.append(update)
        }

        // Change 2: Add .touched (if not already touched)
        if let update = await context.engine.setFlag(.isTouched, on: targetItem) {
            stateChanges.append(update)
        }

        // Update pronoun "it"
        if let update = await context.engine.updatePronouns(to: targetItem) {
            stateChanges.append(update)
        }

        // --- Prepare Result ---
        return ActionResult(
            message: "You put on the \(targetItem.name).",
            stateChanges: stateChanges
        )
    }
}
