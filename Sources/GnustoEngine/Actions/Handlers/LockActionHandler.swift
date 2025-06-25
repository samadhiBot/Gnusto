import Foundation

/// Handles the "LOCK <direct object> WITH <indirect object>" command, allowing the player
/// to lock a lockable item using a key.
public struct LockActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb, .directObject, .with, .indirectObject),
    ]

    public let verbs: [VerbID] = [.lock]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    /// Validates the "LOCK" command.
    ///
    /// This method ensures that:
    /// 1. Both a direct object (the item to lock) and an indirect object (the key)
    ///    are specified and are valid items.
    /// 2. The key item is currently held by the player.
    /// 3. The player can reach the item to be locked.
    /// 4. The target item has the `.isLockable` flag set.
    /// 5. The target item does not already have the `.isLocked` flag set (it's not already locked).
    ///    If it is already locked, validation passes, and `process` will handle the message.
    /// 6. The key item matches the `.lockKey` attribute of the target item.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails, such as:
    ///           `prerequisiteNotMet` (for missing objects or wrong item types),
    ///           `itemNotHeld` (if key is not held),
    ///           `itemNotAccessible` (if target cannot be reached),
    ///           `itemNotLockable` (if target is not lockable),
    ///           `wrongKey` (if the key doesn't match).
    ///           Can also throw errors from `engine.item()`.
        public func process(
        command: Command,
        engine: GameEngine
    ) async throws -> ActionResult {

        // 1. Validate command structure: Need DO and IO, both must be items
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.thatsNotSomethingYouCan(.lock)
            )
        }
        let targetItem = try await engine.item(targetItemID)

        guard let indirectObjectRef = command.indirectObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.lockWithWhat(item: targetItem.withDefiniteArticle)
            )
        }
        guard case .item(let keyItemID) = indirectObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.canOnlyUseItemAsKey()
            )
        }

        // 2. Get item snapshots (existence should be implicitly validated by parser/scope resolver before this point)
        // If items don't exist, engine.item() will throw, which is an acceptable failure.
        // Alternatively, could add explicit unknownEntity checks here if desired.
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
    /// Processes the "LOCK" command.
    ///
    /// This action performs the following:
    /// 1. Retrieves the target item and the key item.
    /// 2. If the target item is already locked (checked via its `.isLocked` flag), an
    ///    `ActionResult` with the message "The [item name] is already locked." is returned,
    ///    and no state changes occur.
    /// 3. If the item is not already locked (validation ensures it's lockable and the correct
    ///    key is being used):
    ///    a. Sets the `.isLocked` flag on the target item.
    ///    b. Ensures the `.isTouched` flag is set on both the target item and the key item.
    ///    c. Updates pronouns to refer to the target item.
    ///    d. Returns an `ActionResult` with a confirmation message (e.g., "The wooden door is now locked.")
    ///       and the state changes.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing the message and relevant state changes.
    /// - Throws: `ActionResponse.internalEngineError` if direct or indirect objects are not items
    ///           (this should be caught by `validate`), or errors from `engine.item()`.
        // Direct and Indirect objects are guaranteed to be items by validate.
        guard let directObjectRef = command.directObject,
            case .item(let targetItemID) = directObjectRef
        else {
            throw ActionResponse.internalEngineError("Lock: Direct object not an item in process.")
        }
        guard let indirectObjectRef = command.indirectObject,
            case .item(let keyItemID) = indirectObjectRef
        else {
            throw ActionResponse.internalEngineError(
                "Lock: Indirect object not an item in process.")
        }

        let targetItem = try await engine.item(targetItemID)
        let keyItem = try await engine.item(keyItemID)

        // Handle case: Already locked (validation allows this to pass through).
        if targetItem.hasFlag(.isLocked) {
            let message = engine.messenger.alreadyLocked(
                item: targetItem.withDefiniteArticle.capitalizedFirst
            )
            return ActionResult(message)
        }

        return ActionResult(
            engine.messenger.lockSuccess(item: targetItem.withDefiniteArticle),
            await engine.setFlag(.isLocked, on: targetItem),
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.setFlag(.isTouched, on: keyItem),
            await engine.updatePronouns(to: targetItem)
        )
    }

    // Default postProcess will print the message
}
