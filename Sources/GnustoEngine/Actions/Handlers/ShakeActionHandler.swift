import Foundation

/// Handles the "SHAKE" command for shaking objects.
/// Implements shaking mechanics following ZIL patterns for physical interactions.
public struct ShakeActionHandler: ActionHandler {
    public init() {}

    /// Validates the "SHAKE" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (what to shake).
    /// 2. The target item exists and is reachable.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
    public func validate(context: ActionContext) async throws {
        // Shake requires a direct object (what to shake)
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet("Shake what?")
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can't shake that.")
        }

        // Check if target exists and is reachable
        _ = try await context.engine.item(targetItemID)
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    }

    /// Processes the "SHAKE" command.
    ///
    /// Handles shaking attempts on different types of objects.
    /// Generally provides descriptive responses following ZIL traditions.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate shaking message and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject,
              case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.internalEngineError("ShakeActionHandler: directObject was not an item in process.")
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
            // Shaking characters - not advisable
            message = "I don't think the \(targetItem.name) would appreciate being shaken."
        } else if targetItem.hasFlag(.isContainer) {
            // Shaking containers might reveal contents
            if targetItem.hasFlag(.isOpen) {
                message = "You shake the \(targetItem.name), but nothing falls out."
            } else {
                message = "You shake the \(targetItem.name) and hear something rattling inside."
            }
        } else if targetItem.name.lowercased().contains("bottle") || targetItem.name.lowercased().contains("vial") {
            // Shaking liquid containers
            message = "You shake the \(targetItem.name) and hear liquid sloshing inside."
        } else if targetItem.hasFlag(.isTakable) {
            // Shaking small objects
            message = "You shake the \(targetItem.name) vigorously, but nothing happens."
        } else {
            // Can't shake fixed objects
            message = "You can't shake the \(targetItem.name) - it's firmly in place."
        }

        return ActionResult(message: message, stateChanges: stateChanges)
    }

    /// Performs any post-processing after the shake action completes.
    ///
    /// Currently no post-processing is needed for basic shaking.
    ///
    /// - Parameter context: The action context for the current action.
    public func postProcess(context: ActionContext) async throws {
        // No post-processing needed for shake
    }
}
