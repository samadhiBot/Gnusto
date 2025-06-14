import Foundation

/// Handles the "READ" command, allowing the player to attempt to read text from an item.
public struct ReadActionHandler: ActionHandler {
    /// Validates the "READ" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (the player must indicate *what* to read).
    /// 2. The direct object refers to an existing item.
    /// 3. The current location is lit, or the item itself provides light.
    /// 4. The player can reach the specified item.
    /// 5. The item has the `.isReadable` flag set.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors such as `custom` (for missing direct object),
    ///           `prerequisiteNotMet` (if not an item), `roomIsDark`, `itemNotAccessible`,
    ///           or `itemNotReadable` if any validation condition fails.
    ///           Can also throw errors from `context.engine.item()` if the item doesn't exist.
    public func validate(context: ActionContext) async throws {
        // 1. Ensure we have a direct object and it's an item
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.custom("Read what?")
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can only read items.")
        }

        // 2. Check if item exists
        let targetItem = try await context.engine.item(targetItemID)

        // 3. Check if room is lit (unless item provides light)
        guard await context.engine.playerLocationIsLit() else {
            throw ActionResponse.roomIsDark
        }

        // 4. Check reachability
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // 5. Check if item is readable
        guard targetItem.hasFlag(.isReadable) else {
            throw ActionResponse.itemNotReadable(targetItemID)
        }
    }

    /// Processes the "READ" command.
    ///
    /// Assuming validation has passed, this action:
    /// 1. Retrieves the target item.
    /// 2. If the item is takeable and not currently held by the player, automatically takes it first
    ///    and prepends "(Taken)" to the output message.
    /// 3. Creates a `StateChange` to set the `.isTouched` flag on the target item, if not already set.
    /// 4. Updates pronouns to refer to this item.
    /// 5. Attempts to fetch the readable text from the item's dynamic attributes using
    ///    the `.readText` key via `context.engine.fetch()`.
    /// 6. If text is found and is not empty, it's returned as the message. Otherwise, a default
    ///    message indicating nothing is written on the item is used.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing the text read from the item (or a default message)
    ///            and any relevant `StateChange`s (e.g., auto-taking, setting `.isTouched`, updating pronouns).
    /// - Throws: `ActionResponse.internalEngineError` if the direct object is unexpectedly not an item.
    ///           Can also throw errors from `context.engine.item()` or `context.engine.fetch()`.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject,
            case .item(let targetItemID) = directObjectRef
        else {
            throw ActionResponse.internalEngineError(
                "Read: directObject was not an item in process.")
        }
        let targetItem = try await context.engine.item(targetItemID)

        // Check if item needs to be auto-taken
        let isHeld = targetItem.parent == .player
        let isTakeable = targetItem.hasFlag(.isTakable)
        let needsAutoTake = !isHeld && isTakeable

        // Determine read text
        let readText: String
        do {
            if let textToRead: String = try await context.engine.attribute(
                .readText, of: targetItem.id
            ), !textToRead.isEmpty {
                readText = textToRead
            } else {
                readText = "There's nothing written on the \(targetItem.name)."
            }
        } catch {
            readText = "There's nothing written on the \(targetItem.name)."
        }

        // Build final message
        let message =
            if needsAutoTake {
                "(Taken)\n\n\(readText)"
            } else {
                readText
            }

        return ActionResult(
            message: message,
            stateChanges: [
                needsAutoTake ? await context.engine.move(targetItem, to: .player) : nil,
                await context.engine.setFlag(.isTouched, on: targetItem),
                await context.engine.updatePronouns(to: targetItem),
            ]
        )
    }
}
