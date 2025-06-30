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

    // MARK: - Universal Object Support

    /// Determines whether this handler can process digging-related universal objects.
    /// Returns `true` for universals that represent diggable surfaces.
    public func handlesUniversal(_ universal: UniversalObject) -> Bool {
        return UniversalObject.diggableUniversals.contains(universal)
    }

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
                        engine.messenger.digWithToolGeneral(
                            tool: indirectObjectItem.withDefiniteArticle
                        )
                    )
                }
            }
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }
        // Handle both regular items and universal objects
        switch directObjectRef {
        case .item(let targetItemID):
            // Handle regular item digging
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

            // Continue with item-specific digging logic
            return try await processItemDigging(
                targetItem: targetItem, command: command, engine: engine)

        case .universal(let universal):
            // Handle universal object digging (like "ground", "earth")
            guard handlesUniversal(universal) else {
                throw ActionResponse.prerequisiteNotMet(
                    engine.messenger.cannotDoThat(verb: "dig")
                )
            }

            // For universals, we always treat it as bare-handed digging unless a tool is specified
            return try await processUniversalDigging(
                universal: universal, command: command, engine: engine)

        default:
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotDoThat(verb: "dig")
            )
        }
    }

    /// Processes digging of regular items.
    private func processItemDigging(targetItem: Item, command: Command, engine: GameEngine)
        async throws -> ActionResult
    {

        // If digging tool is specified, validate it
        guard let indirectObjectRef = command.indirectObject else {
            // General digging (no specific target, no tool)
            let playerInventory = await engine.playerInventory
            let diggingTools = playerInventory.filter { $0.hasFlag(.isTool) }

            let message =
                diggingTools.isEmpty
                ? engine.messenger.cannotDoThat(verb: .dig, item: targetItem.withDefiniteArticle)
                : engine.messenger.suggestUsingToolToDig()

            return ActionResult(
                message,
                await engine.setFlag(.isTouched, on: targetItem),
                await engine.updatePronouns(to: targetItem)
            )
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

        let message =
            toolItem.hasFlag(.isTool)
            ? engine.messenger.digWithToolGeneral(tool: toolItem.withDefiniteArticle)
            : engine.messenger.toolNotSuitableForDigging(tool: toolItem.withDefiniteArticle)

        return ActionResult(
            message,
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.updatePronouns(to: targetItem)
        )
    }

    /// Processes digging of universal objects like "ground", "earth", etc.
    private func processUniversalDigging(
        universal: UniversalObject, command: Command, engine: GameEngine
    ) async throws -> ActionResult {
        // If digging tool is specified, validate it
        guard let indirectObjectRef = command.indirectObject else {
            // Bare-handed digging of universal objects
            let playerInventory = await engine.playerInventory
            let diggingTools = playerInventory.filter { $0.hasFlag(.isTool) }

            let message =
                diggingTools.isEmpty
                ? engine.messenger.digUniversalIneffective()
                : engine.messenger.suggestUsingToolToDig()

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

        let message =
            toolItem.hasFlag(.isTool)
            ? engine.messenger.digWithToolGeneral(tool: toolItem.withDefiniteArticle)
            : engine.messenger.toolNotSuitableForDigging(tool: toolItem.withDefiniteArticle)

        return ActionResult(message)
    }
}
