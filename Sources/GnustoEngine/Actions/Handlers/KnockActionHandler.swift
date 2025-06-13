import Foundation

/// Handles the "KNOCK" command for knocking on objects.
/// Implements knocking mechanics following ZIL patterns for interactions.
public struct KnockActionHandler: ActionHandler {
    public init() {}

    /// Validates the "KNOCK" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (what to knock on).
    /// 2. The target item exists and is reachable.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
    public func validate(context: ActionContext) async throws {
        // Knock requires a direct object (what to knock on)
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet("Knock on what?")
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can't knock on that.")
        }

        // Check if target exists and is reachable
        _ = try await context.engine.item(targetItemID)
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    }

    /// Processes the "KNOCK" command.
    ///
    /// Handles knocking attempts on different types of objects.
    /// Generally provides appropriate responses following ZIL traditions.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate knocking message and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject,
              case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.internalEngineError("KnockActionHandler: directObject was not an item in process.")
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

        if targetItem.hasFlag(.isDoor) {
            // Knocking on doors
            if targetItem.hasFlag(.isOpen) {
                message = "The \(targetItem.name) is already open. There's no need to knock."
            } else if targetItem.hasFlag(.isLocked) {
                message = "You knock on the \(targetItem.name). There's no response from the other side."
            } else {
                message = "You knock on the \(targetItem.name), but there's no answer."
            }
        } else if targetItem.name.lowercased().contains("wall") {
            // Knocking on walls
            message = "You knock on the \(targetItem.name). It sounds solid."
        } else if targetItem.name.lowercased().contains("wood") || targetItem.name.lowercased().contains("wooden") {
            // Knocking on wooden objects
            message = "You knock on the \(targetItem.name). It makes a hollow wooden sound."
        } else if targetItem.hasFlag(.isContainer) {
            // Knocking on containers
            message = "You knock on the \(targetItem.name). You hear a hollow sound."
        } else if targetItem.hasFlag(.isTakable) {
            // Knocking on small objects
            message = "You knock on the \(targetItem.name), but it's too small to produce much of a sound."
        } else {
            // Knocking on other objects
            message = "You knock on the \(targetItem.name). Nothing happens."
        }

        return ActionResult(message: message, stateChanges: stateChanges)
    }

    /// Performs any post-processing after the knock action completes.
    ///
    /// Currently no post-processing is needed for basic knocking.
    ///
    /// - Parameter context: The action context for the current action.
    public func postProcess(context: ActionContext) async throws {
        // No post-processing needed for knock
    }
}
