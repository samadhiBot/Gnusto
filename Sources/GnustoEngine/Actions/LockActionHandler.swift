import Foundation

/// Handles the "LOCK <DO> WITH <IO>" context.command.
public struct LockActionHandler: EnhancedActionHandler {

    public init() {}

    // MARK: - EnhancedActionHandler

    public func validate(context: ActionContext) async throws {
        // 1. Validate context.command structure: Need DO and IO
        guard context.command.directObject != nil else {
            throw ActionError.prerequisiteNotMet("Lock what?")
        }
        guard context.command.indirectObject != nil else {
            throw ActionError.prerequisiteNotMet("Lock it with what?")
        }

        // Safely unwrap IDs after checks
        let targetItemID = context.command.directObject!
        let keyItemID = context.command.indirectObject!

        // 2. Get item snapshots
        guard let targetItem = await context.engine.item(with: targetItemID) else {
            // If parser resolved it but it's gone now, treat as inaccessible.
            throw ActionError.itemNotAccessible(targetItemID)
        }
        guard let keyItem = await context.engine.item(with: keyItemID) else {
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
        guard targetItem.flag(.isLockable) else {
            throw ActionError.itemNotLockable(targetItemID)
        }
        guard !targetItem.flag(.isLocked) else {
            // Don't throw, let process handle the message
            return
        }

        // 5. Check if it's the correct key
        guard targetItem.lockKey == keyItemID else {
            throw ActionError.wrongKey(keyID: keyItemID, lockID: targetItemID)
        }
    }

    public func process(context: ActionContext) async throws -> ActionResult {
        // IDs are guaranteed non-nil by validate
        let targetItemID = context.command.directObject!
        let keyItemID = context.command.indirectObject!

        // Get snapshots (needed for properties)
        // Existence guaranteed by validate
        guard let targetItem = await context.engine.item(with: targetItemID),
              let keyItem = await context.engine.item(with: keyItemID) else
        {
            throw ActionError.internalEngineError("Item snapshot disappeared between validate and process for LOCK.")
        }

        // Handle case: Already locked (detected in validate)
        if targetItem.flag(.isLocked) {
            // Manually construct definite article message
            return ActionResult(success: false, message: "The \(targetItem.name) is already locked.")
        }

        // --- Lock Successful: Calculate State Changes ---
        var stateChanges: [StateChange] = []

        // Change 1: Add .locked to target (if not already set)
        if targetItem.attributes[.isLocked] != .bool(true) {
            let lockedChange = StateChange(
                entityId: .item(targetItemID),
                propertyKey: .itemDynamicValue(key: .isLocked),
                oldValue: targetItem.attributes[.isLocked] ?? .bool(false),
                newValue: .bool(true)
            )
            stateChanges.append(lockedChange)
        }

        // Change 2: Add .touched to target (if not already set)
        if targetItem.attributes[.itemTouched] != .bool(true) {
            let targetTouchedChange = StateChange(
                entityId: .item(targetItemID),
                propertyKey: .itemDynamicValue(key: .itemTouched),
                oldValue: targetItem.attributes[.itemTouched] ?? .bool(false),
                newValue: .bool(true)
            )
            stateChanges.append(targetTouchedChange)
        }

        // Change 3: Add .touched to key (if not already set)
        if keyItem.attributes[.itemTouched] != .bool(true) {
            let keyTouchedChange = StateChange(
                entityId: .item(keyItemID),
                propertyKey: .itemDynamicValue(key: .itemTouched),
                oldValue: keyItem.attributes[.itemTouched] ?? .bool(false),
                newValue: .bool(true)
            )
            stateChanges.append(keyTouchedChange)
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
