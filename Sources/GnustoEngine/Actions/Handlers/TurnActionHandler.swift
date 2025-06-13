import Foundation

/// Handles the "TURN" command for turning objects.
/// Implements turning mechanics following ZIL patterns for object manipulation.
public struct TurnActionHandler: ActionHandler {
    public init() {}

    /// Validates the "TURN" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (what to turn).
    /// 2. The target item exists and is reachable.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
    public func validate(context: ActionContext) async throws {
        // Turn requires a direct object (what to turn)
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet("Turn what?")
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can't turn that.")
        }

        // Check if target exists and is reachable
        _ = try await context.engine.item(targetItemID)
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    }

    /// Processes the "TURN" command.
    ///
    /// Handles turning attempts on different types of objects.
    /// Provides appropriate responses following ZIL traditions.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate turning message and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject,
              case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.internalEngineError("TurnActionHandler: directObject was not an item in process.")
        }

        let targetItem = try await context.engine.item(targetItemID)
        var stateChanges: [StateChange] = []

        // Mark target as touched
        if let touchedChange = await context.engine.setFlag(.isTouched, on: targetItem) {
            stateChanges.append(touchedChange)
        }

        // Update pronouns to refer to the target
        if let pronounChange = await context.engine.updatePronouns(to: targetItem) {
            stateChanges.append(pronounChange)
        }

        // Determine appropriate response based on object type
        let message: String

        if targetItem.name.lowercased().contains("dial") || targetItem.name.lowercased().contains("knob") {
            // Turning dials and knobs - might have mechanical effects
            message = "You turn the \(targetItem.name). It clicks into a new position."
        } else if targetItem.name.lowercased().contains("wheel") {
            // Turning wheels
            message = "You turn the \(targetItem.name). It rotates with some effort."
        } else if targetItem.name.lowercased().contains("handle") || targetItem.name.lowercased().contains("crank") {
            // Turning handles and cranks
            message = "You turn the \(targetItem.name). It moves with a grinding sound."
        } else if targetItem.name.lowercased().contains("key") {
            // Turning keys - should probably use with something
            message = "You can't just turn the \(targetItem.name) by itself. You need to use it with something."
        } else if targetItem.hasFlag(.isCharacter) {
            // Can't turn characters
            message = "You can't turn the \(targetItem.name) around like an object."
        } else if targetItem.hasFlag(.isTakable) {
            // Turning small objects
            message = "You turn the \(targetItem.name) around in your hands, but nothing happens."
        } else {
            // Can't turn large/fixed objects
            message = "The \(targetItem.name) doesn't seem to be designed to be turned."
        }

        return ActionResult(message: message, stateChanges: stateChanges)
    }

    /// Performs any post-processing after the turn action completes.
    ///
    /// Currently no post-processing is needed for basic turning.
    ///
    /// - Parameter context: The action context for the current action.
    public func postProcess(context: ActionContext) async throws {
        // No post-processing needed for turn
    }
}
