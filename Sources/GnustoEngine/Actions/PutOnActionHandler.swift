import Foundation

/// Handles the "PUT [item] ON [surface]" action.
struct PutOnActionHandler: ActionHandler {

    func validate(context: ActionContext) async throws {
        // 1. Validate Direct and Indirect Objects - both must be items
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet("Put what?")
        }
        guard case .item(let itemToPutID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can only put items on things.")
        }

        guard let indirectObjectRef = context.command.indirectObject else {
            let itemToPut = try await context.engine.item(itemToPutID) // Fetch for name
            throw ActionResponse.prerequisiteNotMet("Put the \(itemToPut.name) on what?")
        }
        guard case .item(let surfaceID) = indirectObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can only put things on items (that are surfaces).")
        }

        // 2. Get Items (existence should be implicitly validated by parser/scope or engine.item() will throw)
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
        // Direct and Indirect objects are guaranteed to be items by validate.
        guard let directObjectRef = context.command.directObject,
              case .item(let itemToPutID) = directObjectRef else {
            throw ActionResponse.internalEngineError("PutOn: Direct object not an item in process.")
        }
        guard let indirectObjectRef = context.command.indirectObject,
              case .item(let surfaceID) = indirectObjectRef else {
            throw ActionResponse.internalEngineError("PutOn: Indirect object not an item in process.")
        }

        // Get snapshots (existence guaranteed by validate)
        let itemToPut = try await context.engine.item(itemToPutID)
        let surface = try await context.engine.item(surfaceID)

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
