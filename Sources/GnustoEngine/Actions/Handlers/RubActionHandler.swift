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
            throw ActionResponse.prerequisiteNotMet(
                context.message.doWhat(verb: .rub)
            )
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.cannotActOnThat(verb: "rub")
            )
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
            case .item(let targetItemID) = directObjectRef
        else {
            throw ActionResponse.internalEngineError(
                "RubActionHandler: directObject was not an item in process.")
        }

        let targetItem = try await context.engine.item(targetItemID)

        // Determine appropriate response based on object type
        let message =
            if targetItem.hasFlag(.isCharacter) {
                // Rubbing characters might not be appropriate
                context.message.rubCharacter(character: targetItem.withDefiniteArticle)
            } else if targetItem.hasFlag(.isLightSource) {
                // Special message for light sources (lamps, lanterns)
                context.message.rubLamp(item: targetItem.withDefiniteArticle)
            } else if targetItem.hasFlag(.isTakable) {
                // Message for a generic takable object
                context.message.rubTakableObject(item: targetItem.withDefiniteArticle)
            } else {
                // Generic rubbing response for objects
                context.message.rubGenericObject(item: targetItem.withDefiniteArticle)
            }

        return ActionResult(
            message: message,
            changes: [
                await context.engine.setFlag(.isTouched, on: targetItem),
                await context.engine.updatePronouns(to: targetItem),
            ]
        )
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
