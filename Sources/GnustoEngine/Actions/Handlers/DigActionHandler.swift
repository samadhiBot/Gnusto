import Foundation

/// Handles the "DIG" command for digging with or without tools.
/// Implements digging mechanics following ZIL patterns.
public struct DigActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb(.dig)),
        .match(.verb, .directObject),
        .match(.verb, .directObject, .with, .indirectObject),
    ]

    public let synonyms: [VerbID] = [.dig, .excavate]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

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
                throw ActionResponse.prerequisiteNotMet(
                    context.message.cannotDoThat(verb: "dig")
                )
            }

            _ = try await context.engine.item(targetItemID)
            guard await context.engine.playerCanReach(targetItemID) else {
                throw ActionResponse.itemNotAccessible(targetItemID)
            }
        }

        // If digging tool is specified, validate it
        if let indirectObjectRef = context.command.indirectObject {
            guard case .item(let toolItemID) = indirectObjectRef else {
                throw ActionResponse.prerequisiteNotMet(
                    context.message.cannotActWithThat(verb: "dig")
                )
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
        // Handle direct object if specified
        if let directObjectRef = context.command.directObject,
            case .item(let targetItemID) = directObjectRef
        {
            let targetItem = try await context.engine.item(targetItemID)

            return ActionResult(
                context.message.cannotDig(item: targetItem.withDefiniteArticle),
                await context.engine.setFlag(.isTouched, on: targetItem),
                await context.engine.updatePronouns(to: targetItem),
            )
        } else {
            // General digging (no specific target)
            let message: String
            if let indirectObjectRef = context.command.indirectObject,
                case .item(let toolItemID) = indirectObjectRef
            {
                let toolItem = try await context.engine.item(toolItemID)

                if toolItem.hasFlag(.isTool) {
                    message = context.message.digWithToolNothing(
                        tool: toolItem.withDefiniteArticle
                    )
                } else {
                    message = context.message.toolNotSuitableForDigging(
                        tool: toolItem.withDefiniteArticle
                    )
                }
            } else {
                // Check if player has digging tools
                let playerInventory = await context.engine.playerInventory
                let diggingTools = playerInventory.filter { $0.hasFlag(.isTool) }

                if !diggingTools.isEmpty {
                    message = context.message.suggestUsingToolToDig()
                } else {
                    message = context.message.diggingBareHandsIneffective()
                }
            }

            return ActionResult(message: message)
        }
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
