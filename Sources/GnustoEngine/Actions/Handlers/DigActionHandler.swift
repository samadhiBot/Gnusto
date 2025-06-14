import Foundation

/// Handles the "DIG" command for digging with or without tools.
/// Implements digging mechanics following ZIL patterns.
public struct DigActionHandler: ActionHandler {
    public init() {}

    /// Validates the "DIG" command.
    ///
    /// This method ensures that:
    /// 1. If a direct object is specified, it exists and is reachable.
    /// 2. If a digging tool is specified, it exists and is held.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
    public func validate(context: ActionContext) async throws {
        // If a direct object is specified, validate it
        if let directObjectRef = context.command.directObject {
            guard case .item(let targetItemID) = directObjectRef else {
                let message = context.message(.cannotActOnThat(verb: "dig"))
                throw ActionResponse.prerequisiteNotMet(message)
            }

            _ = try await context.engine.item(targetItemID)
            guard await context.engine.playerCanReach(targetItemID) else {
                throw ActionResponse.itemNotAccessible(targetItemID)
            }
        }

        // If digging tool is specified, validate it
        if let indirectObjectRef = context.command.indirectObject {
            guard case .item(let toolItemID) = indirectObjectRef else {
                let message = context.message(.cannotActWithThat(verb: "dig"))
                throw ActionResponse.prerequisiteNotMet(message)
            }

            let toolItem = try await context.engine.item(toolItemID)
            guard toolItem.parent == .player else {
                throw ActionResponse.itemNotHeld(toolItemID)
            }
        }
    }

    /// Processes the "DIG" command.
    ///
    /// Handles digging attempts with different scenarios:
    /// - Digging with appropriate tools (shovels, spades)
    /// - Digging with inappropriate tools
    /// - Digging with bare hands
    /// - Digging specific objects vs. general digging
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate digging message and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        var stateChanges: [StateChange] = []
        let message: String

        // Handle direct object if specified
        if let directObjectRef = context.command.directObject,
            case .item(let targetItemID) = directObjectRef
        {

            let targetItem = try await context.engine.item(targetItemID)

            // Mark target as touched
            if let touchedChange = await context.engine.setFlag(.isTouched, on: targetItem) {
                stateChanges.append(touchedChange)
            }

            // Update pronouns to refer to the target
            if let pronounChange = await context.engine.updatePronouns(to: targetItem) {
                stateChanges.append(pronounChange)
            }

            message = context.message(.cannotDig(item: targetItem.withDefiniteArticle))

        } else {
            // General digging (no specific target)
            if let indirectObjectRef = context.command.indirectObject,
                case .item(let toolItemID) = indirectObjectRef
            {

                let toolItem = try await context.engine.item(toolItemID)

                if toolItem.hasFlag(.isTool) {
                    message = context.message(
                        .digWithToolNothing(tool: toolItem.withDefiniteArticle))
                } else {
                    message = context.message(
                        .toolNotSuitableForDigging(tool: toolItem.withDefiniteArticle))
                }

            } else {
                // Check if player has digging tools
                let playerInventory = await context.engine.playerInventory
                let diggingTools = playerInventory.filter { $0.hasFlag(.isTool) }

                if !diggingTools.isEmpty {
                    message = context.message(.suggestUsingToolToDig)
                } else {
                    message = context.message(.diggingBareHandsIneffective)
                }
            }
        }

        return ActionResult(message: message, stateChanges: stateChanges)
    }

    /// Performs any post-processing after the "DIG" command.
    ///
    /// Currently no post-processing is needed for basic digging.
    ///
    /// - Parameter context: The processed `ActionContext`.
    /// - Returns: The context unchanged.
    public func postProcess(context: ActionContext) async -> ActionContext {
        return context
    }
}
