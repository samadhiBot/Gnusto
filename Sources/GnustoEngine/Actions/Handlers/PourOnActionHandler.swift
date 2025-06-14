import Foundation

/// Handles the "POUR ON" command for pouring liquids on objects.
/// Implements pouring mechanics following ZIL patterns for liquid manipulation.
public struct PourOnActionHandler: ActionHandler {
    public init() {}

    /// Validates the "POUR ON" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (what to pour).
    /// 2. An indirect object is specified (what to pour on).
    /// 3. The target items exist and are reachable.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
    public func validate(context: ActionContext) async throws {
        // Pour requires a direct object (what to pour)
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet("Pour what?")
        }
        guard case .item(let sourceItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can't pour that.")
        }

        // Pour requires an indirect object (what to pour on)
        guard let indirectObjectRef = context.command.indirectObject else {
            let sourceItem = try await context.engine.item(sourceItemID)
            throw ActionResponse.prerequisiteNotMet("Pour the \(sourceItem.name) on what?")
        }
        guard case .item(let targetItemID) = indirectObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can't pour something on that.")
        }

        // Check if source exists and is reachable
        _ = try await context.engine.item(sourceItemID)
        guard await context.engine.playerCanReach(sourceItemID) else {
            throw ActionResponse.itemNotAccessible(sourceItemID)
        }

        // Check if target exists and is reachable
        _ = try await context.engine.item(targetItemID)
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    }

    /// Processes the "POUR ON" command.
    ///
    /// Handles pouring attempts with different types of liquids and targets.
    /// Provides appropriate responses following ZIL traditions.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate pouring message and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject,
            case .item(let sourceItemID) = directObjectRef,
            let indirectObjectRef = context.command.indirectObject,
            case .item(let targetItemID) = indirectObjectRef
        else {
            throw ActionResponse.internalEngineError(
                "PourOnActionHandler: missing required objects in process.")
        }

        let sourceItem = try await context.engine.item(sourceItemID)
        let targetItem = try await context.engine.item(targetItemID)

        // Determine appropriate response based on what's being poured and where
        let message = try await handlePouring(
            sourceItem: sourceItem,
            targetItem: targetItem,
            context: context
        )

        return ActionResult(
            message: message,
            stateChanges: [
                await context.engine.setFlag(.isTouched, on: sourceItem),
                await context.engine.setFlag(.isTouched, on: targetItem),
                await context.engine.updatePronouns(to: targetItem),
            ]
        )
    }

    /// Handles the actual pouring logic.
    private func handlePouring(
        sourceItem: Item,
        targetItem: Item,
        context: ActionContext
    ) async throws -> String {
        // Check if we're trying to pour something on itself
        if sourceItem.id == targetItem.id {
            return "You can't pour the \(sourceItem.name) on itself."
        }

        // Check if the source is actually pourable
        if !sourceItem.hasFlag(.isDrinkable) {
            return "You can't pour the \(sourceItem.name) - it's not a liquid."
        }

        // Special cases for characters as targets
        if targetItem.hasFlag(.isCharacter) {
            return
                "You pour the \(sourceItem.name) on the \(targetItem.name). They are not pleased with this treatment."
        }

        // Special cases for sensitive objects
        if targetItem.hasFlag(.isDevice) {
            return
                "You pour the \(sourceItem.name) on the \(targetItem.name). This probably wasn't a good idea - electronic devices and liquids don't mix well."
        }

        // General pouring response
        return
            "You pour the \(sourceItem.name) on the \(targetItem.name). It drips off without much effect."
    }

    /// Performs any post-processing after the pour action completes.
    ///
    /// Currently no post-processing is needed for basic pouring.
    ///
    /// - Parameter context: The action context for the current action.
    public func postProcess(context: ActionContext) async throws {
        // No post-processing needed for pour
    }
}
