import Foundation

/// Handles the "UNLOCK <direct object> WITH <indirect object>" command, allowing the player
/// to unlock a lockable item using a key.
public struct UnlockActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb, .directObject, .with, .indirectObject),
    ]

    public let synonyms: [Verb] = [.unlock]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "UNLOCK" command.
    ///
    /// This action validates prerequisites and handles unlocking items using keys.
    /// Checks that both items exist, the key is held, the target is lockable,
    /// currently locked, and the correct key is being used.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Validate command structure: Need direct object
        guard let lockedItem = try await context.itemDirectObject() else {
            throw ActionResponse.doWhat(context)
        }

        // Validate it's lockable
        guard await lockedItem.hasFlags(any: .isLocked, .isLockable) else {
            throw ActionResponse.feedback(
                context.msg.thatsNotSomethingYouCan(context.command)
            )
        }

        // Check if currently locked
        guard await lockedItem.hasFlag(.isLocked) else {
            throw await ActionResponse.feedback(
                context.msg.alreadyDone(
                    context.command,
                    item: lockedItem.withDefiniteArticle
                )
            )
        }

        // Check whether item requires a key (manual unlock)
        guard case .itemID(let lockKeyID) = await lockedItem.property(.lockKey) else {
            return await ActionResult(
                context.msg.itemIsNowUnlocked(lockedItem.withDefiniteArticle),
                lockedItem.clearFlag(.isLocked),
                lockedItem.setFlag(.isTouched)
            )
        }

        // Handle key validation (if indirect object provided)
        guard let key = try await context.itemIndirectObject() else {
            throw await ActionResponse.feedback(
                context.msg.doWithWhat(
                    context.command,
                    item: lockedItem.withDefiniteArticle
                )
            )
        }

        // Check if player is holding the key
        guard await key.playerIsHolding else {
            throw ActionResponse.itemNotHeld(key)
        }

        // Validate that it's the correct key
        guard key.id == lockKeyID else {
            throw await ActionResponse.feedback(
                context.msg.wrongKey(
                    key.withDefiniteArticle,
                    lock: lockedItem.withDefiniteArticle
                )
            )
        }

        // Unlock the locked item with the key
        return await ActionResult(
            context.msg.itemIsNowUnlocked(lockedItem.withDefiniteArticle),
            lockedItem.clearFlag(.isLocked),
            lockedItem.setFlag(.isTouched),
            key.setFlag(.isTouched)
        )
    }
}
