import Foundation

/// Handles the "PUT <direct object> ON <indirect object>" command, allowing the player
/// to place an item they are holding onto a surface item.
public struct PutOnActionHandler: ActionHandler {
    /// Validates the "PUT ... ON" command.
    ///
    /// This method ensures that:
    /// 1. Both a direct object (the item to put) and an indirect object (the surface)
    ///    are specified and are valid items.
    /// 2. The player is currently holding the direct object item.
    /// 3. The player can reach the indirect object (surface) item.
    /// 4. The direct object is not the same as the indirect object (cannot put an item on itself).
    /// 5. The indirect object (surface) is not currently inside the direct object (prevents
    ///    circular placement, e.g., putting a table on a plate that is on the table).
    /// 6. The indirect object (surface) has the `.isSurface` flag set.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails, such as:
    ///           `prerequisiteNotMet` (for missing objects, wrong item types, self-placement, circular placement),
    ///           `itemNotHeld` (if item to put is not held),
    ///           `itemNotAccessible` (if surface cannot be reached),
    ///           `targetIsNotASurface` (if indirect object is not a surface).
    ///           Can also throw errors from `context.engine.item()`.
    public func validate(context: ActionContext) async throws {
        // 1. Validate Direct and Indirect Objects - both must be items
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet("Put what?")
        }
        guard case .item(let itemToPutID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can only put items on things.")
        }

        guard let indirectObjectRef = context.command.indirectObject else {
            // Fetch item name for a more informative message if indirect object is missing.
            let itemToPut = try await context.engine.item(itemToPutID)
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
                let preposition = if itemToPut.hasFlag(.isContainer) {
                    "inside"
                } else if itemToPut.hasFlag(.isSurface) {
                    "on"
                } else {
                    "in"
                }
                throw ActionResponse.prerequisiteNotMet("""
                    You can't put the \(itemToPut.name) on the \(surfaceItem.name) because \
                    the \(surfaceItem.name) is \(preposition) the \(itemToPut.name).
                    """)
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

    /// Processes the "PUT ... ON" command.
    ///
    /// Assuming validation has passed, this action performs the following:
    /// 1. Retrieves the item to be put and the surface item.
    /// 2. Moves the item to be put so its parent becomes the surface item.
    /// 3. Ensures the `.isTouched` flag is set on both the item being put and the surface.
    /// 4. Updates pronouns to refer to the item that was put.
    /// 5. Returns an `ActionResult` with a confirmation message (e.g., "You put the book on the table.")
    ///    and the state changes.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing the message and relevant state changes.
    /// - Throws: `ActionResponse.internalEngineError` if direct or indirect objects are not items
    ///           (this should be caught by `validate`), or errors from `context.engine.item()`.
    public func process(context: ActionContext) async throws -> ActionResult {
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
        if let update = await context.engine.setFlag(.isTouched, on: itemToPut) {
            stateChanges.append(update)
        }

        // Change 3: Mark surface touched
        if let update = await context.engine.setFlag(.isTouched, on: surface) {
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
