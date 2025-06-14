import Foundation

/// Handles the "DEFLATE" command for deflating previously inflated objects like balloons, rafts, etc.
/// Implements deflation mechanics following ZIL patterns.
public struct DeflateActionHandler: ActionHandler {
    public init() {}

    /// Validates the "DEFLATE" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (what to deflate).
    /// 2. The target item exists and is reachable.
    /// 3. The item has the `.isInflatable` flag (can be deflated).
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
    public func validate(context: ActionContext) async throws {
        // Deflate requires a direct object (what to deflate)
        guard let directObjectRef = context.command.directObject else {
            let message = context.message(.deflateWhat)
            throw ActionResponse.prerequisiteNotMet(message)
        }
        guard case .item(let targetItemID) = directObjectRef else {
            let message = context.message(.canOnlyActOnItems(verb: "deflate"))
            throw ActionResponse.prerequisiteNotMet(message)
        }

        // Check if target exists and is reachable
        let targetItem = try await context.engine.item(targetItemID)
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // Check if item is inflatable (which means it can also be deflated)
        guard targetItem.hasFlag(.isInflatable) else {
            throw ActionResponse.prerequisiteNotMet("You can't deflate the \(targetItem.name).")
        }
    }

    /// Processes the "DEFLATE" command.
    ///
    /// Handles deflating objects. If the object is not currently inflated, provides
    /// an appropriate message. If it is inflated, clears the `.isInflated` flag
    /// and provides confirmation.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate deflate message and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject,
            case .item(let targetItemID) = directObjectRef
        else {
            throw ActionResponse.internalEngineError(
                "DeflateActionHandler: directObject was not an item in process.")
        }

        let targetItem = try await context.engine.item(targetItemID)
        var stateChanges: [StateChange] = []

        // Mark item as touched
        if let touchedChange = await context.engine.setFlag(.isTouched, on: targetItem) {
            stateChanges.append(touchedChange)
        }

        // Update pronouns to refer to the target
        if let pronounChange = await context.engine.updatePronouns(to: targetItem) {
            stateChanges.append(pronounChange)
        }

        // Check if currently inflated
        let isCurrentlyInflated = try await context.engine.hasFlag(.isInflated, on: targetItemID)

        let message: String
        if !isCurrentlyInflated {
            message = "The \(targetItem.name) is not inflated."
        } else {
            // Deflate the item
            if let deflateChange = await context.engine.clearFlag(.isInflated, on: targetItem) {
                stateChanges.append(deflateChange)
            }

            message = "You deflate the \(targetItem.name)."
        }

        return ActionResult(message: message, stateChanges: stateChanges)
    }

    /// Performs any post-processing after the deflate action completes.
    ///
    /// Currently no post-processing is needed for basic deflation.
    ///
    /// - Parameter context: The action context for the current action.
    public func postProcess(context: ActionContext, result: ActionResult) async throws {
        // No post-processing needed for deflate
    }
}
