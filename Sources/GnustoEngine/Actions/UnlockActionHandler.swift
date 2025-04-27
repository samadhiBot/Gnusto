import Foundation

/// Handles the "UNLOCK <DO> WITH <IO>" command.
public struct UnlockActionHandler: EnhancedActionHandler {

    public init() {}

    // MARK: - EnhancedActionHandler

    public func validate(
        command: Command,
        engine: GameEngine
    ) async throws {
        // 1. Validate command structure: Need DO and IO
        guard command.directObject != nil else {
            throw ActionError.prerequisiteNotMet("Unlock what?")
        }
        guard command.indirectObject != nil else {
            throw ActionError.prerequisiteNotMet("Unlock it with what?")
        }

        // Safely unwrap IDs after checks
        let targetItemID = command.directObject!
        let keyItemID = command.indirectObject!

        // 2. Get item snapshots
        guard let targetItem = await engine.itemSnapshot(with: targetItemID) else {
            throw ActionError.itemNotAccessible(targetItemID)
        }
        guard let keyItem = await engine.itemSnapshot(with: keyItemID) else {
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
            throw ActionError.itemNotUnlockable(targetItemID)
        }
        guard targetItem.hasProperty(.locked) else {
            // Target is already unlocked. Don't throw, let process handle the message.
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

        // Get snapshots (existence guaranteed by validate)
        guard let targetItemSnapshot = await engine.itemSnapshot(with: targetItemID),
              let keyItemSnapshot = await engine.itemSnapshot(with: keyItemID) else
        {
            throw ActionError.internalEngineError("Item snapshot disappeared between validate and process for UNLOCK.")
        }

        // Handle case: Already unlocked (detected in validate)
        if !targetItemSnapshot.hasProperty(.locked) {
            // Manually construct definite article message
            return ActionResult(success: false, message: "The \(targetItemSnapshot.name) is already unlocked.")
        }

        // --- Unlock Successful: Calculate State Changes ---
        var stateChanges: [StateChange] = []

        // Change 1: Remove .locked from target
        let oldTargetProps = targetItemSnapshot.properties
        var newTargetProps = oldTargetProps
        newTargetProps.remove(.locked)
        newTargetProps.insert(.touched) // Also mark target touched

        if oldTargetProps != newTargetProps {
            let targetPropsChange = StateChange(
                objectId: targetItemID,
                propertyKey: .itemProperties,
                oldValue: .itemProperties(oldTargetProps),
                newValue: .itemProperties(newTargetProps)
            )
            stateChanges.append(targetPropsChange)
        }

        // Change 2: Add .touched to key (if needed)
        let oldKeyProps = keyItemSnapshot.properties
        if !oldKeyProps.contains(.touched) {
            var newKeyProps = oldKeyProps
            newKeyProps.insert(.touched)
            let keyPropsChange = StateChange(
                objectId: keyItemID,
                propertyKey: .itemProperties,
                oldValue: .itemProperties(oldKeyProps),
                newValue: .itemProperties(newKeyProps)
            )
            stateChanges.append(keyPropsChange)
        }

        // --- Prepare Result ---
        // Manually construct definite article message
        let message = "The \(targetItemSnapshot.name) is now unlocked."
        return ActionResult(
            success: true,
            message: message,
            stateChanges: stateChanges
        )
    }

    // Default postProcess will print the message
}
