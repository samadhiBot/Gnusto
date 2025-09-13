import Foundation

/// Handles the "THINK ABOUT" command, allowing the player to ponder an item or themselves.
/// This is a more introspective action, often resulting in a generic or humorous response.
public struct ThinkActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb),
        .match(.consider, .directObject),
        .match(.ponder, .over, .directObject),
        .match(.think, .about, .directObject),
    ]

    public let synonyms: [Verb] = [.think, .consider, .ponder]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "THINK ABOUT" command.
    ///
    /// This action validates prerequisites and provides contemplative responses for thinking
    /// about objects or the player themselves. Items are marked as touched when thought about.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Ensure we have a direct object
        guard
            let topic = try await context.itemDirectObject(
                requiresLight: false,
                locationMessage: { await context.msg.thinkAboutLocation($0.withDefiniteArticle) },
                universalMessage: { context.msg.thinkAboutUniversal($0.withDefiniteArticle) },
                playerMessage: context.msg.thinkAboutSelf()
            )
        else {
            throw ActionResponse.feedback(
                context.msg.think()
            )
        }

        return try await ActionResult(
            topic.response(
                object: context.msg.thinkAboutItem,
                character: context.msg.thinkAboutCharacter,
                enemy: context.msg.thinkAboutEnemy
            ),
            topic.setFlag(.isTouched)
        )
    }
}
