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
            let itemSnapshot = await context.engine.item(targetItemID)
        else {
            throw ActionError.internalEngineError("Item snapshot disappeared!")
        }

        var stateChanges: [StateChange] = []

        // Change 1: Set `.isWorn` to false
        if itemSnapshot.attributes[.isWorn] == true {
            stateChanges.append(
                StateChange(
                    entityID: .item(targetItemID),
                    attributeKey: .itemAttribute(.isWorn),
                    oldValue: true,
                    newValue: false
                )
            )
        }

        // Change 2: Set `.isTouched` to true
        if try await context.engine.fetch(targetItemID, .isTouched) {
            stateChanges.append(
                StateChange(
                    entityID: .item(targetItemID),
                    attributeKey: .itemAttribute(.isTouched),
                    oldValue: itemSnapshot.attributes[.isTouched] ?? false,
                    newValue: true,
                )
            )
        }

        // Update pronoun "it"
        stateChanges.append(
            StateChange(
                entityID: .global,
                attributeKey: .pronounReference(pronoun: "it"),
                oldValue: nil,
                newValue: .itemIDSet([targetItemID])
            )
        )

        // --- Prepare Result ---
        let message = "You take off the \(itemSnapshot.name)."
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
