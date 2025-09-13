import Foundation

/// Handles the "KISS" command for kissing objects or characters.
/// Implements kissing mechanics following ZIL patterns for social interactions.
public struct KissActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject)
    ]

    public let synonyms: [Verb] = [.kiss]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "KISS" command.
    ///
    /// This action validates prerequisites and handles kissing attempts on different types
    /// of objects and characters. Generally provides humorous or appropriate responses
    /// following ZIL traditions.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Kiss requires a direct object (what to kiss)
        guard
            let item = try await context.itemDirectObject(
                playerMessage: context.msg.kissSelf()
            )
        else {
            throw ActionResponse.doWhat(context)
        }

        return try await ActionResult(
            item.response(
                object: context.msg.kissObject,
                character: context.msg.kissCharacter,
                enemy: context.msg.kissEnemy
            ),
            item.setFlag(.isTouched)
        )
    }
}
