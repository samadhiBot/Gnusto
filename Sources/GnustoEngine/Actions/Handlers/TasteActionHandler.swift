import Foundation

/// Handles the "TASTE" command, providing a generic response when the player attempts
/// to taste an item.
///
/// By default, tasting items results in a non-specific message. Game developers can provide
/// more detailed taste descriptions or effects for particular items (e.g., food, potions)
/// by implementing custom `ItemEventHandler` logic.
public struct TasteActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject)
    ]

    public let synonyms: [Verb] = [.taste, .lick]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "TASTE" command.
    ///
    /// This action validates prerequisites and provides gustatory responses to tasting items.
    /// Checks that the item exists and is accessible, then provides appropriate taste feedback.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Taste requires a direct object (what to taste)
        guard
            let item = try await context.itemDirectObject(
                playerMessage: context.msg.tasteSelf(context.verb),
                failureMessage: context.msg.tasteNothingUnusual(context.verb)
            )
        else {
            throw ActionResponse.feedback(
                context.msg.tasteNothingUnusual(context.verb)
            )
        }

        return try await ActionResult(
            item.response(
                object: { context.msg.tasteObject(context.verb, item: $0) },
                character: { context.msg.tasteCharacter(context.verb, character: $0) },
                enemy: { context.msg.tasteEnemy(context.verb, enemy: $0) },
            ),
            item.setFlag(.isTouched)
        )
    }
}
