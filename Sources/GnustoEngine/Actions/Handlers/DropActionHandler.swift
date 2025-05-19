import Foundation

/// Handles the "DROP" command and its synonyms (e.g., "PUT DOWN"), allowing the player
/// to release an item they are currently holding into their current location.
public struct DropActionHandler: ActionHandler {
    /// Validates the "DROP" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (the player must indicate *what* to drop).
    /// 2. The direct object refers to an existing item.
    /// 3. The item is not flagged as `.isScenery` (fixed, non-droppable items).
    ///
    /// Note: It explicitly *does not* throw an error if the player isn't holding the item;
    /// this case is handled gracefully in the `process` method with a specific message.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: `ActionResponse.prerequisiteNotMet` if no direct object is provided or if it's
    ///           not an item, or `ActionResponse.itemNotDroppable` if the item is scenery.
    ///           Can also throw errors from `context.engine.item()` if the item doesn't exist.
    public func validate(context: ActionContext) async throws {
        // 1. Ensure we have a direct object and it's an item
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet("Drop what?")
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can only drop items.")
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

    /// Processes the "DROP" command.
    ///
    /// Assuming basic validation has passed, this action performs the following:
    /// 1. Retrieves the target item.
    /// 2. Checks if the player is actually holding the item. If not, a message like
    ///    "You aren't holding the [item name]." is returned.
    /// 3. If the player is holding the item:
    ///    a. Creates a `StateChange` to move the item from the player's inventory to the
    ///       current location.
    ///    b. Ensures the `.isTouched` flag is set on the item.
    ///    c. Updates pronouns to refer to the dropped item.
    ///    d. Ensures the `.isWorn` flag is cleared from the item (as dropping implies removing).
    ///    e. Returns a confirmation message, typically "Dropped."
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing a message and any relevant `StateChange`s.
    /// - Throws: Can throw errors from `context.engine.item()` if the item doesn't exist.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject,
              case .item(let targetItemID) = directObjectRef else {
            // This should ideally be caught by validate.
            // Consider what message is best if this is ever reached.
            return ActionResult("You can only drop items.")
        }

        let targetItem = try await context.engine.item(targetItemID)

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
        if let update = await context.engine.setFlag(.isTouched, on: targetItem) {
            stateChanges.append(update)
        }

        // Change 3: Update pronoun
        if let update = await context.engine.updatePronouns(to: targetItem) {
            stateChanges.append(update)
        }

        // Change 4: Ensure `.isWorn` is false
        if let update = await context.engine.clearFlag(.isWorn, on: targetItem) {
            stateChanges.append(update)
        }

        return ActionResult(
            message: "Dropped.",
            stateChanges: stateChanges
        )
    }
}
