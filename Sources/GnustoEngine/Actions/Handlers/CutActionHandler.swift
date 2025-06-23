import Foundation

/// Handles the "CUT" command and its synonyms (e.g., "SLICE", "CHOP").
///
/// The CUT verb allows players to attempt cutting objects with tools.
/// This handler checks for cutting tools (knives, swords, etc.), validates the target,
/// and provides appropriate responses based on ZIL behavior.
public struct CutActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let verbID: VerbID = .cut

    public let syntax: [SyntaxRule] = [
        SyntaxRule(.verb, .directObject),
        SyntaxRule(.verb, .directObject, .particle("with"), .indirectObject)
    ]

    public let synonyms: [String] = ["slice", "chop"]

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
    public func validate(context: ActionContext) async throws {
        // Cut requires a direct object (what to cut)
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.doWhat(verb: .cut)
            )
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.cannotDoThat(verb: "cut")
            )
        }

        // Check if target exists and is reachable
        _ = try await context.engine.item(targetItemID)
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // If cutting tool is specified, validate it
        if let indirectObjectRef = context.command.indirectObject {
            guard case .item(let toolItemID) = indirectObjectRef else {
                throw ActionResponse.prerequisiteNotMet(
                    context.message.cannotActWithThat(verb: "cut")
                )
            }

            let toolItem = try await context.engine.item(toolItemID)
            guard toolItem.parent == .player else {
                throw ActionResponse.itemNotHeld(toolItemID)
            }
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
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject,
            case .item(let targetItemID) = directObjectRef
        else {
            let message = context.message.actionHandlerInternalError(
                handler: "CutActionHandler",
                details: "directObject was not an item in process"
            )
            throw ActionResponse.internalEngineError(message)
        }

        let targetItem = try await context.engine.item(targetItemID)

        // Determine cutting implement
        let message: String

        if let indirectObjectRef = context.command.indirectObject,
            case .item(let toolItemID) = indirectObjectRef
        {

            let toolItem = try await context.engine.item(toolItemID)

            if toolItem.hasFlag(.isWeapon) || toolItem.hasFlag(.isTool) {
                // Successfully cut with appropriate tool
                message = context.message.cutWithTool(
                    item: targetItem.withDefiniteArticle,
                    tool: toolItem.withDefiniteArticle
                )
            } else {
                // Using an inappropriate implement
                message = context.message.cutToolNotSharp(
                    tool: toolItem.withDefiniteArticle.capitalizedFirst
                )
            }

        } else {
            // No tool specified - check if player has cutting implements
            let playerInventory = await context.engine.playerInventory
            let cuttingTools = playerInventory.filter {
                $0.hasFlag(.isWeapon) || $0.hasFlag(.isTool)
            }

            if !cuttingTools.isEmpty {
                let firstTool = cuttingTools.first!
                // Auto-cut with available tool
                message = context.message.cutWithAutoTool(
                    item: targetItem.withDefiniteArticle,
                    tool: firstTool.withDefiniteArticle
                )
            } else {
                message = context.message.cutNoSuitableTool()
            }
        }

        return ActionResult(
            message: message,
            changes: [
                await context.engine.setFlag(.isTouched, on: targetItem),
                await context.engine.updatePronouns(to: targetItem),
            ]
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
