import Foundation

/// Handles the "LOCK <DO> WITH <IO>" command.
public struct LockActionHandler: EnhancedActionHandler {

    public init() {}

    // MARK: - EnhancedActionHandler

    public func validate(
        command: Command,
        engine: GameEngine
    ) async throws {
        // 1. Validate command structure: Need DO and IO
        guard command.directObject != nil else {
            throw ActionError.prerequisiteNotMet("Lock what?")
        }
        guard command.indirectObject != nil else {
            throw ActionError.prerequisiteNotMet("Lock it with what?")
        }

        // Safely unwrap IDs after checks
        let targetItemID = command.directObject!
        let keyItemID = command.indirectObject!

        // 2. Get item snapshots
        guard let targetItem = await engine.item(with: targetItemID) else {
            // If parser resolved it but it's gone now, treat as inaccessible.
            throw ActionError.itemNotAccessible(targetItemID)
        }
        guard let keyItem = await engine.item(with: keyItemID) else {
            throw ActionError.itemNotAccessible(keyItemID)
        }

        // 3. Check reachability
        guard keyItem.parent == .player else {
            throw ActionError.itemNotHeld(keyItemID)
        }
        let reachableItems = await engine.scopeResolver.itemsReachableByPlayer()
        guard reachableItems.contains(targetItemID) else {
            throw ActionError.itemNotAccessible(targetItemID)
        }

        // 4. Check item properties
        guard targetItem.hasProperty(.lockable) else {
            throw ActionError.itemNotLockable(targetItemID)
        }
        guard !targetItem.hasProperty(.locked) else {
            // Don't throw, let process handle the message
            return
        }

        // 5. Check if it's the correct key
        guard targetItem.lockKey == keyItemID else {
            throw ActionError.wrongKey(keyID: keyItemID, lockID: targetItemID)
        }
    }

    public func process(
        command: Command,
        engine: GameEngine
    ) async throws -> ActionResult {
        // IDs are guaranteed non-nil by validate
        let targetItemID = command.directObject!
        let keyItemID = command.indirectObject!

        // Get snapshots (needed for properties)
        // Existence guaranteed by validate
        guard let targetItem = await engine.item(with: targetItemID),
              let keyItem = await engine.item(with: keyItemID) else
        {
            throw ActionError.internalEngineError("Item snapshot disappeared between validate and process for LOCK.")
        }

        // Handle case: Already locked (detected in validate)
        if targetItem.hasProperty(.locked) {
            // Manually construct definite article message
            return ActionResult(success: false, message: "The \(targetItem.name) is already locked.")
        }

        // --- Lock Successful: Calculate State Changes ---
        var stateChanges: [StateChange] = []

        // Change 1: Add .locked to target
        let oldTargetProps = targetItem.properties
        var newTargetProps = oldTargetProps
        newTargetProps.insert(.locked)
        newTargetProps.insert(.touched) // Also mark target touched

        if oldTargetProps != newTargetProps {
            let targetPropsChange = StateChange(
                entityId: .item(targetItemID),
                propertyKey: .itemProperties,
                oldValue: .itemProperties(oldTargetProps),
                newValue: .itemProperties(newTargetProps)
            )
            stateChanges.append(targetPropsChange)
        }

        // Change 2: Add .touched to key (if needed)
        let oldKeyProps = keyItem.properties
        if !oldKeyProps.contains(.touched) {
            var newKeyProps = oldKeyProps
            newKeyProps.insert(.touched)
            let keyPropsChange = StateChange(
                entityId: .item(keyItemID),
                propertyKey: .itemProperties,
                oldValue: .itemProperties(oldKeyProps),
                newValue: .itemProperties(newKeyProps)
            )
            stateChanges.append(keyPropsChange)
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
