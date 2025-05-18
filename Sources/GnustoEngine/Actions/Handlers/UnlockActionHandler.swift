import Foundation

/// Handles the "UNLOCK <direct object> WITH <indirect object>" command, allowing the player
/// to unlock a lockable item using a key.
public struct UnlockActionHandler: ActionHandler {
    /// Validates the "UNLOCK" command.
    ///
    /// This method ensures that:
    /// 1. Both a direct object (the item to unlock) and an indirect object (the key)
    ///    are specified and are valid items.
    /// 2. The key item is currently held by the player.
    /// 3. The player can reach the item to be unlocked.
    /// 4. The target item has the `.isLockable` flag set.
    /// 5. The target item currently has the `.isLocked` flag set (it's not already unlocked).
    /// 6. The key item matches the `.lockKey` attribute of the target item.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails, such as:
    ///           `prerequisiteNotMet` (for missing objects, wrong item types, or already unlocked),
    ///           `itemNotHeld` (if key is not held),
    ///           `itemNotAccessible` (if target cannot be reached),
    ///           `itemNotUnlockable` (if target is not lockable),
    ///           `wrongKey` (if the key doesn't match).
    ///           Can also throw errors from `context.engine.item()`.
    public func validate(context: ActionContext) async throws {
        // 1. Validate command structure: Need DO and IO, both must be items
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet("Unlock what?")
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can only unlock items.")
        }

        guard let indirectObjectRef = context.command.indirectObject else {
            throw ActionResponse.prerequisiteNotMet("Unlock it with what?")
        }
        guard case .item(let keyItemID) = indirectObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can only use an item as a key.")
        }

        // 2. Get item snapshots
        let targetItem = try await context.engine.item(targetItemID)
        let keyItem = try await context.engine.item(keyItemID)

        // 3. Check reachability
        guard keyItem.parent == .player else {
            throw ActionResponse.itemNotHeld(keyItemID)
        }

        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // 4. Check item properties
        guard targetItem.hasFlag(.isLockable) else {
            throw ActionResponse.itemNotUnlockable(targetItemID)
        }

        guard targetItem.hasFlag(.isLocked) else {
            throw ActionResponse.prerequisiteNotMet("The \(targetItem.name) is already unlocked.")
        }

        // 5. Check if it's the correct key
        guard targetItem.attributes[.lockKey] == .itemID(keyItemID) else {
            throw ActionResponse.wrongKey(keyID: keyItemID, lockID: targetItemID)
        }
    }

    /// Processes the "UNLOCK" command.
    ///
    /// Assuming validation has passed (correct key, lockable and locked item, etc.),
    /// this action performs the following:
    /// 1. Retrieves the target item and the key item.
    /// 2. Clears the `.isLocked` flag on the target item.
    /// 3. Ensures the `.isTouched` flag is set on both the target item and the key item.
    /// 4. Updates pronouns to refer to the target item and the key.
    /// 5. Returns an `ActionResult` with a confirmation message (e.g., "The wooden door is now unlocked.")
    ///    and the state changes.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing the message and relevant state changes.
    /// - Throws: `ActionResponse.internalEngineError` if direct or indirect objects are not items
    ///           (this should be caught by `validate`), or errors from `context.engine.item()`.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Direct and Indirect objects are guaranteed to be items by validate.
        guard let directObjectRef = context.command.directObject,
              case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.internalEngineError("Unlock: Direct object not an item in process.")
        }
        guard let indirectObjectRef = context.command.indirectObject,
              case .item(let keyItemID) = indirectObjectRef else {
            throw ActionResponse.internalEngineError("Unlock: Indirect object not an item in process.")
        }

        // Get snapshots (existence guaranteed by validate)
        let targetItem = try await context.engine.item(targetItemID)
        let keyItem = try await context.engine.item(keyItemID)

        // Validation ensures the item was locked, so no need to check again here.

        // --- Unlock Successful: Calculate State Changes ---
        var stateChanges: [StateChange] = []

        // Change 1: Clear `.isLocked` flag from target item.
        // Validation ensures the item was locked, so an update should always occur.
        if let update = await context.engine.clearFlag(.isLocked, on: targetItem) {
            stateChanges.append(update)
        }

        // Change 2: Ensure `.isTouched` flag is set on target item.
        if let update = await context.engine.setFlag(.isTouched, on: targetItem) {
            stateChanges.append(update)
        }

        // Change 3: Ensure `.isTouched` flag is set on key item.
        if let update = await context.engine.setFlag(.isTouched, on: keyItem) {
            stateChanges.append(update)
        }

        // Change 4: Update pronouns to refer to the target and key.
        if let update = await context.engine.updatePronouns(to: targetItem, keyItem) {
            stateChanges.append(update)
        }

        // --- Prepare Result ---
        // Manually construct definite article message
        return ActionResult(
            message: "The \(targetItem.name) is now unlocked.",
            stateChanges: stateChanges
        )
    }

    // Default postProcess will print the message
}
