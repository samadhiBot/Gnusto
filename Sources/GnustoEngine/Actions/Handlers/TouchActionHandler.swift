import Foundation

/// Handles the "TOUCH" command and its synonyms (e.g., "FEEL", "PAT"), allowing the
/// player to physically interact with an item by touching it.
public struct TouchActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject)
    ]

    public let synonyms: [Verb] = [.touch, .feel]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "TOUCH" command.
    ///
    /// This action validates prerequisites and provides tactile feedback for touching items.
    /// Sets the .isTouched flag on the target item and provides appropriate messaging.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Touch requires a direct object (what to touch)
        guard
            let item = try await context.itemDirectObject(
                playerMessage: context.msg.touchSelf(context.verb),
                failureMessage: context.msg.feelNothingUnusual(context.verb)
            )
        else {
            throw ActionResponse.doWhat(context)
        }

        return await ActionResult(
            item.response(
                object: { context.msg.touchObject(context.verb, item: $0) },
                character: { context.msg.touchCharacter(context.verb, character: $0) },
                enemy: { context.msg.touchEnemy(context.verb, enemy: $0) },
            ),
            item.setFlag(.isTouched)
        )
    }
}
