import Foundation

/// Handles the LAUGH verb for laughing, guffawing, or expressing mirth.
///
/// This is a humorous atmospheric command that provides entertaining responses
/// to player attempts to laugh. Based on ZIL tradition.
public struct LaughActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb),
        .match(.verb, .about, .directObject),
        .match(.verb, .at, .directObject),
    ]

    public let synonyms: [Verb] = [.laugh, .chuckle, .giggle, .snicker, .chortle]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "LAUGH" command.
    ///
    /// This action provides humorous responses to player attempts to laugh.
    /// Can be used with or without a target object.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let proxyReference = context.command.directObject else {
            // General laughing
            return ActionResult(
                context.msg.laugh()
            )
        }

        let message =
            if context.hasPreposition(.at) {
                await context.msg.laughAt(proxyReference.withDefiniteArticle)
            } else {
                await context.msg.laughAbout(proxyReference.withDefiniteArticle)
            }

        let changes: [StateChange?] =
            if case .item(let itemProxy) = proxyReference {
                await [
                    itemProxy.setFlag(.isTouched)
                ]
            } else {
                []
            }

        return ActionResult(
            message: message, changes: changes
        )
    }
}
