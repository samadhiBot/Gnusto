import Foundation

/// Handles the "PUT [item] ON [surface]" action.
@MainActor
struct PutOnActionHandler: EnhancedActionHandler {

    func validate(context: ActionContext) async throws {
        // 1. Validate Direct and Indirect Objects
        guard let itemToPutID = context.command.directObject else {
            throw ActionError.prerequisiteNotMet("Put what?") // Changed from Insert
        }
        guard let surfaceID = context.command.indirectObject else {
            let itemName = context.engine.item(itemToPutID)?.name ?? "item"
            throw ActionError.prerequisiteNotMet("Put the \(itemName) on what?") // Changed from Insert
        }

        // 2. Get Item Snapshots
        guard let itemToPut = context.engine.item(itemToPutID) else {
            throw ActionError.itemNotAccessible(itemToPutID)
        }
        guard let surfaceItem = context.engine.item(surfaceID) else {
            throw ActionError.itemNotAccessible(surfaceID)
        }

        // 3. Perform Basic Checks
        guard itemToPut.parent == .player else {
            throw ActionError.itemNotHeld(itemToPutID)
        }
        let reachableItems = context.engine.scopeResolver.itemsReachableByPlayer()
        guard reachableItems.contains(surfaceID) else {
             throw ActionError.itemNotAccessible(surfaceID)
        }

        // Prevent putting item onto itself
        if itemToPutID == surfaceID {
             throw ActionError.prerequisiteNotMet("You can't put something on itself.")
        }
        // Recursive check: is the target surface inside the item we are putting?
        var currentParent = surfaceItem.parent
        while case .item(let parentItemID) = currentParent {
            if parentItemID == itemToPutID {
                // Slightly awkward message, but covers the case
                throw ActionError.prerequisiteNotMet("You can't put the \(surfaceItem.name) inside the \(itemToPut.name) like that.")
            }
            guard let parentItem = context.engine.item(parentItemID) else { break }
            currentParent = parentItem.parent
        }

        // 4. Target Checks (Specific to PUT ON)
        guard surfaceItem.hasFlag(.isSurface) else {
            throw ActionError.targetIsNotASurface(surfaceID)
        }
        // TODO: Add surface capacity/volume checks?
    }

    func process(context: ActionContext) async throws -> ActionResult {
        // IDs guaranteed non-nil by validate
        let itemToPutID = context.command.directObject!
        let surfaceID = context.command.indirectObject!

        // Get snapshots (existence guaranteed by validate)
        guard let itemToPutSnapshot = context.engine.item(itemToPutID),
              let surfaceSnapshot = context.engine.item(surfaceID) else
        {
            throw ActionError.internalEngineError("Item snapshot disappeared between validate and process for PUT ON.")
        }

        // --- Put Successful: Calculate State Changes ---
        var stateChanges: [StateChange] = []

        // Change 1: Update item parent
        let oldParent = itemToPutSnapshot.parent // Should be .player
        let newParent: ParentEntity = .item(surfaceID)
        stateChanges.append(StateChange(
            entityId: .item(itemToPutID),
            attributeKey: .itemParent,
            oldValue: .parentEntity(oldParent),
            newValue: .parentEntity(newParent)
        ))

        // Change 2: Mark item touched
        if itemToPutSnapshot.attributes[.isTouched] != true {
            stateChanges.append(StateChange(
                entityId: .item(itemToPutID),
                attributeKey: .itemAttribute(.isTouched),
                oldValue: itemToPutSnapshot.attributes[.isTouched] ?? false,
                newValue: true,
            ))
        }

        // Change 3: Mark surface touched
        if surfaceSnapshot.attributes[.isTouched] != true {
            stateChanges.append(StateChange(
                entityId: .item(surfaceID),
                attributeKey: .itemAttribute(.isTouched),
                oldValue: surfaceSnapshot.attributes[.isTouched] ?? false,
                newValue: true,
            ))
        }

        // Change 4: Update pronoun "it"
        stateChanges.append(StateChange(
            entityId: .global,
            attributeKey: .pronounReference(pronoun: "it"),
            oldValue: nil,
            newValue: .itemIDSet([itemToPutID])
        ))

        // --- Prepare Result ---
        let message = "You put the \(itemToPutSnapshot.name) on the \(surfaceSnapshot.name)."
        return ActionResult(
            success: true,
            message: message,
            stateChanges: stateChanges
        )
    }
}
