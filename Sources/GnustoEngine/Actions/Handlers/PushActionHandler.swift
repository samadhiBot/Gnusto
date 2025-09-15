import Foundation

/// Handles the "PUSH" command and its synonyms (e.g., "PRESS", "SHOVE"), allowing the player
/// to push objects.
public struct PushActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject)
    ]

    public let synonyms: [Verb] = [.depress, .press, .push, .shove]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "PUSH" command.
    ///
    /// This action validates prerequisites and handles pushing objects. Provides feedback
    /// for each item pushed and updates touched flags appropriately.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Press requires a direct object (what to press)
        guard let item = try await context.itemDirectObject() else {
            throw ActionResponse.doWhat(context)
        }

        return try await ActionResult(
            item.response(
                object: context.msg.pushObject,
                character: context.msg.pushCharacter,
                enemy: context.msg.pushEnemy
            ),
            item.setFlag(.isTouched)
        )
    }
}
