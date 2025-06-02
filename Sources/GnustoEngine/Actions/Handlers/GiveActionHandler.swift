import Foundation

/// Handles the "GIVE" command and its synonyms (e.g., "DONATE", "OFFER"), allowing the player
/// to give items to other actors.
public struct GiveActionHandler: ActionHandler {
    /// Validates the "GIVE" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (the player must indicate *what* to give).
    /// 2. An indirect object is specified (the player must indicate *to whom* to give).
    /// 3. The direct object refers to an existing item that the player has.
    /// 4. The indirect object refers to an existing actor.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
    public func validate(context: ActionContext) async throws {
        // For ALL commands, allow empty directObjects (handled in process method)
        if context.command.isAllCommand {
            // Still need an indirect object (recipient)
            guard let indirectObjectRef = context.command.indirectObject else {
                throw ActionResponse.prerequisiteNotMet("Give to whom?")
            }
            guard case .item(let recipientID) = indirectObjectRef else {
                throw ActionResponse.prerequisiteNotMet("You can only give things to people.")
            }
            // Check if recipient exists and is an actor
            let recipient = try await context.engine.item(recipientID)
            guard recipient.hasFlag(.isCharacter) else {
                throw ActionResponse.prerequisiteNotMet("You can only give things to people.")
            }
            return
        }
        
        // 1. Ensure we have at least one direct object for non-ALL commands
        guard !context.command.directObjects.isEmpty else {
            throw ActionResponse.prerequisiteNotMet("Give what?")
        }
        
        // 2. Ensure we have an indirect object
        guard let indirectObjectRef = context.command.indirectObject else {
            throw ActionResponse.prerequisiteNotMet("Give to whom?")
        }
        
        // For single object commands, validate the single object
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet("Give what?")
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can only give items.")
        }
        guard case .item(let recipientID) = indirectObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can only give things to people.")
        }

        // 3. Check if item exists and player has it
        let targetItem = try await context.engine.item(targetItemID)
        guard targetItem.parent == .player else {
            throw ActionResponse.prerequisiteNotMet("You don't have that.")
        }

        // 4. Check if recipient exists and is an actor
        let recipient = try await context.engine.item(recipientID)
        guard recipient.hasFlag(.isCharacter) else {
            throw ActionResponse.prerequisiteNotMet("You can only give things to people.")
        }
        
        // 5. Check if recipient is reachable
        guard await context.engine.playerCanReach(recipientID) else {
            throw ActionResponse.itemNotAccessible(recipientID)
        }
    }

    /// Processes the "GIVE" command.
    ///
    /// For each item to be given:
    /// 1. Checks if the player has the item
    /// 2. Moves the item to the recipient
    /// 3. Updates pronouns and touched flags
    /// 4. Provides appropriate feedback
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing a message and any relevant `StateChange`s.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Get the recipient
        guard let indirectObjectRef = context.command.indirectObject,
              case .item(let recipientID) = indirectObjectRef else {
            return ActionResult("Give to whom?")
        }
        
        let recipient = try await context.engine.item(recipientID)
        
        // For ALL commands, empty directObjects is valid (means nothing to give)
        if !context.command.isAllCommand {
            guard !context.command.directObjects.isEmpty else {
                return ActionResult("Give what?")
            }
        }
        
        var allStateChanges: [StateChange] = []
        var givenItems: [Item] = []
        var lastGivenItem: Item?
        
        // Process each object individually
        for directObjectRef in context.command.directObjects {
            guard case .item(let targetItemID) = directObjectRef else {
                if context.command.isAllCommand {
                    continue // Skip non-items in ALL commands
                } else {
                    return ActionResult("You can only give items.")
                }
            }
            
            do {
                let targetItem = try await context.engine.item(targetItemID)
                
                // Check if player has this item
                guard targetItem.parent == .player else {
                    if context.command.isAllCommand {
                        continue // Skip items not held in ALL commands
                    } else {
                        return ActionResult("You don't have that.")
                    }
                }
                
                // --- Calculate State Changes for this item ---
                var itemStateChanges: [StateChange] = []

                // Change 1: Move item to recipient
                let moveChange = await context.engine.move(targetItem, to: .item(recipientID))
                itemStateChanges.append(moveChange)

                // Change 2: Set `.isTouched` flag if not already set
                if let touchedChange = await context.engine.setFlag(.isTouched, on: targetItem) {
                    itemStateChanges.append(touchedChange)
                }

                allStateChanges.append(contentsOf: itemStateChanges)
                givenItems.append(targetItem)
                lastGivenItem = targetItem
                
            } catch {
                // For ALL commands, skip items that cause errors
                if !context.command.isAllCommand {
                    throw error
                }
            }
        }
        
        // Update pronouns appropriately for multiple objects
        if let lastItem = lastGivenItem {
            if givenItems.count > 1 {
                // For multiple items, update both "it" and "them"
                let pronounChanges = await context.engine.updatePronounsForMultipleObjects(
                    lastItem: lastItem,
                    allItems: givenItems
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
        let message = if givenItems.isEmpty {
            context.command.isAllCommand ? "You have nothing to give." : "You don't have that."
        } else {
            "You give \(givenItems.listWithDefiniteArticles) to the \(recipient.name)."
        }
        
        return ActionResult(
            message: message,
            stateChanges: allStateChanges
        )
    }
} 
