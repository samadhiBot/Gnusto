import Foundation

/// Handles the "REMOVE" command and its synonyms (e.g., "DOFF", "TAKE OFF"), allowing the
/// player to unequip an item they are currently wearing.
public struct RemoveActionHandler: ActionHandler {
    /// Validates the "REMOVE" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (the player must indicate *what* to remove).
    /// 2. The direct object refers to an existing item.
    /// 3. The item currently has the `.isWorn` flag set (it is being worn by the player).
    /// 4. The item does not have the `.isScenery` flag set (it's not an immovable part of the
    ///    environment that happens to be marked as worn, which would be unusual but is checked).
    ///
    /// Note: It implicitly assumes the item is "held" by virtue of being worn.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails, such as:
    ///           `prerequisiteNotMet` (for missing object or wrong item type),
    ///           `itemIsNotWorn` (if the item isn't currently worn),
    ///           `itemNotRemovable` (if the item is scenery).
    ///           Can also throw errors from `context.engine.item()`.
    public func validate(context: ActionContext) async throws {
        // 1. Ensure we have a direct object and it's an item
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet("Remove what?")
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can only remove items.")
        }

        // 2. Check if the item exists and is held by the player
        let targetItem = try await context.engine.item(targetItemID)

        // 3. Check if the (held) item is currently worn
        guard targetItem.hasFlag(.isWorn) else {
            throw ActionResponse.itemIsNotWorn(targetItemID)
        }

        // 4. Check if the item is fixed scenery (e.g., the ground)
        guard !targetItem.hasFlag(.isScenery) else {
            throw ActionResponse.itemNotRemovable(targetItemID)
        }
    }

    /// Processes the "REMOVE" command.
    ///
    /// Assuming validation has passed (the item is worn and not scenery),
    /// this action performs the following:
    /// 1. Retrieves the target item.
    /// 2. Clears the `.isWorn` flag on the item.
    /// 3. Ensures the `.isTouched` flag is set on the item.
    /// 4. Updates pronouns to refer to the removed item.
    /// 5. Returns an `ActionResult` with a confirmation message (e.g., "You take off the cloak.")
    ///    and the state changes.
    ///
    /// After being removed, the item remains in the player's inventory.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing the message and relevant state changes.
    /// - Throws: `ActionResponse.internalEngineError` if the direct object is not an item
    ///           (this should be caught by `validate`), or errors from `context.engine.item()`.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject,
              case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.internalEngineError("Remove: directObject was not an item in process.")
        }
        let targetItem = try await context.engine.item(targetItemID)

        var stateChanges: [StateChange] = []

        // Change 1: Set `.isWorn` to false
        if let addTouchedFlag = await context.engine.clearFlag(.isWorn, on: targetItem) {
            stateChanges.append(addTouchedFlag)
        }

        // Change 2: Set `.isTouched` to true
        if let addTouchedFlag = await context.engine.setFlag(.isTouched, on: targetItem) {
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
