import Foundation

/// Handles the "TOUCH" command and its synonyms (e.g., "FEEL", "RUB", "PAT"), allowing the
/// player to physically interact with an item by touching it.
public struct TouchActionHandler: ActionHandler {
    /// Validates the "TOUCH" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (the player must indicate *what* to touch).
    /// 2. The direct object refers to an existing item.
    /// 3. The player can reach the specified item.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: `ActionResponse.custom` if no direct object is provided,
    ///           `ActionResponse.prerequisiteNotMet` if the direct object is not an item,
    ///           or `ActionResponse.itemNotAccessible` if the item cannot be reached.
    ///           Can also throw errors from `context.engine.item()` if the item doesn't exist.
    public func validate(context: ActionContext) async throws {
        // 1. Ensure we have a direct object and it's an item
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.custom("Touch what?")
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can only touch items.")
        }

        // 2. Check if item exists (engine.item() will throw if not found)
        let _ = try await context.engine.item(targetItemID)

        // 3. Check reachability
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    }

    /// Processes the "TOUCH" command.
    ///
    /// Assuming validation has passed, this action:
    /// 1. Retrieves the target item.
    /// 2. Creates a `StateChange` to set the `.isTouched` flag on the target item, if not already set.
    /// 3. Returns a generic message like "You feel nothing special."
    ///
    /// Specific tactile feedback or consequences for touching particular items can be implemented
    /// via custom `ItemEventHandler` logic.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing a default message and potentially a `StateChange`
    ///   to mark the item as touched.
    /// - Throws: `ActionResponse.internalEngineError` if the direct object is unexpectedly not an item.
    ///           Can also throw errors from `context.engine.item()` if the item doesn't exist.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject,
              case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.internalEngineError("Touch: directObject was not an item in process.")
        }
        let targetItem = try await context.engine.item(targetItemID)

        // --- State Change: Mark as Touched ---
        var stateChanges: [StateChange] = []

        if let addTouchedFlag = await context.engine.setFlag(.isTouched, on: targetItem) {
            stateChanges.append(addTouchedFlag)
        }

        // --- Create Result ---
        return ActionResult(
            message: "You feel nothing special.",
            stateChanges: stateChanges
        )
    }
}
