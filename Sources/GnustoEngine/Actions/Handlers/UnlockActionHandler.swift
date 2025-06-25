import Foundation

/// Handles the "UNLOCK <direct object> WITH <indirect object>" command, allowing the player
/// to unlock a lockable item using a key.
public struct UnlockActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb, .directObject, .with, .indirectObject),
    ]

    public let verbs: [VerbID] = [.unlock]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    /// Validates the "UNLOCK" command.
    ///
    /// This method ensures that:
    /// 1. Both a direct object (the item to unlock) and an indirect object (the key)
    ///    are specified and are valid items.
    /// 2. The key item is currently held by the player.
    /// 3. The player can reach the item to be unlocked.
    /// 4. The target item has the `.isLockable` flag set.
    /// 5. The target item currently has the `.isLocked` flag set (it's not already unlocked).
    /// 6. The key item matches the `.lockKey` attribute of the target item.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails, such as:
    ///           `prerequisiteNotMet` (for missing objects, wrong item types, or already unlocked),
    ///           `itemNotHeld` (if key is not held),
    ///           `itemNotAccessible` (if target cannot be reached),
    ///           `itemNotUnlockable` (if target is not lockable),
    ///           `wrongKey` (if the key doesn't match).
    ///           Can also throw errors from `engine.item()`.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {

        // 1. Validate command structure: Need DO and IO, both must be items
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.thatsNotSomethingYouCan(.unlock)
            )
        }
        let targetItem = try await engine.item(targetItemID)

        guard let indirectObjectRef = command.indirectObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.unlockWithWhat(item: targetItem.withDefiniteArticle)
            )
        }
        guard case .item(let keyItemID) = indirectObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.thatsNotSomethingYouCanUseAsKey()
            )
        }
        let keyItem = try await engine.item(keyItemID)

        // 3. Check reachability
        guard keyItem.parent == .player else {
            throw ActionResponse.itemNotHeld(keyItemID)
        }

        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // 4. Check item properties
        guard targetItem.hasFlag(.isLockable) else {
            throw ActionResponse.itemNotUnlockable(targetItemID)
        }

        guard targetItem.hasFlag(.isLocked) else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.unlockAlreadyUnlocked(item: targetItem.name)
            )
        }

        // 5. Check if it's the correct key
        guard targetItem.attributes[.lockKey] == .itemID(keyItemID) else {
            throw ActionResponse.wrongKey(keyID: keyItemID, lockID: targetItemID)
        }
    /// Processes the "UNLOCK" command.
    ///
    /// Assuming validation has passed (correct key, lockable and locked item, etc.),
    /// this action performs the following:
    /// 1. Retrieves the target item and the key item.
    /// 2. Clears the `.isLocked` flag on the target item.
    /// 3. Ensures the `.isTouched` flag is set on both the target item and the key item.
    /// 4. Updates pronouns to refer to the target item and the key.
    /// 5. Returns an `ActionResult` with a confirmation message (e.g., "The wooden door is now unlocked.")
    ///    and the state changes.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing the message and relevant state changes.
    /// - Throws: `ActionResponse.internalEngineError` if direct or indirect objects are not items
    ///           (this should be caught by `validate`), or errors from `engine.item()`.
        // Direct and Indirect objects are guaranteed to be items by validate.
        guard let directObjectRef = command.directObject,
            case .item(let targetItemID) = directObjectRef
        else {
            throw ActionResponse.internalEngineError(
                "Unlock: Direct object not an item in process.")
        }
        guard let indirectObjectRef = command.indirectObject,
            case .item(let keyItemID) = indirectObjectRef
        else {
            throw ActionResponse.internalEngineError(
                "Unlock: Indirect object not an item in process."
            )
        }

        // Get snapshots (existence guaranteed by validate)
        let targetItem = try await engine.item(targetItemID)
        let keyItem = try await engine.item(keyItemID)

        // Validation ensures the item was locked, so no need to check again here.

        return ActionResult(
            engine.messenger.itemIsNowUnlocked(item: targetItem.withDefiniteArticle),
            await engine.clearFlag(.isLocked, on: targetItem),
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.setFlag(.isTouched, on: keyItem),
            await engine.updatePronouns(to: targetItem, keyItem)
        )
    }

    // Default postProcess will print the message
}
