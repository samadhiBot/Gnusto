import Foundation

/// Handles the YELL verb for yelling, shouting, or making loud vocalizations.
///
/// This is a humorous atmospheric command that provides entertaining responses
/// to player attempts to yell or shout. Based on ZIL tradition.
public struct YellActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb),
        .match(.verb, .at, .directObject),
    ]

    public let synonyms: [Verb] = [.yell, .shout, .scream, .shriek, .holler]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "YELL" command.
    ///
    /// This action provides humorous responses to player attempts to yell or shout.
    /// Can be used with or without a target object.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let recipient = try await context.itemDirectObject() else {
            return ActionResult(
                context.msg.yell()
            )
        }

        return await ActionResult(
            recipient.response(
                object: context.msg.yellAtObject,
                character: context.msg.yellAtCharacter,
                enemy: context.msg.yellAtEnemy
            ),
            recipient.setFlag(.isTouched)
        )
    }
}
