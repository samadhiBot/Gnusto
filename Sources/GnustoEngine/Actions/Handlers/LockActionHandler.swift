import Foundation

/// Handles the "LOCK <direct object> WITH <indirect object>" command, allowing the player
/// to lock a lockable item using a key.
public struct LockActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb, .directObject, .with, .indirectObject),
    ]

    public let synonyms: [Verb] = [.lock]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "LOCK" command.
    ///
    /// This action validates prerequisites and handles locking items using keys.
    /// Checks that both items exist, the key is held, the target is lockable,
    /// not already locked, and the correct key is being used.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Get direct object (with automatic reachability checking)
        guard let lockItem = try await context.itemDirectObject() else {
            throw ActionResponse.doWhat(context)
        }

        // Validate it's lockable
        guard await lockItem.hasFlag(.isLockable) else {
            throw ActionResponse.cannotDo(context, lockItem)
        }

        // Check if already locked
        if await lockItem.hasFlag(.isLocked) {
            return await ActionResult(
                context.msg.alreadyDone(context.command, item: lockItem.withDefiniteArticle)
            )
        }

        // Handle key validation (if indirect object provided)
        if let keyItem = try await context.itemIndirectObject() {
            // Check if player is holding the key
            guard await keyItem.playerIsHolding else {
                throw ActionResponse.itemNotHeld(keyItem)
            }

            // Check if it's the correct key
            guard
                let lockKeyValue = await lockItem.property(.lockKey),
                case .itemID(let lockKey) = lockKeyValue,
                lockKey == keyItem.id
            else {
                throw await ActionResponse.feedback(
                    context.msg.wrongKey(
                        keyItem.withDefiniteArticle,
                        lock: lockItem.withDefiniteArticle
                    )
                )
            }

            // Lock with key
            return await ActionResult(
                context.msg.lockSuccess(lockItem.withDefiniteArticle),
                lockItem.setFlag(.isLocked),
                lockItem.setFlag(.isTouched),
                keyItem.setFlag(.isTouched)
            )
        } else {
            // No key specified - check if item requires a key
            if await lockItem.property(.lockKey) != nil {
                throw await ActionResponse.feedback(
                    context.msg.doWithWhat(
                        context.command,
                        item: lockItem.withDefiniteArticle
                    )
                )
            } else {
                // Item doesn't require a key (manual lock)
                return await ActionResult(
                    context.msg.lockSuccess(lockItem.withDefiniteArticle),
                    lockItem.setFlag(.isLocked),
                    lockItem.setFlag(.isTouched)
                )
            }
        }
    }
}
