import Foundation

/// Handles the "TURN" command for turning objects.
/// Implements turning mechanics following ZIL patterns for object manipulation.
public struct TurnActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb, .directObject, .to, .indirectObject),
    ]

    public let synonyms: [Verb] = [.turn, .rotate, .twist]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "TURN" command.
    ///
    /// This action validates prerequisites and handles turning attempts on different types
    /// of objects. Provides appropriate responses following ZIL traditions.
    /// Can optionally turn to a specific setting specified in the indirect object.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Turn requires a direct object (what to turn)
        guard let item = try await context.itemDirectObject() else {
            throw ActionResponse.doWhat(context)
        }

        // Determine appropriate response based on object type
        let message =
            if await item.isCharacter {
                context.msg.turnCharacter(await item.withDefiniteArticle)
            } else if await item.hasFlag(.isTakable) {
                context.msg.turnItem(await item.withDefiniteArticle)
            } else {
                context.msg.turnFixedObject(await item.withDefiniteArticle)
            }

        return await ActionResult(
            message,
            item.setFlag(.isTouched)
        )
    }
}
