import Foundation

/// Handles the "JUMP" command and its synonyms (e.g., "LEAP", "HOP").
/// Implements jumping behavior following ZIL patterns.
public struct JumpActionHandler: ActionHandler {
    public init() {}

    /// Validates the "JUMP" command.
    ///
    /// This method ensures that if a direct object is specified,
    /// it exists and is reachable.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
    public func validate(context: ActionContext) async throws {
        // JUMP with no object is always valid (general jumping)
        guard let directObjectRef = context.command.directObject else {
            return
        }

        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can't jump that.")
        }

        // Check if target exists and is reachable
        _ = try await context.engine.item(targetItemID)
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    }

    /// Processes the "JUMP" command.
    ///
    /// Handles jumping in place or jumping over objects.
    /// Provides appropriate responses based on ZIL traditions.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate jump message and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        var stateChanges: [StateChange] = []

        // Handle JUMP with no object - general jumping
        guard let directObjectRef = context.command.directObject else {
            // Provide varied responses for atmospheric effect
            let responses = [
                "You jump on the spot, fruitlessly.",
                "You jump up and down.",
                "You leap into the air.",
                "You bounce up and down."
            ]

            return ActionResult(
                try await context.engine.randomElement(in: responses)
            )
        }

        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.internalEngineError("JumpActionHandler: directObject was not an item in process.")
        }

        let targetItem = try await context.engine.item(targetItemID)

        // Mark as touched and update pronouns
        if let touchedChange = await context.engine.setFlag(.isTouched, on: targetItem) {
            stateChanges.append(touchedChange)
        }
        if let pronounChange = await context.engine.updatePronouns(to: targetItem) {
            stateChanges.append(pronounChange)
        }

        // Determine appropriate response based on object type
        let message: String

        if targetItem.hasFlag(.isCharacter) {
            // Can't jump characters
            message = "You can't jump the \(targetItem.name)."
        } else if targetItem.name.lowercased().contains("gap") ||
                  targetItem.name.lowercased().contains("chasm") ||
                  targetItem.name.lowercased().contains("pit") {
            // Dangerous to jump across gaps
            message = "That would be extremely dangerous."
        } else if targetItem.name.lowercased().contains("water") ||
                  targetItem.name.lowercased().contains("stream") ||
                  targetItem.name.lowercased().contains("river") {
            // Jumping water
            message = "You can't jump across the \(targetItem.name)."
        } else if targetItem.hasFlag(.isTakable) {
            // Small objects
            message = "You jump over the \(targetItem.name)."
        } else {
            // Large objects
            message = "You can't jump the \(targetItem.name)."
        }

        return ActionResult(message: message, stateChanges: stateChanges)
    }

    /// Performs any post-processing after the jump action completes.
    ///
    /// Currently no post-processing is needed for basic jumping.
    ///
    /// - Parameter context: The action context for the current action.
    public func postProcess(context: ActionContext) async throws {
        // No post-processing needed for jump
    }
}
