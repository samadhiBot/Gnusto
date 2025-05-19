import Foundation

/// Handles the "WEAR" command and its synonyms (e.g., "DON"), allowing the player to
/// equip an item that is wearable.
public struct WearActionHandler: ActionHandler {
    /// Validates the "WEAR" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (the player must indicate *what* to wear).
    /// 2. The direct object refers to an existing item.
    /// 3. The player is currently holding the item.
    /// 4. The item has the `.isWearable` flag set.
    /// 5. The item does not already have the `.isWorn` flag set (it's not already being worn).
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails, such as:
    ///           `prerequisiteNotMet` (for missing object or wrong item type),
    ///           `itemNotHeld` (if player isn't holding the item),
    ///           `itemNotWearable` (if the item cannot be worn),
    ///           `itemIsAlreadyWorn` (if the item is already being worn).
    ///           Can also throw errors from `context.engine.item()`.
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

    /// Processes the "WEAR" command.
    ///
    /// Assuming validation has passed (the item is held, wearable, and not already worn),
    /// this action performs the following:
    /// 1. Retrieves the target item.
    /// 2. Sets the `.isWorn` flag on the item.
    /// 3. Ensures the `.isTouched` flag is set on the item.
    /// 4. Updates pronouns to refer to the worn item.
    /// 5. Returns an `ActionResult` with a confirmation message (e.g., "You put on the cloak.")
    ///    and the state changes.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing the message and relevant state changes.
    /// - Throws: `ActionResponse.internalEngineError` if the direct object is not an item
    ///           (this should be caught by `validate`), or errors from `context.engine.item()`.
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
