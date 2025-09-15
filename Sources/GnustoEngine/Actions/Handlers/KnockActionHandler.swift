import Foundation

/// Handles the "KNOCK" command for knocking on objects.
/// Implements knocking mechanics following ZIL patterns for interactions.
public struct KnockActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.knock),
        .match(.tap, .directObject),
        .match(.verb, .on, .directObject),
    ]

    public let synonyms: [Verb] = [.knock, .rap, .tap]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "KNOCK" command.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Knock requires a direct object (what to knock on)
        guard let item = try await context.itemDirectObject() else {
            throw ActionResponse.feedback(
                context.msg.doWhat(context.command)
            )
        }

        return try await ActionResult(
            await context.msg.youDo(
                context.command,
                item: item.withDefiniteArticle
            ),
            item.setFlag(.isTouched)
        )
    }
}
