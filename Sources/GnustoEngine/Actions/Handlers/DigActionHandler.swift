import Foundation

/// Handles the "DIG" command for digging with or without tools.
/// Implements digging mechanics following ZIL patterns.
public struct DigActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.dig),
        .match(.verb, .directObject),
        .match(.verb, .directObject, .with, .indirectObject),
        .match(.verb, .with, .indirectObject),
    ]

    public let verbs: [Verb] = [.dig, .excavate]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "DIG" command.
    ///
    /// Handles digging attempts with different scenarios:
    /// - Digging with appropriate tools (shovels, spades)
    /// - Digging with inappropriate tools
    /// - Digging with bare hands
    /// - Digging specific objects vs. general digging
    ///
    /// - Parameter command: The command being processed.
    /// - Parameter engine: The game engine.
    /// - Returns: An `ActionResult` with appropriate digging message and state changes.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        guard let directObjectRef = command.directObject else {
            // Ground implied .match(.verb, .with, .indirectObject)
            if let indirectObjectItemID = command.indirectObjectItemID {
                let indirectObjectItem = try await engine.item(indirectObjectItemID)
                if indirectObjectItem.hasFlag(.isTool) {
                    return ActionResult(
                        engine.messenger.digWithToolNothing(
                            tool: indirectObjectItem.withDefiniteArticle
                        )
                    )
                }
            }
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotDoThat(verb: "dig")
            )
        }

        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        let targetItem = try await engine.item(targetItemID)

        if targetItem.hasFlag(.isTakable) {
            // Generally cannot dig something that can be taken
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotDoThat(verb: "dig")
            )
        }

        // If digging tool is specified, validate it
        guard let indirectObjectRef = command.indirectObject else {
            // General digging (no specific target, no tool)
            let playerInventory = await engine.playerInventory
            let diggingTools = playerInventory.filter { $0.hasFlag(.isTool) }

            let message = diggingTools.isEmpty ?
                engine.messenger.diggingBareHandsIneffective(
                    ground: targetItem.withDefiniteArticle
                ) :
                engine.messenger.suggestUsingToolToDig()

            return ActionResult(message)
        }

        guard case .item(let toolItemID) = indirectObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotActWithThat(verb: "dig")
            )
        }

        let toolItem = try await engine.item(toolItemID)

        guard toolItem.parent == .player else {
            throw ActionResponse.itemNotHeld(toolItemID)
        }

        let message = toolItem.hasFlag(.isTool)
            ? engine.messenger.digWithToolNothing(tool: toolItem.withDefiniteArticle)
            : engine.messenger.toolNotSuitableForDigging(tool: toolItem.withDefiniteArticle)

        return ActionResult(message)
    }
}
