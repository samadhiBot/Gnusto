import Foundation

/// Handles the "TAKE" command and its synonyms (e.g., "GET"), allowing the player to pick up
/// an item and add it to their inventory.
public struct TakeActionHandler: ActionHandler {
    /// Validates the "TAKE" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (the player must indicate *what* to take).
    /// 2. The direct object refers to an existing item.
    /// 3. If the item is inside another item, that parent item must be a container or surface.
    ///    It prevents taking items from non-container/non-surface parents.
    /// 4. If the item is inside a container, and that container is closed and not transparent,
    ///    and the target item hasn't been touched (implying player knows it's there), an error
    ///    for a closed container or general inaccessibility is thrown.
    /// 5. The player can reach the item (general reachability check).
    /// 6. The item has the `.isTakable` flag set.
    /// 7. The player has enough carrying capacity for the item.
    ///
    /// Note: It explicitly *does not* throw an error if the player already has the item;
    /// this case is handled gracefully in the `process` method with a specific message.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails, such as:
    ///           `prerequisiteNotMet`, `unknownEntity`, `itemNotAccessible`, `itemNotTakable`,
    ///           `containerIsClosed`, or `playerCannotCarryMore`.
    ///           Can also throw errors from `context.engine.item()`.
    public func validate(context: ActionContext) async throws {
        // 1. Ensure we have a direct object and it's an item
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet("Take what?")
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can only take items.")
        }

        // 2. Check if item exists
        let targetItem = try await context.engine.item(targetItemID)

        // 3. Check if player already has the item
        if targetItem.parent == .player {
            // Can't throw error here, need to report specific message.
            // Let process handle returning a specific ActionResult for this.
            // This validation passes if already held, process generates the message.
            return
        }

        // 4. Check if item is inside something invalid (non-container/non-surface)
        if case .item(let parentID) = targetItem.parent {
            let parentItem = try await context.engine.item(parentID)

            // Fail only if the parent is NOT a container and NOT a surface.
            // We allow taking from *closed* containers here; reachability handles closed state later.
            let isContainer = parentItem.hasFlag(.isContainer)
            let isSurface = parentItem.hasFlag(.isSurface)
            if !isContainer && !isSurface {
                // Custom message similar to Zork's, using the plain name.
                throw ActionResponse.prerequisiteNotMet("You can't take things out of the \(parentItem.name).")
            }
        }

        // 5. Handle specific container closed errors before general unreachability
        if case .item(let parentID) = targetItem.parent {
            let container = try await context.engine.item(parentID)
            if container.hasFlag(.isContainer) && !container.hasFlag(.isOpen) {
                if targetItem.hasFlag(.isTouched) || container.hasFlag(.isTransparent) {
                    throw ActionResponse.containerIsClosed(parentID)
                } else {
                    throw ActionResponse.itemNotAccessible(targetItemID)
                }
            }
        }

        // 6. Check reachability using ScopeResolver (general check)
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // 7. Check if the item is takable
        guard targetItem.hasFlag(.isTakable) else {
            throw ActionResponse.itemNotTakable(targetItemID)
        }

        // 8. Check capacity <-- Check added here
        guard await context.engine.playerCanCarry(targetItem) else {
            throw ActionResponse.playerCannotCarryMore
        }
    }

    /// Processes the "TAKE" command.
    ///
    /// Assuming basic validation has passed, this action performs the following:
    /// 1. Retrieves the target item.
    /// 2. Checks if the player already has the item. If so, a message "You already have that."
    ///    is returned.
    /// 3. If the player does not have the item:
    ///    a. Creates a `StateChange` to move the item to the player's inventory (`.player` parent).
    ///    b. Ensures the `.isTouched` flag is set on the item.
    ///    c. Updates pronouns to refer to the taken item.
    ///    d. Returns a confirmation message, typically "Taken."
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing a message and any relevant `StateChange`s.
    /// - Throws: `ActionResponse.internalEngineError` if direct object is not an item (should be
    ///           caught by validate), or errors from `context.engine.item()`.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject,
              case .item(let targetItemID) = directObjectRef else {
            // This should ideally be caught by validate.
            throw ActionResponse.internalEngineError("Take: directObject was not an item in process.")
        }
        let targetItem = try await context.engine.item(targetItemID)

        // Handle "already have" case detected (but not thrown) in validate
        if targetItem.parent == .player {
            return ActionResult("You already have that.")
        }

        // --- Calculate State Changes ---
        var stateChanges: [StateChange] = []

        // Change 1: Parent
        let update = await context.engine.move(targetItem, to: .player)
        stateChanges.append(update)

        // Change 2: Set `.isTouched` flag if not already set
        if let update = await context.engine.setFlag(.isTouched, on: targetItem) {
            stateChanges.append(update)
        }

        // Change 3: Pronoun ("it")
        if let update = await context.engine.updatePronouns(to: targetItem) {
            stateChanges.append(update)
        }

        // --- Prepare Result ---
        return ActionResult(
            message: "Taken.",
            stateChanges: stateChanges
        )
    }

    // Rely on default postProcess.
}
