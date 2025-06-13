import Foundation

/// Handles the "WAVE" command for waving objects.
/// Implements waving mechanics following ZIL patterns for physical interactions.
public struct WaveActionHandler: ActionHandler {
    public init() {}

    /// Validates the "WAVE" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (what to wave).
    /// 2. The target item exists and is reachable.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
    public func validate(context: ActionContext) async throws {
        // Wave requires a direct object (what to wave)
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet("Wave what?")
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can't wave that.")
        }

        // Check if target exists and is reachable
        _ = try await context.engine.item(targetItemID)
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    }

    /// Processes the "WAVE" command.
    ///
    /// Handles waving attempts on different types of objects.
    /// Generally provides descriptive responses following ZIL traditions.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate waving message and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject,
              case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.internalEngineError("WaveActionHandler: directObject was not an item in process.")
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
            // Waving at characters
            message = "You wave the \(targetItem.name) around, but it doesn't seem to appreciate being waved."
        } else if targetItem.name.lowercased().contains("wand") || targetItem.name.lowercased().contains("staff") {
            // Waving magical items
            message = "You wave the \(targetItem.name) dramatically, but nothing magical happens."
        } else if targetItem.name.lowercased().contains("sword") || targetItem.name.lowercased().contains("blade") {
            // Waving weapons - brandishing
            message = "You brandish the \(targetItem.name) menacingly."
        } else if targetItem.hasFlag(.isTakable) {
            // Waving small objects
            message = "You wave the \(targetItem.name) around. It's not particularly impressive."
        } else {
            // Can't wave fixed objects
            message = "You can't wave the \(targetItem.name) around - it's not something you can pick up and wave."
        }

        return ActionResult(message: message, stateChanges: stateChanges)
    }

    /// Performs any post-processing after the wave action completes.
    ///
    /// Currently no post-processing is needed for basic waving.
    ///
    /// - Parameter context: The action context for the current action.
    public func postProcess(context: ActionContext) async throws {
        // No post-processing needed for wave
    }
}
