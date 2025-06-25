import Foundation

/// Handles the "DIG" command for digging with or without tools.
/// Implements digging mechanics following ZIL patterns.
public struct DigActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.dig),
        .match(.verb, .directObject),
        .match(.verb, .directObject, .with, .indirectObject),
    ]

    public let verbs: [VerbID] = [.dig, .excavate]

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
        public func process(
        command: Command,
        engine: GameEngine
    ) async throws -> ActionResult {

        // If a direct object is specified, validate it
        if let directObjectRef = command.directObject {
            guard case .item(let targetItemID) = directObjectRef else {
                throw ActionResponse.prerequisiteNotMet(
                    engine.messenger.cannotDoThat(verb: "dig")
                )
            }

            _ = try await engine.item(targetItemID)
            guard await engine.playerCanReach(targetItemID) else {
                throw ActionResponse.itemNotAccessible(targetItemID)
            }
        }

        // If digging tool is specified, validate it
        if let indirectObjectRef = command.indirectObject {
            guard case .item(let toolItemID) = indirectObjectRef else {
                throw ActionResponse.prerequisiteNotMet(
                    engine.messenger.cannotActWithThat(verb: "dig")
                )
            }

            let toolItem = try await engine.item(toolItemID)
            guard toolItem.parent == .player else {
                throw ActionResponse.itemNotHeld(toolItemID)
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
        // Handle direct object if specified
        if let directObjectRef = command.directObject,
            case .item(let targetItemID) = directObjectRef
        {
            let targetItem = try await engine.item(targetItemID)

            return ActionResult(
                engine.messenger.cannotDoThat(
                    verb: .dig,
                    item: targetItem.withDefiniteArticle
                ),
                await engine.setFlag(.isTouched, on: targetItem),
                await engine.updatePronouns(to: targetItem),
            )
        } else {
            // General digging (no specific target)
            let message: String
            if let indirectObjectRef = command.indirectObject,
                case .item(let toolItemID) = indirectObjectRef
            {
                let toolItem = try await engine.item(toolItemID)

                if toolItem.hasFlag(.isTool) {
                    message = engine.messenger.digWithToolNothing(
                        tool: toolItem.withDefiniteArticle
                    )
                } else {
                    message = engine.messenger.toolNotSuitableForDigging(
                        tool: toolItem.withDefiniteArticle
                    )
                }
            } else {
                // Check if player has digging tools
                let playerInventory = await engine.playerInventory
                let diggingTools = playerInventory.filter { $0.hasFlag(.isTool) }

                if !diggingTools.isEmpty {
                    message = engine.messenger.suggestUsingToolToDig()
                } else {
                    message = engine.messenger.diggingBareHandsIneffective()
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
