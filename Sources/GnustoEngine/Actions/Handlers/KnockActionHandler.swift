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
            let message = context.message(.knockOnWhat)
            throw ActionResponse.prerequisiteNotMet(message)
        }
        guard case .item(let targetItemID) = directObjectRef else {
            let message = context.message(.cannotActOnThat(verb: "knock on"))
            throw ActionResponse.prerequisiteNotMet(message)
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
            case .item(let targetItemID) = directObjectRef
        else {
            throw ActionResponse.internalEngineError(
                "KnockActionHandler: directObject was not an item in process.")
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
                message = context.message(.knockOnOpenDoor(door: targetItem.name))
            } else if targetItem.hasFlag(.isLocked) {
                message = context.message(.knockOnLockedDoor(door: targetItem.name))
            } else {
                message = context.message(.knockOnClosedDoor(door: targetItem.name))
            }
        } else if targetItem.hasFlag(.isContainer) {
            // Knocking on containers
            message = context.message(.knockOnContainer(container: targetItem.withDefiniteArticle))
        } else {
            // Generic knocking response for objects
            message = context.message(.knockOnGenericObject(item: targetItem.withDefiniteArticle))
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
