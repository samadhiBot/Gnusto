import Foundation

/// Handles the "PRESS" command for pressing buttons, switches, and other pressable objects.
/// Implements pressing mechanics following ZIL patterns.
public struct PressActionHandler: ActionHandler {
    public init() {}

    /// Validates the "PRESS" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (what to press).
    /// 2. The target item exists and is reachable.
    /// 3. The item can be pressed (has the `.isPressable` flag or similar logic).
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
    public func validate(context: ActionContext) async throws {
        // Press requires a direct object (what to press)
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet("Press what?")
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can only press objects.")
        }

        // Check if target exists and is reachable
        _ = try await context.engine.item(targetItemID)
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    }

    /// Processes the "PRESS" command.
    ///
    /// Handles pressing objects. Items with the `.isPressable` flag can be pressed
    /// and may have special behavior defined via ItemEventHandlers. Most objects
    /// cannot be pressed effectively.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate press message and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject,
              case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.internalEngineError("PressActionHandler: directObject was not an item in process.")
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

        // Check if item is pressable
        let message: String
        if targetItem.hasFlag(.isPressable) {
            message = "You press the \(targetItem.name)."
            // Note: Specific press behavior should be handled by ItemEventHandlers
        } else {
            // Default behavior: most things can't be pressed effectively
            message = "You can't press the \(targetItem.name)."
        }

        return ActionResult(message: message, stateChanges: stateChanges)
    }

    /// Performs any post-processing after the press action completes.
    ///
    /// Currently no post-processing is needed for basic pressing.
    ///
    /// - Parameter context: The action context for the current action.
    public func postProcess(context: ActionContext, result: ActionResult) async throws {
        // No post-processing needed for press
    }
}
