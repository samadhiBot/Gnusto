import Foundation

/// Handles the "CLOSE" command, allowing the player to close an item that is openable
/// and currently open.
public struct CloseActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject)
    ]

    public let verbs: [VerbID] = [.close, .shut]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods
    /// Validates the "CLOSE" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (the player must indicate *what* to close).
    /// 2. The direct object refers to an existing item.
    /// 3. The player can reach the specified item.
    /// 4. The item has the `.isOpenable` flag set (indicating it can be opened and closed).
    ///
    /// Note: It explicitly *does not* throw an error if the item is already closed;
    /// this case is handled gracefully in the `process` method with a specific message.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails, such as:
    ///           `prerequisiteNotMet`, `itemNotAccessible`, `itemNotClosable`.
    ///           Can also throw errors from `engine.item()`.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {

        // 1. Ensure we have a direct object and it's an item
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.thatsNotSomethingYouCan(.close)
            )
        }

        // 2. Check if item exists
        guard let targetItem = try? await engine.item(targetItemID) else {
            // Standard approach: If parser resolved it, but it's gone, treat as inaccessible.
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // 3. Check reachability using ScopeResolver
        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // 4. Check if item is closable (using .openable for symmetry)
        guard targetItem.hasFlag(.isOpenable) else {
            throw ActionResponse.itemNotClosable(targetItemID)
        }

        // 5. Check if already closed (using dynamic property)
        guard try await engine.hasFlag(.isOpen, on: targetItemID) else {
            // Let process handle the specific message "That's already closed."
            return
        }

        // Note: Closing doesn't usually depend on locked status.
    /// Processes the "CLOSE" command.
    ///
    /// Assuming basic validation has passed, this action performs the following:
    /// 1. Retrieves the target item.
    /// 2. Checks if the item is already closed (by fetching its `.isOpen` dynamic property).
    ///    If so, a message "[Item] is already closed." is returned.
    /// 3. If the item is open:
    ///    a. Creates a `StateChange` to clear the `.isOpen` flag on the item.
    ///    b. Ensures the `.isTouched` flag is set on the item.
    ///    c. Updates pronouns to refer to the item.
    ///    d. Returns a confirmation message, typically "Closed."
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing a message and any relevant `StateChange`s.
    /// - Throws: Errors from `engine.item()` or `engine.fetch()`.
        guard
            let directObjectRef = command.directObject,
            case .item(let targetItemID) = directObjectRef
        else {
            // This case should ideally be caught by the validate function.
            return ActionResult(
                engine.messenger.youCantDoThat()
            )
        }

        let targetItem = try await engine.item(targetItemID)

        // Handle "already closed" case detected (but not thrown) in validate
        guard try await engine.hasFlag(.isOpen, on: targetItem.id) else {
            return ActionResult(
                engine.messenger.itemAlreadyClosed(item: targetItem.withDefiniteArticle)
            )
        }

        // --- Prepare Result ---
        return ActionResult(
            engine.messenger.closed(),
            await engine.clearFlag(.isOpen, on: targetItem),
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.updatePronouns(to: targetItem)
        )
    }

    // Rely on default postProcess to print the message.
}

// TODO: Add/verify ActionResponse cases: .itemNotClosable, .itemAlreadyClosed
