import Foundation
import GnustoEngine

/// Handles the "LOCK <DO> WITH <IO>" command.
public struct LockActionHandler: ActionHandler {

    public init() {}

    public func perform(command: Command, engine: GameEngine) async throws {
        // 1. Validate command structure: Need DO and IO
        guard let targetItemID = command.directObject else {
            await engine.output("Lock what?")
            return
        }
        guard let keyItemID = command.indirectObject else {
            await engine.output("Lock it with what?")
            return
        }

        // 2. Get item snapshots
        guard let targetItem = await engine.itemSnapshot(with: targetItemID) else {
            throw ActionError.internalEngineError("Parser resolved non-existent target item ID '\(targetItemID)'.")
        }
        guard let keyItem = await engine.itemSnapshot(with: keyItemID) else {
            throw ActionError.internalEngineError("Parser resolved non-existent key item ID '\(keyItemID)'.")
        }

        // 3. Check reachability (player must hold the key)
        guard keyItem.parent == .player else {
            throw ActionError.itemNotHeld(keyItemID)
        }
        // Target item must be reachable (held or in location)
        let reachableItems = await engine.scopeResolver.itemsReachableByPlayer()
        guard reachableItems.contains(targetItemID) else {
            throw ActionError.itemNotAccessible(targetItemID)
        }

        // Mark items as touched
        await engine.addItemProperty(itemID: targetItemID, property: .touched)
        await engine.addItemProperty(itemID: keyItemID, property: .touched)

        // 4. Check item properties
        guard targetItem.hasProperty(.lockable) else {
            throw ActionError.itemNotLockable(targetItemID)
        }
        guard !targetItem.hasProperty(.locked) else {
            throw ActionError.itemIsLocked(targetItemID)
        }

        // 5. Check if it's the correct key
        guard targetItem.lockKey == keyItemID else {
            throw ActionError.wrongKey(keyID: keyItemID, lockID: targetItemID)
        }

        // --- Lock Successful ---

        // 6. Update State
        await engine.addItemProperty(itemID: targetItemID, property: .locked)

        // 7. Output Message
        // Zork: "The <door> is now locked."
        await engine.output("The \(targetItem.name) is now locked.")
    }
}
