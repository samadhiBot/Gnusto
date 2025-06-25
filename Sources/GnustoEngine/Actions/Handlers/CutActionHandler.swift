import Foundation

/// Handles the "CUT" command and its synonyms (e.g., "SLICE", "CHOP").
///
/// The CUT verb allows players to attempt cutting objects with tools.
/// This handler checks for cutting tools (knives, swords, etc.), validates the target,
/// and provides appropriate responses based on ZIL behavior.
public struct CutActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb, .directObject, .with, .indirectObject),
    ]

    public let verbs: [VerbID] = [.cut, .slice, .chop]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Validates the "CUT" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (what to cut).
    /// 2. The target item exists and is reachable.
    /// 3. If a cutting tool is specified, it exists and is held.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
        public func process(
        command: Command,
        engine: GameEngine
    ) async throws -> ActionResult {

        // Cut requires a direct object (what to cut)
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotDoThat(verb: "cut")
            )
        }

        // Check if target exists and is reachable
        _ = try await engine.item(targetItemID)
        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // If cutting tool is specified, validate it
        if let indirectObjectRef = command.indirectObject {
            guard case .item(let toolItemID) = indirectObjectRef else {
                throw ActionResponse.prerequisiteNotMet(
                    engine.messenger.cannotActWithThat(verb: "cut")
                )
            }

            let toolItem = try await engine.item(toolItemID)
            guard toolItem.parent == .player else {
                throw ActionResponse.itemNotHeld(toolItemID)
            }
        }
    /// Processes the "CUT" command.
    ///
    /// Handles cutting attempts with different tools:
    /// - Sharp weapons (knives, swords)
    /// - Tools (axes, saws)
    /// - Inappropriate implements
    /// - Bare hands
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate cutting message and state changes.
        guard let directObjectRef = command.directObject,
            case .item(let targetItemID) = directObjectRef
        else {
            let message = engine.messenger.actionHandlerInternalError(
                handler: "CutActionHandler",
                details: "directObject was not an item in process"
            )
            throw ActionResponse.internalEngineError(message)
        }

        let targetItem = try await engine.item(targetItemID)

        // Determine cutting implement
        let message: String

        if let indirectObjectRef = command.indirectObject,
            case .item(let toolItemID) = indirectObjectRef
        {

            let toolItem = try await engine.item(toolItemID)

            if toolItem.hasFlag(.isWeapon) || toolItem.hasFlag(.isTool) {
                // Successfully cut with appropriate tool
                message = engine.messenger.cutWithTool(
                    item: targetItem.withDefiniteArticle,
                    tool: toolItem.withDefiniteArticle
                )
            } else {
                // Using an inappropriate implement
                message = engine.messenger.cutToolNotSharp(
                    tool: toolItem.withDefiniteArticle.capitalizedFirst
                )
            }

        } else {
            // No tool specified - check if player has cutting implements
            let playerInventory = await engine.playerInventory
            let cuttingTools = playerInventory.filter {
                $0.hasFlag(.isWeapon) || $0.hasFlag(.isTool)
            }

            if !cuttingTools.isEmpty {
                let firstTool = cuttingTools.first!
                // Auto-cut with available tool
                message = engine.messenger.cutWithAutoTool(
                    item: targetItem.withDefiniteArticle,
                    tool: firstTool.withDefiniteArticle
                )
            } else {
                message = engine.messenger.cutNoSuitableTool()
            }
        }

        return ActionResult(
            message,
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.updatePronouns(to: targetItem)
        )
    }

    /// Performs any post-processing after the "CUT" command.
    ///
    /// Currently no post-processing is needed for basic cutting.
    ///
    /// - Parameter context: The processed `ActionContext`.
    /// - Returns: The context unchanged.
    public func postProcess(context: ActionContext) async -> ActionContext {
        return context
    }
}
