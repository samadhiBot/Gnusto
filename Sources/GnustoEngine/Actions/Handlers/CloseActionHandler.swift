import Foundation

/// Handles the "CLOSE" command, allowing the player to close an item that is openable
/// and currently open.
public struct CloseActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject)
    ]

    public let verbs: [Verb] = [.close, .shut]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "CLOSE" command.
    ///
    /// This action validates prerequisites and closes the specified item if possible.
    /// Checks that the item exists, is reachable, closable, and currently open.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Ensure we have a direct object and it's an item
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.thatsNotSomethingYouCan(.close)
            )
        }

        // Check if item exists and is accessible
        let targetItem = try await engine.item(targetItemID)
        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // Check if item is closable (using .isOpenable for symmetry)
        guard targetItem.hasFlag(.isOpenable) else {
            throw ActionResponse.itemNotClosable(targetItemID)
        }

        // Check if already closed
        guard try await engine.hasFlag(.isOpen, on: targetItemID) else {
            return ActionResult(
                engine.messenger.itemAlreadyClosed(item: targetItem.withDefiniteArticle)
            )
        }

        return ActionResult(
            engine.messenger.closed(),
            await engine.clearFlag(.isOpen, on: targetItem),
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.updatePronouns(to: targetItem)
        )
    }
}
