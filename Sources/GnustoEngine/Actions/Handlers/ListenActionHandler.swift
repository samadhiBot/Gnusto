import Foundation

/// Handles the "LISTEN" command, providing a generic response.
///
/// By default, listening doesn't produce any specific information. Game developers can
/// customize listening behavior by providing custom `ItemEventHandler` or
/// `LocationEventHandler` implementations for specific items or locations if special
/// sounds should be heard.
public struct ListenActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb),
        .match(.verb, .for, .directObject),
        .match(.verb, .to, .directObject),
    ]

    public let synonyms: [Verb] = [.listen]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "LISTEN" command.
    ///
    /// This action provides atmospheric responses to listening. Can be used without objects
    /// for general listening, or with objects for listening to specific items.
    public func process(context: ActionContext) async throws -> ActionResult {
        do {
            guard let item = try await context.itemDirectObject() else {
                return ActionResult(
                    context.msg.listen()
                )
            }

            let message = if context.hasPreposition(.to) {
                await context.msg.listenTo(item.withDefiniteArticle)
            } else {
                await context.msg.listenFor(item.withDefiniteArticle)
            }

            return await ActionResult(
                message,
                item.setFlag(.isTouched)
            )
        } catch {
            guard await context.player.location.isLit else {
                throw ActionResponse.feedback(
                    context.msg.listenInDarkness()
                )
            }
            throw error
        }
    }
}
