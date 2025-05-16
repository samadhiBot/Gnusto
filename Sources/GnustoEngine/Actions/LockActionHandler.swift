import Foundation

/// Handles the "LOCK <DO> WITH <IO>" context.command.
public struct LockActionHandler: ActionHandler {
    public func validate(context: ActionContext) async throws {
        // 1. Validate command structure: Need DO and IO, both must be items
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet("Lock what?")
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can only lock items.")
        }

        guard let indirectObjectRef = context.command.indirectObject else {
            throw ActionResponse.prerequisiteNotMet("Lock it with what?")
        }
        guard case .item(let keyItemID) = indirectObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can only use an item as a key.")
        }

        // 2. Get item snapshots (existence should be implicitly validated by parser/scope resolver before this point)
        // If items don't exist, engine.item() will throw, which is an acceptable failure.
        // Alternatively, could add explicit unknownEntity checks here if desired.
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
        // Direct and Indirect objects are guaranteed to be items by validate.
        guard let directObjectRef = context.command.directObject,
              case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.internalEngineError("Lock: Direct object not an item in process.")
        }
        guard let indirectObjectRef = context.command.indirectObject,
              case .item(let keyItemID) = indirectObjectRef else {
            throw ActionResponse.internalEngineError("Lock: Indirect object not an item in process.")
        }

        let targetItem = try await context.engine.item(targetItemID)
        let keyItem = try await context.engine.item(keyItemID)

        // Handle case: Already locked (detected in validate)
        if targetItem.hasFlag(.isLocked) {
            return ActionResult("The \(targetItem.name) is already locked.")
        }

        // --- Lock Successful: Calculate State Changes ---
        var stateChanges: [StateChange] = []

        // Change 1: Add .locked to target (if not already set)
        if let update = await context.engine.setFlag(.isLocked, on: targetItem) {
            stateChanges.append(update)
        }

        // Change 2: Add .touched to target (if not already set)
        if let update = await context.engine.setFlag(.isTouched, on: targetItem) {
            stateChanges.append(update)
        }

        // Change 3: Add .touched to key (if not already set)
        if let update = await context.engine.setFlag(.isTouched, on: keyItem) {
            stateChanges.append(update)
        }

        // Change 4: Update pronoun
        if let update = await context.engine.updatePronouns(to: targetItem) {
            stateChanges.append(update)
        }

        // --- Prepare Result ---
        let message = "The \(targetItem.name) is now locked."

        return ActionResult(
            message: message,
            stateChanges: stateChanges
        )
    }

    // Default postProcess will print the message
}
