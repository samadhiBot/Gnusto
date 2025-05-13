import Foundation

/// Handles the "PUT [item] ON [surface]" action.
struct PutOnActionHandler: ActionHandler {

    func validate(context: ActionContext) async throws {
        // 1. Validate Direct and Indirect Objects
        guard let itemToPutID = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet("Put what?") // Changed from Insert
        }
        guard let surfaceID = context.command.indirectObject else {
            let item = try await context.engine.item(itemToPutID)
            throw ActionResponse.prerequisiteNotMet("Put the \(item.name) on what?")
        }

        // 2. Get Items
        let itemToPut = try await context.engine.item(itemToPutID)
        let surfaceItem = try await context.engine.item(surfaceID)

        // 3. Perform Basic Checks
        guard await context.engine.playerIsHolding(itemToPutID) else {
            throw ActionResponse.itemNotHeld(itemToPutID)
        }

        guard await context.engine.playerCanReach(surfaceID) else {
             throw ActionResponse.itemNotAccessible(surfaceID)
        }

        // Prevent putting item onto itself
        if itemToPutID == surfaceID {
             throw ActionResponse.prerequisiteNotMet("You can't put something on itself.")
        }

        // Recursive check: is the target surface inside the item we are putting?
        var currentParent = surfaceItem.parent
        while case .item(let parentItemID) = currentParent {
            if parentItemID == itemToPutID {
                // Slightly awkward message, but covers the case
                throw ActionResponse.prerequisiteNotMet("You can't put the \(surfaceItem.name) inside the \(itemToPut.name) like that.")
            }
            let parentItem = try await context.engine.item(parentItemID)
            currentParent = parentItem.parent
        }

        // 4. Target Checks (Specific to PUT ON)
        guard surfaceItem.hasFlag(.isSurface) else {
            throw ActionResponse.targetIsNotASurface(surfaceID)
        }
        // TODO: Add surface capacity/volume checks?
    }

    func process(context: ActionContext) async throws -> ActionResult {
        // Get snapshots (existence guaranteed by validate)
        let itemToPut = try await context.engine.item(context.command.directObject)
        let surface = try await context.engine.item(context.command.indirectObject)

        // --- Put Successful: Calculate State Changes ---
        var stateChanges: [StateChange] = []

        // Change 1: Update item parent
        let update = await context.engine.move(itemToPut, to: .item(surface.id))
        stateChanges.append(update)

        // Change 2: Mark item touched
        if let update = await context.engine.flag(itemToPut, with: .isTouched) {
            stateChanges.append(update)
        }

        // Change 3: Mark surface touched
        if let update = await context.engine.flag(surface, with: .isTouched) {
            stateChanges.append(update)
        }

        // Change 4: Update pronoun "it"
        if let update = await context.engine.updatePronouns(to: itemToPut) {
            stateChanges.append(update)
        }

        // --- Prepare Result ---
        return ActionResult(
            message: "You put the \(itemToPut.name) on the \(surface.name).",
            stateChanges: stateChanges
        )
    }
}
