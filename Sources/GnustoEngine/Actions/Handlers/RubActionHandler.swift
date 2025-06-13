import Foundation

/// Handles the "RUB" command for rubbing objects.
/// Implements rubbing mechanics following ZIL patterns for physical interactions.
public struct RubActionHandler: ActionHandler {
    public init() {}

    /// Validates the "RUB" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (what to rub).
    /// 2. The target item exists and is reachable.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
    public func validate(context: ActionContext) async throws {
        // Rub requires a direct object (what to rub)
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet("Rub what?")
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can't rub that.")
        }

        // Check if target exists and is reachable
        _ = try await context.engine.item(targetItemID)
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    }

    /// Processes the "RUB" command.
    ///
    /// Handles rubbing attempts on different types of objects.
    /// Generally provides descriptive responses following ZIL traditions.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate rubbing message and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject,
              case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.internalEngineError("RubActionHandler: directObject was not an item in process.")
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

        if targetItem.hasFlag(.isCharacter) {
            // Rubbing characters might not be appropriate
            message = "I don't think the \(targetItem.name) would appreciate being rubbed."
        } else if targetItem.name.lowercased().contains("clean") {
            // Already clean items
            message = "The \(targetItem.name) is already clean."
        } else if targetItem.name.lowercased().contains("lamp") || targetItem.name.lowercased().contains("lantern") {
            // Special case for lamps - magical associations
            message = "Rubbing the \(targetItem.name) doesn't seem to do anything. No djinn appears."
        } else if targetItem.hasFlag(.isTakable) {
            // Rubbing small objects
            message = "You rub the \(targetItem.name). It feels smooth to the touch."
        } else {
            // Rubbing fixed/large objects
            message = "You rub the \(targetItem.name), but nothing interesting happens."
        }

        return ActionResult(message: message, stateChanges: stateChanges)
    }

    /// Performs any post-processing after the rub action completes.
    ///
    /// Currently no post-processing is needed for basic rubbing.
    ///
    /// - Parameter context: The action context for the current action.
    public func postProcess(context: ActionContext) async throws {
        // No post-processing needed for rub
    }
}
