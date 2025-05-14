import Foundation

/// Handles the "UNLOCK <DO> WITH <IO>" context.command.
public struct UnlockActionHandler: ActionHandler {
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

//        // Handle case: Already unlocked (detected in validate)
//        if !targetItem.hasFlag(.isLocked) {
//            // Manually construct definite article message
//            return ActionResult()
//        }

        // --- Unlock Successful: Calculate State Changes ---
        var stateChanges: [StateChange] = []

        // Change 1: Remove .locked from target (if currently locked)
        if let update = await context.engine.flag(targetItem, remove: .isLocked) {
            stateChanges.append(update)
        }

        // Change 2: Add .touched to target (if not already set)
        if let update = await context.engine.flag(targetItem, with: .isTouched) {
            stateChanges.append(update)
        }

        // Change 3: Add .touched to key (if not already set)
        if let update = await context.engine.flag(keyItem, with: .isTouched) {
            stateChanges.append(update)
        }

        // Change 3: Update pronouns
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
