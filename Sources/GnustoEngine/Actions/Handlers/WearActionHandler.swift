import Foundation

/// Handles the "WEAR" command and its synonyms (e.g., "DON"), allowing the player to
/// equip an item that is wearable.
public struct WearActionHandler: ActionHandler {
    /// Validates the "WEAR" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (the player must indicate *what* to wear).
    /// 2. For single object commands, validates the specific item.
    /// 3. For ALL commands, allows empty directObjects (handled in process method).
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
    public func validate(context: ActionContext) async throws {
        // For ALL commands, allow empty directObjects (handled in process method)
        if context.command.isAllCommand {
            return
        }
        
        // 1. Ensure we have at least one direct object for non-ALL commands
        guard !context.command.directObjects.isEmpty else {
            throw ActionResponse.prerequisiteNotMet("Wear what?")
        }
        
        // For single object commands, validate the single object
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
    /// For each item to be worn:
    /// 1. Checks if the player is holding the item
    /// 2. Checks if the item is wearable and not already worn
    /// 3. Sets the `.isWorn` flag on the item
    /// 4. Updates touched flags and pronouns
    /// 5. Provides appropriate feedback
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing the message and relevant state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        // For ALL commands, empty directObjects is valid (means nothing to wear)
        if !context.command.isAllCommand {
            guard !context.command.directObjects.isEmpty else {
                return ActionResult("Wear what?")
            }
        }
        
        var allStateChanges: [StateChange] = []
        var wornItems: [Item] = []
        var lastWornItem: Item?
        
        // Process each object individually
        for directObjectRef in context.command.directObjects {
            guard case .item(let targetItemID) = directObjectRef else {
                if context.command.isAllCommand {
                    continue // Skip non-items in ALL commands
                } else {
                    return ActionResult("You can only wear items.")
                }
            }
            
            do {
                let targetItem = try await context.engine.item(targetItemID)
                
                // Validate this specific item for ALL commands
                if context.command.isAllCommand {
                    // Check if player is holding the item
                    guard await context.engine.playerIsHolding(targetItemID) else {
                        continue // Skip items not held in ALL commands
                    }
                    
                    // Check if item is wearable
                    guard targetItem.hasFlag(.isWearable) else {
                        continue // Skip non-wearable items in ALL commands
                    }
                    
                    // Check if already worn
                    guard !targetItem.hasFlag(.isWorn) else {
                        continue // Skip already worn items in ALL commands
                    }
                }
                
                // --- Calculate State Changes for this item ---
                var itemStateChanges: [StateChange] = []

                // Change 1: Set .isWorn flag
                if let wornChange = await context.engine.setFlag(.isWorn, on: targetItem) {
                    itemStateChanges.append(wornChange)
                }

                // Change 2: Set .isTouched flag if not already set
                if let touchedChange = await context.engine.setFlag(.isTouched, on: targetItem) {
                    itemStateChanges.append(touchedChange)
                }

                allStateChanges.append(contentsOf: itemStateChanges)
                wornItems.append(targetItem)
                lastWornItem = targetItem
                
            } catch {
                // For ALL commands, skip items that cause errors
                if !context.command.isAllCommand {
                    throw error
                }
            }
        }
        
        // Update pronouns appropriately for multiple objects
        if let lastItem = lastWornItem {
            if wornItems.count > 1 {
                // For multiple items, update both "it" and "them"
                let pronounChanges = await context.engine.updatePronounsForMultipleObjects(
                    lastItem: lastItem,
                    allItems: wornItems
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
        let message = if wornItems.isEmpty {
            context.command.isAllCommand ? "You have nothing to wear." : "Wear what?"
        } else {
            "You put on \(wornItems.listWithDefiniteArticles)."
        }

        return ActionResult(
            message: message,
            stateChanges: allStateChanges
        )
    }
}
