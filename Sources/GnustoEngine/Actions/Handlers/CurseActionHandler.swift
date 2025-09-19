import Foundation

/// Handles the CURSE verb for swearing, cursing, or expressing frustration.
///
/// This is a humorous atmospheric command that provides entertaining responses
/// to player attempts to curse or swear. Based on ZIL tradition.
public struct CurseActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb),
        .match(.curse, .directObject),
        .match(.damn, .directObject),
    ]

    public let synonyms: [Verb] = [.curse, .swear, .shit, .fuck, .damn]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "CURSE" command.
    ///
    /// This action provides humorous responses to player attempts to curse or swear.
    /// Can be used with or without a target object.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let targetItem = try await context.itemDirectObject() else {
            // General cursing (no object)
            return ActionResult(
                context.msg.curse()
            )
        }

        let message =
            if await targetItem.isCharacter {
                await context.msg.curseCharacter(targetItem.withDefiniteArticle)
            } else {
                await context.msg.curseTarget(targetItem.withDefiniteArticle)
            }

        // Cursing at something
        return await ActionResult(
            message,
            targetItem.setFlag(.isTouched)
        )
    }
}
