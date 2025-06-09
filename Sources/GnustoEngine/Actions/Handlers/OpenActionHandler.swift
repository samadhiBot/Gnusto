import Foundation

/// Handles the "OPEN" command, allowing the player to open an item that is openable,
/// not locked, and not already open.
public struct OpenActionHandler: ActionHandler {
    /// Validates the "OPEN" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (the player must indicate *what* to open).
    /// 2. The direct object refers to an existing item.
    /// 3. The player can reach the specified item.
    /// 4. The item has the `.isOpenable` flag set.
    /// 5. The item does not have the `.isLocked` flag set.
    ///
    /// Note: It does *not* check if the item is already open here; that case is handled
    /// gracefully in the `process` method with a specific message.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails, such as:
    ///           `prerequisiteNotMet` (for missing object or wrong item type),
    ///           `itemNotAccessible` (if item cannot be reached),
    ///           `itemNotOpenable` (if item cannot be opened),
    ///           `itemIsLocked` (if item is locked).
    ///           Can also throw errors from `context.engine.item()`.
    public func validate(context: ActionContext) async throws {
        // 1. Check for multiple objects (not supported by OPEN)
        if context.command.directObjects.count > 1 {
            throw ActionResponse.prerequisiteNotMet("The OPEN command doesn't support multiple objects.")
        }

        // 2. Ensure we have a direct object and it's an item
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet("Open what?")
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can only open items.")
        }

        // 3. Check if item exists and is accessible using ScopeResolver
        let targetItem = try await context.engine.item(targetItemID)

        // Use ScopeResolver to determine reachability
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // 4. Check if item is openable
        guard targetItem.hasFlag(.isOpenable) else {
            throw ActionResponse.itemNotOpenable(targetItemID)
        }

        // 5. Check if locked
        if targetItem.hasFlag(.isLocked) {
            throw ActionResponse.itemIsLocked(targetItemID)
        }
    }

    /// Processes the "OPEN" command.
    ///
    /// This action performs the following:
    /// 1. Retrieves the target item.
    /// 2. Checks if the item is already open (by fetching its `.isOpen` dynamic property).
    ///    If so, an `ActionResponse.itemAlreadyOpen` error is thrown, leading to a message
    ///    like "The [item name] is already open."
    /// 3. If the item is not already open (and validation has ensured it's openable and not locked):
    ///    a. Sets the `.isOpen` flag on the item.
    ///    b. Ensures the `.isTouched` flag is set on the item.
    ///    c. Updates pronouns to refer to the opened item.
    ///    d. Returns an `ActionResult` with a confirmation message that announces any revealed
    ///       contents if the container has items inside (e.g., "Opening the small mailbox reveals a leaflet."),
    ///       or a simple confirmation otherwise (e.g., "You open the chest."), and the state changes.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing the message and relevant state changes.
    /// - Throws: `ActionResponse.internalEngineError` if the direct object is not an item
    ///           (this should be caught by `validate`), `ActionResponse.itemAlreadyOpen` if the item
    ///           is already open, or errors from `context.engine` calls.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject,
              case .item(let targetItemID) = directObjectRef else {
            // Should not be reached if validate is correct.
            throw ActionResponse.internalEngineError("Open: directObject was not an item in process.")
        }

        let targetItem = try await context.engine.item(targetItemID)

        // Check if already open
        if try await context.engine.hasFlag(.isOpen, on: targetItem.id) {
            throw ActionResponse.itemAlreadyOpen(targetItemID)
        }

        var stateChanges: [StateChange] = []

        if let update = await context.engine.setFlag(.isOpen, on: targetItem) {
            stateChanges.append(update)
        }

        if let update = await context.engine.setFlag(.isTouched, on: targetItem) {
            stateChanges.append(update)
        }

        // Update pronoun
        if let update = await context.engine.updatePronouns(to: targetItem) {
            stateChanges.append(update)
        }

        // Check if container has items inside to announce what's revealed
        let message: String
        if targetItem.hasFlag(.isContainer) {
            let itemsInside = await context.engine.items(in: .item(targetItemID))
            if !itemsInside.isEmpty {
                // Announce what's revealed: "Opening the small mailbox reveals a leaflet."
                let itemList = itemsInside.sorted().listWithIndefiniteArticles
                message = "Opening the \(targetItem.name) reveals \(itemList)."
            } else {
                // Container is empty, use simple message
                message = "You open the \(targetItem.name)."
            }
        } else {
            // Not a container, use simple message
            message = "You open the \(targetItem.name)."
        }

        // Prepare the result
        return ActionResult(
            message: message,
            stateChanges: stateChanges
        )
    }

    // Rely on default postProcess to print the message.
    // Engine's execute method handles applying the stateChanges.
}

// TODO: Add/verify ActionResponse cases: .itemNotOpenable, .itemAlreadyOpen, .itemIsLocked
