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

    public init() {}

    /// Processes the "UNLOCK" command.
    ///
    /// This action validates prerequisites and handles unlocking items using keys.
    /// Checks that both items exist, the key is held, the target is lockable,
    /// currently locked, and the correct key is being used.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Validate command structure: Need direct object
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

        // Get target item and validate it's lockable
        let targetItem = try await engine.item(targetItemID)
        guard targetItem.hasFlag(.isLockable) else {
            throw ActionResponse.itemNotUnlockable(targetItemID)
        }

        // Check if target is accessible
        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // Check if currently locked
        guard targetItem.hasFlag(.isLocked) else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.unlockAlreadyUnlocked(item: targetItem.name)
            )
        }

        // Handle key validation (if indirect object provided)
        if let indirectObjectRef = command.indirectObject {
            guard case .item(let keyItemID) = indirectObjectRef else {
                throw ActionResponse.prerequisiteNotMet(
                    engine.messenger.thatsNotSomethingYouCanUseAsKey()
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

            // Unlock with key
            return ActionResult(
                engine.messenger.itemIsNowUnlocked(item: targetItem.withDefiniteArticle),
                await engine.clearFlag(.isLocked, on: targetItem),
                await engine.setFlag(.isTouched, on: targetItem),
                await engine.setFlag(.isTouched, on: keyItem),
                await engine.updatePronouns(to: targetItem, keyItem)
            )
        } else {
            // No key specified - check if item requires a key
            if targetItem.attributes[.lockKey] != nil {
                throw ActionResponse.prerequisiteNotMet(
                    engine.messenger.unlockWithWhat(item: targetItem.withDefiniteArticle)
                )
            } else {
                // Item doesn't require a key (manual unlock)
                return ActionResult(
                    engine.messenger.itemIsNowUnlocked(item: targetItem.withDefiniteArticle),
                    await engine.clearFlag(.isLocked, on: targetItem),
                    await engine.setFlag(.isTouched, on: targetItem),
                    await engine.updatePronouns(to: targetItem)
                )
            }
        }
    }
}
