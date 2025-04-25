import Foundation

/// Handles the "PUT [item] ON/IN [target]" action.
@MainActor
struct PutActionHandler: ActionHandler {
    func perform(
        command: Command,
        engine: GameEngine
    ) async throws {
        // 1. Validate Direct and Indirect Objects
        guard let itemToPutID = command.directObject else {
            await engine.output("What do you want to put?")
            return // Or throw ActionError.missingDirectObject
        }
        // Fetch direct object name *only* for the potential error message below
        let directObjectName = engine.itemSnapshot(with: itemToPutID)?.name ?? "item"
        guard let targetID = command.indirectObject else {
            await engine.output("Where do you want to put the \(directObjectName)?")
            return // Or throw ActionError.missingIndirectObject
        }

        // 2. Get Item Snapshots
        guard let itemToPut = engine.itemSnapshot(with: itemToPutID) else {
            // Should ideally be caught by parser scope check, but double-check
            throw ActionError.itemNotAccessible(itemToPutID)
        }
        guard let targetItem = engine.itemSnapshot(with: targetID) else {
            throw ActionError.itemNotAccessible(targetID)
        }

        // 3. Perform Basic Checks
        // Check if player holds the item to put
        guard itemToPut.parent == .player else {
            throw ActionError.itemNotHeld(itemToPutID)
        }

        // Check if target is accessible (basic reachability)
        // Note: Parser usually handles scope, but good to double check reachability
        let reachableItems = engine.scopeResolver.itemsReachableByPlayer()
        guard reachableItems.contains(targetID) else {
             throw ActionError.itemNotAccessible(targetID) // Or more specific error if needed
        }

        // Prevent putting item inside/onto itself or its container
        if itemToPutID == targetID {
             throw ActionError.prerequisiteNotMet("You can't put something on or in itself.")
        }
        // Recursive check: is the target inside the item we are putting?
        var currentParent = targetItem.parent
        while case .item(let parentItemID) = currentParent {
            if parentItemID == itemToPutID {
                throw ActionError.prerequisiteNotMet("You can't put the \(targetItem.name) inside the \(itemToPut.name) like that.")
            }
            guard let parentItem = engine.itemSnapshot(with: parentItemID) else { break } // Stop if parent chain breaks
            currentParent = parentItem.parent
        }


        // 4. Determine action based on preposition ("on" vs "in")
        let preposition = command.preposition?.lowercased() ?? "" // Default to "" if nil

        if preposition == "in" || preposition == "into" {
            // --- Handle PUT IN ---
            guard targetItem.hasProperty(.container) else {
                throw ActionError.targetIsNotAContainer(targetID)
            }
            guard targetItem.hasProperty(.open) else {
                throw ActionError.containerIsClosed(targetID)
            }
            // TODO: Add capacity checks if necessary

            // Perform the move
            engine.updateItemParent(itemID: itemToPutID, newParent: .item(targetID))
            engine.updatePronounReference(pronoun: "it", itemID: itemToPutID) // Update "it"
            await engine.output("You put the \(itemToPut.name) in the \(targetItem.name).")

        } else if preposition == "on" || preposition == "onto" {
            // --- Handle PUT ON ---
            guard targetItem.hasProperty(.surface) else {
                throw ActionError.targetIsNotASurface(targetID)
            }
             // TODO: Add capacity checks if necessary

            // Perform the move
            engine.updateItemParent(itemID: itemToPutID, newParent: .item(targetID))
            engine.updatePronounReference(pronoun: "it", itemID: itemToPutID) // Update "it"
            await engine.output("You put the \(itemToPut.name) on the \(targetItem.name).")

        } else {
            // Invalid or missing preposition
            // TODO: Improve error message? ZIL might infer based on target type.
            await engine.output("Do you want to put it 'in' or 'on' the \(targetItem.name)?")
            // Or throw ActionError.badGrammar("Specify 'in' or 'on'.")
        }
    }
}
