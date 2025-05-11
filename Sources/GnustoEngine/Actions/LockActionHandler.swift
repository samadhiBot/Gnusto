import Foundation

/// Handles the "LOCK <DO> WITH <IO>" context.command.
public struct LockActionHandler: ActionHandler {
    public func validate(context: ActionContext) async throws {
        // 1. Validate context.command structure: Need DO and IO
        guard context.command.directObject != nil else {
            throw ActionResponse.prerequisiteNotMet("Lock what?")
        }
        guard context.command.indirectObject != nil else {
            throw ActionResponse.prerequisiteNotMet("Lock it with what?")
        }

        // Safely unwrap IDs after checks
        let targetItemID = context.command.directObject!
        let keyItemID = context.command.indirectObject!

        // 2. Get item snapshots
        guard let targetItem = await context.engine.item(targetItemID) else {
            // If parser resolved it but it's gone now, treat as inaccessible.
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
        guard let keyItem = await context.engine.item(keyItemID) else {
            throw ActionResponse.itemNotAccessible(keyItemID)
        }

        // 3. Check reachability
        guard keyItem.parent == .player else {
            throw ActionResponse.itemNotHeld(keyItemID)
        }
        let reachableItems = await context.engine.scopeResolver.itemsReachableByPlayer()
        guard reachableItems.contains(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // 4. Check item properties
        guard targetItem.hasFlag(.isLockable) else {
            throw ActionResponse.itemNotLockable(targetItemID)
        }
        guard !targetItem.hasFlag(.isLocked) else {
            // Don't throw, let process handle the message
            return
        }

        // 5. Check if it's the correct key
        guard targetItem.attributes[.lockKey] == .itemID(keyItemID) else {
            throw ActionResponse.wrongKey(keyID: keyItemID, lockID: targetItemID)
        }
    }

    public func process(context: ActionContext) async throws -> ActionResult {
        guard
            let targetItemID = context.command.directObject,
            let keyItemID = context.command.indirectObject,
            let targetItem = await context.engine.item(targetItemID),
            let keyItem = await context.engine.item(keyItemID)
        else {
            throw ActionResponse.internalEngineError(
                "Missing directObject or indirectObject in LOCK context.command."
            )
        }

        // Handle case: Already locked (detected in validate)
        if targetItem.hasFlag(.isLocked) {
            // Manually construct definite article message
            return ActionResult(
                success: false,
                message: "The \(targetItem.name) is already locked."
            )
        }

        // --- Lock Successful: Calculate State Changes ---
        var stateChanges: [StateChange] = []

        // Change 1: Add .locked to target (if not already set)
        if targetItem.attributes[.isLocked] != true {
            let lockedChange = StateChange(
                entityID: .item(targetItemID),
                attributeKey: .itemAttribute(.isLocked),
                oldValue: targetItem.attributes[.isLocked] ?? false,
                newValue: true,
            )
            stateChanges.append(lockedChange)
        }

        // Change 2: Add .touched to target (if not already set)
        if let addTouchedFlag = await context.engine.flag(targetItem, with: .isTouched) {
            stateChanges.append(addTouchedFlag)
        }

        // Change 3: Add .touched to key (if not already set)
        if let addTouchedFlag = await context.engine.flag(keyItem, with: .isTouched) {
            stateChanges.append(addTouchedFlag)
        }

        // Change 4: Update pronoun
        if let updatePronoun = await context.engine.updatePronouns(to: targetItem) {
            stateChanges.append(updatePronoun)
        }

        // --- Prepare Result ---
        // Manually construct definite article message
        let message = "The \(targetItem.name) is now locked."
        return ActionResult(
            success: true,
            message: message,
            stateChanges: stateChanges
        )
    }

    // Default postProcess will print the message
}
