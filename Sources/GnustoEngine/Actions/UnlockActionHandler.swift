import Foundation

/// Handles the "UNLOCK <DO> WITH <IO>" context.command.
public struct UnlockActionHandler: EnhancedActionHandler {

    public init() {}

    // MARK: - EnhancedActionHandler

    public func validate(context: ActionContext) async throws {
        // 1. Validate context.command structure: Need DO and IO
        guard context.command.directObject != nil else {
            throw ActionError.prerequisiteNotMet("Unlock what?")
        }
        guard context.command.indirectObject != nil else {
            throw ActionError.prerequisiteNotMet("Unlock it with what?")
        }

        // Safely unwrap IDs after checks
        let targetItemID = context.command.directObject!
        let keyItemID = context.command.indirectObject!

        // 2. Get item snapshots
        guard let targetItem = await context.engine.item(targetItemID) else {
            throw ActionError.itemNotAccessible(targetItemID)
        }
        guard let keyItem = await context.engine.item(keyItemID) else {
            throw ActionError.itemNotAccessible(keyItemID)
        }

        // 3. Check reachability
        guard keyItem.parent == .player else {
            throw ActionError.itemNotHeld(keyItemID)
        }
        let reachableItems = await context.engine.scopeResolver.itemsReachableByPlayer()
        guard reachableItems.contains(targetItemID) else {
            throw ActionError.itemNotAccessible(targetItemID)
        }

        // 4. Check item properties
        guard targetItem.hasFlag(.isLockable) else {
            throw ActionError.itemNotUnlockable(targetItemID)
        }
        guard targetItem.hasFlag(.isLocked) else {
            // Target is already unlocked. Don't throw, let process handle the message.
            return
        }

        // 5. Check if it's the correct key
        guard targetItem.attributes[.lockKey] == .itemID(keyItemID) else {
            throw ActionError.wrongKey(keyID: keyItemID, lockID: targetItemID)
        }
    }

    public func process(context: ActionContext) async throws -> ActionResult {
        // IDs are guaranteed non-nil by validate
        let targetItemID = context.command.directObject!
        let keyItemID = context.command.indirectObject!

        // Get snapshots (existence guaranteed by validate)
        guard let targetItem = await context.engine.item(targetItemID),
              let keyItem = await context.engine.item(keyItemID) else
        {
            throw ActionError.internalEngineError("Item snapshot disappeared between validate and process for UNLOCK.")
        }

        // Handle case: Already unlocked (detected in validate)
        if !targetItem.hasFlag(.isLocked) {
            // Manually construct definite article message
            return ActionResult(success: false, message: "The \(targetItem.name) is already unlocked.")
        }

        // --- Unlock Successful: Calculate State Changes ---
        var stateChanges: [StateChange] = []

        // Change 1: Remove .locked from target (if currently locked)
        if targetItem.attributes[.isLocked] == true {
            let lockedChange = StateChange(
                entityId: .item(targetItemID),
                attributeKey: .itemAttribute(.isLocked),
                oldValue: true,
                newValue: false
            )
            stateChanges.append(lockedChange)
        }

        // Change 2: Add .touched to target (if not already set)
        if targetItem.attributes[.isTouched] != true {
            let targetTouchedChange = StateChange(
                entityId: .item(targetItemID),
                attributeKey: .itemAttribute(.isTouched),
                oldValue: targetItem.attributes[.isTouched] ?? false,
                newValue: true,
            )
            stateChanges.append(targetTouchedChange)
        }

        // Change 3: Add .touched to key (if not already set)
        if keyItem.attributes[.isTouched] != true {
            let keyTouchedChange = StateChange(
                entityId: .item(keyItemID),
                attributeKey: .itemAttribute(.isTouched),
                oldValue: keyItem.attributes[.isTouched] ?? false,
                newValue: true,
            )
            stateChanges.append(keyTouchedChange)
        }

        // --- Prepare Result ---
        // Manually construct definite article message
        let message = "The \(targetItem.name) is now unlocked."
        return ActionResult(
            success: true,
            message: message,
            stateChanges: stateChanges
        )
    }

    // Default postProcess will print the message
}
