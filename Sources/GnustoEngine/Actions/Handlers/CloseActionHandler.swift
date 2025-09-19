import Foundation

/// Handles the "CLOSE" command, allowing the player to close an item that is openable
/// and currently open.
public struct CloseActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject)
    ]

    public let synonyms: [Verb] = [.close, .shut]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "CLOSE" command.
    ///
    /// This action validates prerequisites and closes the specified item if possible.
    /// Checks that the item exists, is reachable, closable, and currently open.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Ensure we have a direct object and it's an item
        guard let targetItem = try await context.itemDirectObject() else {
            throw ActionResponse.doWhat(context)
        }

        // Check if item is closable (using .isOpenable for symmetry)
        guard await targetItem.isOpenable else {
            throw ActionResponse.cannotDo(context, targetItem)
        }

        // Check if already closed
        guard await targetItem.hasFlag(.isOpen) else {
            throw await ActionResponse.feedback(
                context.msg.alreadyDone(
                    context.command,
                    item: targetItem.withDefiniteArticle
                )
            )
        }

        return await ActionResult(
            context.msg.closed(),
            targetItem.clearFlag(.isOpen),
            targetItem.setFlag(.isTouched)
        )
    }
}
