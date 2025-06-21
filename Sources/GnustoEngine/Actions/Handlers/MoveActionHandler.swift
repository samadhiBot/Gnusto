import Foundation

/// Handles the "MOVE" command and its synonyms (e.g., "SHIFT", "SLIDE"), allowing the player
/// to move or manipulate objects in the game world. This is typically used for objects that
/// can be moved but not taken, such as moving leaves to reveal something underneath.
public struct MoveActionHandler: ActionHandler {
    /// Validates the "MOVE" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (the player must indicate *what* to move).
    /// 2. The direct object refers to an existing item.
    /// 3. The player can reach the specified item.
    /// 4. The item is not scenery that cannot be moved.
    ///
    /// Note: Unlike TAKE, this does not require the item to be takable, as MOVE
    /// is often used for manipulating objects that are too large or fixed to pick up.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails, such as:
    ///           `prerequisiteNotMet` (for missing object or wrong item type),
    ///           `itemNotAccessible` (if item cannot be reached),
    ///           `itemNotMovable` (if item is fixed scenery).
    ///           Can also throw errors from `context.engine.item()`.
    public func validate(context: ActionContext) async throws {
        // For ALL commands, allow empty directObjects (handled in process method)
        if context.command.isAllCommand {
            return
        }

        // 1. Ensure we have at least one direct object for non-ALL commands
        guard !context.command.directObjects.isEmpty else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.doWhat(verb: .move)
            )
        }

        // For single object commands, validate the single object
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.doWhat(verb: .move)
            )
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.youCanOnlyMoveItems()
            )
        }

        // 2. Check if item exists
        _ = try await context.engine.item(targetItemID)

        // 3. Check reachability using ScopeResolver
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // 4. Check if the item can be moved (not immovable scenery)
        // Some scenery items might be movable (like a pile of leaves), others are not
        // We'll let the process method handle the specific logic for what happens when moved
    }

    /// Processes the "MOVE" command.
    ///
    /// For each item to be moved:
    /// 1. Checks if there's a specific handler for this item (via item events)
    /// 2. If no specific handler, provides default behavior
    /// 3. Updates touched flags and pronouns appropriately
    /// 4. Returns appropriate feedback based on the result
    ///
    /// This action handler is designed to be extensible - specific items can provide
    /// custom move behavior through item event handlers, while this provides the default.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing a message and any relevant `StateChange`s.
    /// - Throws: `ActionResponse.internalEngineError` if direct object is not an item.
    public func process(context: ActionContext) async throws -> ActionResult {
        // For ALL commands, empty directObjects is valid (means nothing to move)
        if !context.command.isAllCommand {
            guard !context.command.directObjects.isEmpty else {
                throw ActionResponse.internalEngineError("Move: no direct objects in process.")
            }
        }

        var allStateChanges: [StateChange] = []
        var movedItems: [Item] = []
        var lastMovedItem: Item?

        // Process each object individually
        for directObjectRef in context.command.directObjects {
            guard case .item(let targetItemID) = directObjectRef else {
                if context.command.isAllCommand {
                    continue  // Skip non-items in ALL commands
                } else {
                    throw ActionResponse.internalEngineError(
                        "Move: directObject was not an item in process.")
                }
            }

            do {
                let targetItem = try await context.engine.item(targetItemID)

                // Validate this specific item for ALL commands
                if context.command.isAllCommand {
                    // Check if player can reach the item
                    guard await context.engine.playerCanReach(targetItemID) else {
                        continue  // Skip unreachable items in ALL commands
                    }
                }

                // --- Check for item-specific move behavior ---
                // TODO: When item event handlers are implemented, check for custom move behavior here

                // --- Default move behavior ---
                var itemStateChanges: [StateChange] = []

                // Change 1: Set `.isTouched` flag if not already set
                if let touchedChange = await context.engine.setFlag(.isTouched, on: targetItem) {
                    itemStateChanges.append(touchedChange)
                }

                allStateChanges.append(contentsOf: itemStateChanges)
                movedItems.append(targetItem)
                lastMovedItem = targetItem

            } catch {
                // For ALL commands, skip items that cause errors
                if !context.command.isAllCommand {
                    throw error
                }
            }
        }

        // Update pronouns appropriately for multiple objects
        if let lastItem = lastMovedItem {
            if movedItems.count > 1 {
                // For multiple items, update both "it" and "them"
                let pronounChanges = await context.engine.updatePronounsForMultipleObjects(
                    lastItem: lastItem,
                    allItems: movedItems
                )
                allStateChanges.append(contentsOf: pronounChanges)
            } else {
                // For single item, use the original method
                if let pronounChange = await context.engine.updatePronouns(to: lastItem) {
                    allStateChanges.append(pronounChange)
                }
            }
        }

        // Generate appropriate message
        let message =
            if context.command.isAllCommand {
                if movedItems.isEmpty {
                    "There is nothing here to move."
                } else {
                    "You move \(movedItems.listWithDefiniteArticles)."
                }
            } else {
                // Default behavior: most things can't be meaningfully moved
                "Moving the \(movedItems.first?.name ?? "item") doesn't accomplish anything."
            }

        return ActionResult(
            message: message,
            changes: allStateChanges
        )
    }

    // Rely on default postProcess.
}
