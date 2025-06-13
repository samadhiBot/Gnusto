import Foundation

/// Handles the "SQUEEZE" command for squeezing objects.
/// Implements squeezing mechanics following ZIL patterns for physical interactions.
public struct SqueezeActionHandler: ActionHandler {
    public init() {}

    /// Validates the "SQUEEZE" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (what to squeeze).
    /// 2. The target item exists and is reachable.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
    public func validate(context: ActionContext) async throws {
        // Squeeze requires a direct object (what to squeeze)
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet("Squeeze what?")
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can't squeeze that.")
        }

        // Check if target exists and is reachable
        _ = try await context.engine.item(targetItemID)
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    }

    /// Processes the "SQUEEZE" command.
    ///
    /// Handles squeezing attempts on different types of objects.
    /// Generally provides descriptive responses following ZIL traditions.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate squeezing message and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject,
              case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.internalEngineError("SqueezeActionHandler: directObject was not an item in process.")
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

        // Determine appropriate response based on object type and properties
        let message: String

        if targetItem.hasFlag(.isCharacter) {
            // Squeezing characters - not advisable
            message = "I don't think the \(targetItem.name) would appreciate being squeezed."
        } else if targetItem.name.lowercased().contains("sponge") {
            // Squeezing sponges - might get water
            message = "You squeeze the \(targetItem.name) and water drips out."
        } else if targetItem.name.lowercased().contains("tube") || targetItem.name.lowercased().contains("bottle") {
            // Squeezing containers
            message = "You squeeze the \(targetItem.name) and some of its contents ooze out."
        } else if targetItem.name.lowercased().contains("soft") || targetItem.name.lowercased().contains("pillow") {
            // Squeezing soft objects
            message = "You squeeze the \(targetItem.name). It feels soft and yielding."
        } else if targetItem.hasFlag(.isTakable) {
            // Squeezing regular small objects
            message = "You squeeze the \(targetItem.name) as hard as you can, but it doesn't give."
        } else {
            // Can't squeeze large/fixed objects
            message = "You can't get your arms around the \(targetItem.name) to squeeze it."
        }

        return ActionResult(message: message, stateChanges: stateChanges)
    }

    /// Performs any post-processing after the squeeze action completes.
    ///
    /// Currently no post-processing is needed for basic squeezing.
    ///
    /// - Parameter context: The action context for the current action.
    public func postProcess(context: ActionContext) async throws {
        // No post-processing needed for squeeze
    }
}
