import Foundation

/// Handles the "PULL" command for pulling objects.
/// Implements pulling mechanics following ZIL patterns, as a complement to PUSH.
public struct PullActionHandler: ActionHandler {
    public init() {}

    /// Validates the "PULL" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (what to pull).
    /// 2. The target item exists and is reachable.
    /// 3. The item can be pulled (has the `.isPullable` flag or similar logic).
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
    public func validate(context: ActionContext) async throws {
        // Pull requires a direct object (what to pull)
        guard let directObjectRef = context.command.directObject else {
            let message = context.message(.pullWhat)
            throw ActionResponse.prerequisiteNotMet(message)
        }
        guard case .item(let targetItemID) = directObjectRef else {
            let message = context.message(.canOnlyActOnItems(verb: "pull"))
            throw ActionResponse.prerequisiteNotMet(message)
        }

        // Check if target exists and is reachable
        _ = try await context.engine.item(targetItemID)
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    }

    /// Processes the "PULL" command.
    ///
    /// Handles pulling objects. Most objects cannot be pulled, but some specific
    /// items (like ropes, levers, handles) may have special pull behavior that
    /// can be customized via ItemEventHandlers.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate pull message and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject,
            case .item(let targetItemID) = directObjectRef
        else {
            throw ActionResponse.internalEngineError(
                "PullActionHandler: directObject was not an item in process.")
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

        // Check if item is specifically pullable
        let message: String
        if targetItem.hasFlag(.isPullable) {
            message = context.message(.pullSuccess(item: targetItem.name))
        } else {
            // Default behavior: most things can't be pulled effectively
            message = context.message(.cannotPull(item: targetItem.name))
        }

        return ActionResult(message: message, stateChanges: stateChanges)
    }

    /// Performs any post-processing after the pull action completes.
    ///
    /// Currently no post-processing is needed for basic pulling.
    ///
    /// - Parameter context: The action context for the current action.
    public func postProcess(context: ActionContext, result: ActionResult) async throws {
        // No post-processing needed for pull
    }
}
