import Foundation

/// Handles the "DROP" command and its synonyms (e.g., "PUT DOWN"), allowing the player
/// to remove an item from their inventory and place it in the current location.
public struct DropActionHandler: ActionHandler {
    /// Validates the "DROP" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (the player must indicate *what* to drop).
    /// 2. The direct object refers to an existing item.
    /// 3. The player is currently holding the item.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails, such as:
    ///           `prerequisiteNotMet` (for missing object or wrong item type),
    ///           `itemNotHeld` (if the player isn't holding the item).
    ///           Can also throw errors from `context.engine.item()`.
    public func validate(context: ActionContext) async throws {
        // For ALL commands, allow empty directObjects (handled in process method)
        if context.command.isAllCommand {
            return
        }
        
        // 1. Ensure we have at least one direct object for non-ALL commands
        guard !context.command.directObjects.isEmpty else {
            throw ActionResponse.prerequisiteNotMet("Drop what?")
        }
        
        // For single object commands, validate the single object
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet("Drop what?")
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can only drop items.")
        }

        // 2. Check if item exists and is held by player
        let targetItem = try await context.engine.item(targetItemID)
        guard targetItem.parent == .player else {
            throw ActionResponse.itemNotHeld(targetItemID)
        }
        
        // 3. Check if item is droppable (not scenery/fixed)
        guard !targetItem.hasFlag(.isScenery) else {
            throw ActionResponse.itemNotDroppable(targetItemID)
        }
        
        // 3. Check if item is droppable (not scenery/fixed)
        guard !targetItem.hasFlag(.isScenery) else {
            throw ActionResponse.itemNotDroppable(targetItemID)
        }
    }

    /// Processes the "DROP" command.
    ///
    /// Assuming basic validation has passed, this action performs the following:
    /// 1. Retrieves the target item(s).
    /// 2. Checks if the player is actually holding the item. If not, a message like
    ///    "You aren't holding that." is returned.
    /// 3. If the player is holding the item:
    ///    a. Creates a `StateChange` to move the item to the current location.
    ///    b. Ensures the `.isTouched` flag is set on the item.
    ///    c. Updates pronouns to refer to the dropped item.
    ///    d. Returns a confirmation message, typically "Dropped."
    ///
    /// For ALL commands, processes each object individually and provides consolidated feedback.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing a message and any relevant `StateChange`s.
    /// - Throws: `ActionResponse.internalEngineError` if direct object is not an item (should be
    ///           caught by validate), or errors from `context.engine.item()`.
    public func process(context: ActionContext) async throws -> ActionResult {
        // For ALL commands, empty directObjects is valid (means nothing to drop)
        if !context.command.isAllCommand {
            guard !context.command.directObjects.isEmpty else {
                throw ActionResponse.internalEngineError("Drop: no direct objects in process.")
            }
        }
        
        var allStateChanges: [StateChange] = []
        var droppedItems: [Item] = []
        var lastDroppedItem: Item?
        
        // Get current location for dropping items
        let currentLocationID = await context.engine.gameState.player.currentLocationID
        
        // Process each object individually
        for directObjectRef in context.command.directObjects {
            guard case .item(let targetItemID) = directObjectRef else {
                if context.command.isAllCommand {
                    continue // Skip non-items in ALL commands
                } else {
                    throw ActionResponse.internalEngineError("Drop: directObject was not an item in process.")
                }
            }
            
            do {
                let targetItem = try await context.engine.item(targetItemID)
                
                // Check if player is actually holding this item
                guard targetItem.parent == .player else {
                    if context.command.isAllCommand {
                        continue // Skip items not held in ALL commands
                    } else {
                        return ActionResult("You aren't holding that.")
                    }
                }
                
                // Validate this specific item for ALL commands
                if context.command.isAllCommand {
                    // Check if item is droppable (not scenery/fixed)
                    guard !targetItem.hasFlag(.isScenery) else {
                        continue // Skip non-droppable items in ALL commands
                    }
                }
                
                // Validate this specific item for ALL commands
                if context.command.isAllCommand {
                    // Check if item is droppable (not scenery/fixed)
                    guard !targetItem.hasFlag(.isScenery) else {
                        continue // Skip non-droppable items in ALL commands
                    }
                }
                
                // --- Calculate State Changes for this item ---
                var itemStateChanges: [StateChange] = []

                // Change 1: Move item to current location
                let moveChange = await context.engine.move(targetItem, to: .location(currentLocationID))
                itemStateChanges.append(moveChange)

                // Change 2: Set `.isTouched` flag if not already set
                if let touchedChange = await context.engine.setFlag(.isTouched, on: targetItem) {
                    itemStateChanges.append(touchedChange)
                }

                allStateChanges.append(contentsOf: itemStateChanges)
                droppedItems.append(targetItem)
                lastDroppedItem = targetItem
                
            } catch {
                // For ALL commands, skip items that cause errors
                if !context.command.isAllCommand {
                    throw error
                }
            }
        }
        
        // Update pronouns appropriately for multiple objects
        if let lastItem = lastDroppedItem {
            if droppedItems.count > 1 {
                // For multiple items, update both "it" and "them"
                let pronounChanges = await context.engine.updatePronounsForMultipleObjects(
                    lastItem: lastItem,
                    allItems: droppedItems
                )
                allStateChanges.append(contentsOf: pronounChanges)
            } else {
                // For single item, use the original method
                if let pronounChange = await context.engine.updatePronouns(to: lastItem) {
                    allStateChanges.append(pronounChange)
                }
            }
        }
        
        // Clear .isWorn flag for all dropped items (after pronoun update to match expected order)
        for droppedItem in droppedItems {
            if let wornChange = await context.engine.clearFlag(.isWorn, on: droppedItem) {
                allStateChanges.append(wornChange)
            }
        }
        
        // Generate appropriate message
        let message = if context.command.isAllCommand {
            if droppedItems.isEmpty {
                "You aren't carrying anything."
            } else {
                "You drop \(droppedItems.listWithDefiniteArticles)."
            }
        } else {
            "Dropped."
        }
        
        return ActionResult(
            message: message,
            stateChanges: allStateChanges
        )
    }

    // Rely on default postProcess.
}
