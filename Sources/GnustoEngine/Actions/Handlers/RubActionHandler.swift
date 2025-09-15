import Foundation

/// Handles the "RUB" command for rubbing objects.
/// Implements rubbing mechanics following ZIL patterns for physical interactions.
public struct RubActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb, .directObject, .with, .indirectObject),
    ]

    public let synonyms: [Verb] = [.rub, .polish, .clean, .massage]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "RUB" command.
    ///
    /// This action validates prerequisites and handles rubbing attempts on different types
    /// of objects. Generally provides descriptive responses following ZIL traditions.
    /// Can optionally use a tool specified in the indirect object.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Rub requires a direct object (what to rub)
        guard
            let item = try await context.itemDirectObject(
                playerMessage: context.msg.rubSelf(context.verb)
            )
        else {
            throw ActionResponse.doWhat(context)
        }

        return try await ActionResult(
            item.response(
                object: { context.msg.rubObject(context.verb, item: $0) },
                character: { context.msg.rubCharacter(context.verb, character: $0) },
                enemy: { context.msg.rubEnemy(context.verb, enemy: $0) },
            ),
            item.setFlag(.isTouched)
        )
    }
}
