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
            let message = context.message(.squeezeWhat)
            throw ActionResponse.prerequisiteNotMet(message)
        }
        guard case .item(let targetItemID) = directObjectRef else {
            let message = context.message(.cannotActOnThat(verb: "squeeze"))
            throw ActionResponse.prerequisiteNotMet(message)
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
            case .item(let targetItemID) = directObjectRef
        else {
            throw ActionResponse.internalEngineError(
                "SqueezeActionHandler: directObject was not an item in process.")
        }

        let targetItem = try await context.engine.item(targetItemID)

        // Determine appropriate response based on object type and properties
        let message =
            if targetItem.hasFlag(.isCharacter) {
                // Squeezing characters - not advisable
                context.message(.squeezeCharacter(character: targetItem.withDefiniteArticle))
            } else {
                // Generic squeezing response for objects
                context.message(.squeezeHardObject(item: targetItem.withDefiniteArticle))
            }

        return ActionResult(
            message: message,
            stateChanges: [
                await context.engine.setFlag(.isTouched, on: targetItem),
                await context.engine.updatePronouns(to: targetItem),
            ]
        )
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
