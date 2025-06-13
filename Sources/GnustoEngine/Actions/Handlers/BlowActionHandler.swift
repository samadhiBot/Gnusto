import Foundation

/// Handles the "BLOW" command for blowing on objects like candles, fires, wind instruments, etc.
/// Implements blowing mechanics following ZIL patterns.
public struct BlowActionHandler: ActionHandler {
    public init() {}

    /// Validates the "BLOW" command.
    ///
    /// This method ensures that:
    /// 1. If a direct object is specified, it exists and is reachable.
    /// 2. The command is properly formed (can be "blow" alone or "blow object").
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
    public func validate(context: ActionContext) async throws {
        // Blow can be used without an object (general blowing) or with an object
        if let directObjectRef = context.command.directObject {
            guard case .item(let targetItemID) = directObjectRef else {
                throw ActionResponse.prerequisiteNotMet("You can only blow on objects.")
            }

            // Check if target exists and is reachable
            let targetItem = try await context.engine.item(targetItemID)
            guard await context.engine.playerCanReach(targetItemID) else {
                throw ActionResponse.itemNotAccessible(targetItemID)
            }
        }
    }

    /// Processes the "BLOW" command.
    ///
    /// Handles blowing on objects or general blowing. Special items like candles,
    /// fires, or wind instruments can have custom behavior via ItemEventHandlers.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate blow message and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        var stateChanges: [StateChange] = []

        // Handle blowing on a specific object
        if let directObjectRef = context.command.directObject,
           case .item(let targetItemID) = directObjectRef {

            let targetItem = try await context.engine.item(targetItemID)

            // Mark item as touched
            if let touchedChange = await context.engine.setFlag(.isTouched, on: targetItem) {
                stateChanges.append(touchedChange)
            }

            // Update pronouns to refer to the target
            if let pronounChange = await context.engine.updatePronouns(to: targetItem) {
                stateChanges.append(pronounChange)
            }

            // Default behavior for blowing on objects
            let message: String
            if targetItem.hasFlag(.isLightSource) && targetItem.hasFlag(.isLit) {
                // Blowing on lit light sources might extinguish them
                message = "You blow on the \(targetItem.name), but it doesn't go out."
                // Note: Specific extinguishing behavior should use TurnOffActionHandler or custom logic
            } else if targetItem.hasFlag(.isFlammable) {
                message = "Blowing on the \(targetItem.name) has no effect."
            } else {
                message = "You blow on the \(targetItem.name). Nothing happens."
            }

            return ActionResult(message: message, stateChanges: stateChanges)
        } else {
            // General blowing without a target
            return ActionResult("You blow air around. Nothing happens.")
        }
    }

    /// Performs any post-processing after the blow action completes.
    ///
    /// Currently no post-processing is needed for basic blowing.
    ///
    /// - Parameter context: The action context for the current action.
    public func postProcess(context: ActionContext, result: ActionResult) async throws {
        // No post-processing needed for blow
    }
}
