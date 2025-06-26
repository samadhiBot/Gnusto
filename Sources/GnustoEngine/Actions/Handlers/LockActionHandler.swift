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

    public init() {}

    /// Processes the "LOCK" command.
    ///
    /// This action validates prerequisites and handles locking items using keys.
    /// Checks that both items exist, the key is held, the target is lockable,
    /// not already locked, and the correct key is being used.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Validate command structure: Need direct object
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

        // Get target item and validate it's lockable
        let targetItem = try await engine.item(targetItemID)
        guard targetItem.hasFlag(.isLockable) else {
            throw ActionResponse.itemNotLockable(targetItemID)
        }

        // Check if target is accessible
        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // Check if already locked
        if targetItem.hasFlag(.isLocked) {
            return ActionResult(
                engine.messenger.alreadyLocked(
                    item: targetItem.withDefiniteArticle.capitalizedFirst
                )
            )
        }

        // Handle key validation (if indirect object provided)
        if let indirectObjectRef = command.indirectObject {
            guard case .item(let keyItemID) = indirectObjectRef else {
                throw ActionResponse.prerequisiteNotMet(
                    engine.messenger.canOnlyUseItemAsKey()
                )
            }

            let keyItem = try await engine.item(keyItemID)

            // Check if player is holding the key
            guard keyItem.parent == .player else {
                throw ActionResponse.itemNotHeld(keyItemID)
            }

            // Check if it's the correct key
            guard targetItem.attributes[.lockKey] == .itemID(keyItemID) else {
                throw ActionResponse.wrongKey(keyID: keyItemID, lockID: targetItemID)
            }

            // Lock with key
            return ActionResult(
                engine.messenger.lockSuccess(item: targetItem.withDefiniteArticle),
                await engine.setFlag(.isLocked, on: targetItem),
                await engine.setFlag(.isTouched, on: targetItem),
                await engine.setFlag(.isTouched, on: keyItem),
                await engine.updatePronouns(to: targetItem)
            )
        } else {
            // No key specified - check if item requires a key
            if targetItem.attributes[.lockKey] != nil {
                throw ActionResponse.prerequisiteNotMet(
                    engine.messenger.lockWithWhat(item: targetItem.withDefiniteArticle)
                )
            } else {
                // Item doesn't require a key (manual lock)
                return ActionResult(
                    engine.messenger.lockSuccess(item: targetItem.withDefiniteArticle),
                    await engine.setFlag(.isLocked, on: targetItem),
                    await engine.setFlag(.isTouched, on: targetItem),
                    await engine.updatePronouns(to: targetItem)
                )
            }
        }
    }
}
