import Foundation

/// Handles the "MOVE" command and its synonyms (e.g., "SHIFT", "SLIDE"), allowing the player
/// to move or manipulate objects in the game world. This is typically used for objects that
/// can be moved but not taken, such as moving leaves to reveal something underneath.
public struct MoveActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb, .directObject, .to, .indirectObject),
    ]

    public let synonyms: [Verb] = [.move, .shift, .slide]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "MOVE" command.
    ///
    /// This action validates prerequisites and handles moving or manipulating objects.
    /// Unlike TAKE, this doesn't require items to be takable, as MOVE is often used
    /// for manipulating objects that are too large or fixed to pick up.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let item = try await context.itemDirectObject(
            playerMessage: context.msg.move()
        ) else {
            throw ActionResponse.feedback(
                context.msg.move()
            )
        }

        guard let target = try await context.itemIndirectObject() else {
            return await ActionResult(
                context.msg.moveItem(item.withDefiniteArticle),
                item.setFlag(.isTouched)
            )
        }

        return await ActionResult(
            context.msg.moveItemToTarget(
                item.withDefiniteArticle,
                target: target.withDefiniteArticle
            ),
            item.setFlag(.isTouched),
            target.setFlag(.isTouched)
        )
    }
}
