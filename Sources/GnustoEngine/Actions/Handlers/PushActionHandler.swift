import Foundation

/// Handles the "PUSH" command and its synonyms (e.g., "PRESS", "SHOVE"), allowing the player
/// to push objects.
public struct PushActionHandler: ActionHandler {
    /// Validates the "PUSH" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (the player must indicate *what* to push).
    /// 2. The direct object refers to an existing item that the player can reach.
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
            throw ActionResponse.prerequisiteNotMet("Push what?")
        }
        
        // For single object commands, validate the single object
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet("Push what?")
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can only push items.")
        }

        // 2. Check if item exists
        _ = try await context.engine.item(targetItemID)

        // 3. Check reachability
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    }

    /// Processes the "PUSH" command.
    ///
    /// For each item to be pushed:
    /// 1. Checks if the player can reach the item
    /// 2. Updates touched flags and pronouns
    /// 3. Provides appropriate feedback (typically "Nothing happens")
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing a message and any relevant `StateChange`s.
    public func process(context: ActionContext) async throws -> ActionResult {
        // For ALL commands, empty directObjects is valid (means nothing to push)
        if !context.command.isAllCommand {
            guard !context.command.directObjects.isEmpty else {
                return ActionResult("Push what?")
            }
        }
        
        var allStateChanges: [StateChange] = []
        var pushedItems: [Item] = []
        var lastPushedItem: Item?
        
        // Process each object individually
        for directObjectRef in context.command.directObjects {
            guard case .item(let targetItemID) = directObjectRef else {
                if context.command.isAllCommand {
                    continue // Skip non-items in ALL commands
                } else {
                    return ActionResult("You can only push items.")
                }
            }
            
            do {
                let targetItem = try await context.engine.item(targetItemID)
                
                // Validate this specific item for ALL commands
                if context.command.isAllCommand {
                    // Check if player can reach the item
                    guard await context.engine.playerCanReach(targetItemID) else {
                        continue // Skip unreachable items in ALL commands
                    }
                }
                
                // --- Calculate State Changes for this item ---
                var itemStateChanges: [StateChange] = []

                // Change 1: Set `.isTouched` flag if not already set
                if let touchedChange = await context.engine.setFlag(.isTouched, on: targetItem) {
                    itemStateChanges.append(touchedChange)
                }

                allStateChanges.append(contentsOf: itemStateChanges)
                pushedItems.append(targetItem)
                lastPushedItem = targetItem
                
            } catch {
                // For ALL commands, skip items that cause errors
                if !context.command.isAllCommand {
                    throw error
                }
            }
        }
        
        // Update pronouns appropriately for multiple objects
        if let lastItem = lastPushedItem {
            if pushedItems.count > 1 {
                // For multiple items, update both "it" and "them"
                let pronounChanges = await context.engine.updatePronounsForMultipleObjects(
                    lastItem: lastItem,
                    allItems: pushedItems
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
        let message = if pushedItems.isEmpty {
            context.command.isAllCommand ? "There is nothing here to push." : "Push what?"
        } else {
            "You push \(pushedItems.listWithDefiniteArticles). Nothing happens."
        }
        
        return ActionResult(
            message: message,
            stateChanges: allStateChanges
        )
    }
} 
