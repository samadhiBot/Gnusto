import Foundation

/// Handles the "DEFLATE" command for deflating previously inflated objects like balloons, rafts, etc.
/// Implements deflation mechanics following ZIL patterns.
public struct DeflateActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject)
    ]

    public let verbs: [Verb] = [.deflate]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "DEFLATE" command.
    ///
    /// Handles deflating objects. If the object is not currently inflated, provides
    /// an appropriate message. If it is inflated, clears the `.isInflated` flag
    /// and provides confirmation.
    ///
    /// - Parameter command: The command being processed.
    /// - Parameter engine: The game engine.
    /// - Returns: An `ActionResult` with appropriate deflate message and state changes.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Deflate requires a direct object (what to deflate)
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }

        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.thatsNotSomethingYouCan(.deflate)
            )
        }

        // Check if target exists and is reachable
        let targetItem = try await engine.item(targetItemID)

        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // Check if item is inflatable (which means it can also be deflated)
        guard targetItem.hasFlag(.isInflatable) else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotDoThat(
                    verb: .deflate,
                    item: targetItem.withDefiniteArticle
                )
            )
        }

        // Check if currently inflated
        let isCurrentlyInflated = try await engine.hasFlag(.isInflated, on: targetItemID)

        let message =
            if !isCurrentlyInflated {
                engine.messenger.itemNotInflated(item: targetItem.withDefiniteArticle)
            } else {
                engine.messenger.deflateSuccess(item: targetItem.withDefiniteArticle)
            }

        return ActionResult(
            message,
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.updatePronouns(to: targetItem),
            await engine.clearFlag(.isInflated, on: targetItem)
        )
    }
}
