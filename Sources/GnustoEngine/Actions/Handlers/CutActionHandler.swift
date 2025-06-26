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

    public let verbs: [Verb] = [.cut, .slice, .chop]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "CUT" command.
    ///
    /// Handles cutting attempts with different tools:
    /// - Sharp weapons (knives, swords)
    /// - Tools (axes, saws)
    /// - Inappropriate implements
    /// - Bare hands
    ///
    /// - Parameter command: The command being processed.
    /// - Parameter engine: The game engine.
    /// - Returns: An `ActionResult` with appropriate cutting message and state changes.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
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
        let targetItem = try await engine.item(targetItemID)

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

        // Determine cutting implement and generate appropriate message
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
}
