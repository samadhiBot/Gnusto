import Foundation

/// Handles the "KISS" command for kissing objects or characters.
/// Implements kissing mechanics following ZIL patterns for social interactions.
public struct KissActionHandler: ActionHandler {
    public init() {}

    /// Validates the "KISS" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (what to kiss).
    /// 2. The target item exists and is reachable.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
    public func validate(context: ActionContext) async throws {
        // Kiss requires a direct object (what to kiss)
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet("Kiss what?")
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can't kiss that.")
        }

        // Check if target exists and is reachable
        _ = try await context.engine.item(targetItemID)
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    }

    /// Processes the "KISS" command.
    ///
    /// Handles kissing attempts on different types of objects and characters.
    /// Generally provides humorous or appropriate responses following ZIL traditions.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate kissing message and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject,
              case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.internalEngineError("KissActionHandler: directObject was not an item in process.")
        }

        let targetItem = try await context.engine.item(targetItemID)
        var stateChanges: [StateChange] = []

        // Mark target as touched (if appropriate)
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
            // Kissing characters - context matters
            if targetItem.name.lowercased().contains("frog") {
                // Fairy tale reference
                message = "You kiss the \(targetItem.name), but it remains a frog. Apparently it's not that kind of story."
            } else {
                // Other characters
                message = "The \(targetItem.name) doesn't seem particularly receptive to your affections."
            }
        } else if targetItem.name.lowercased().contains("mirror") {
            // Kissing mirrors
            message = "You kiss your reflection in the \(targetItem.name). How narcissistic!"
        } else if targetItem.name.lowercased().contains("statue") || targetItem.name.lowercased().contains("sculpture") {
            // Kissing art
            message = "You kiss the \(targetItem.name). The cold stone is not very responsive."
        } else if targetItem.hasFlag(.isTakable) {
            // Kissing small objects
            message = "You kiss the \(targetItem.name). It tastes about as good as you'd expect."
        } else {
            // Kissing large/fixed objects
            message = "You can't kiss the \(targetItem.name) - it's too large and impersonal."
        }

        return ActionResult(message: message, stateChanges: stateChanges)
    }

    /// Performs any post-processing after the kiss action completes.
    ///
    /// Currently no post-processing is needed for basic kissing.
    ///
    /// - Parameter context: The action context for the current action.
    public func postProcess(context: ActionContext) async throws {
        // No post-processing needed for kiss
    }
}
