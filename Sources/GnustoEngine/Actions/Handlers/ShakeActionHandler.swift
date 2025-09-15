import Foundation

/// Handles the "SHAKE" command for shaking objects.
/// Implements shaking mechanics following ZIL patterns for physical interactions.
public struct ShakeActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject)
    ]

    public let synonyms: [Verb] = [.shake, .rattle]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "SHAKE" command.
    ///
    /// This action validates prerequisites and handles shaking attempts on different types
    /// of objects. Generally provides descriptive responses following ZIL traditions.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Shake requires a direct object (what to shake)
        guard
            let item = try await context.itemDirectObject(
                playerMessage: context.msg.shakeSelf(context.verb)
            )
        else {
            throw ActionResponse.feedback(
                context.msg.shakeSelf(context.verb)
            )
        }

        return try await ActionResult(
            item.response(
                object: { context.msg.shakeObject(context.verb, item: $0) },
                character: { context.msg.shakeCharacter(context.verb, character: $0) },
                enemy: { context.msg.shakeEnemy(context.verb, enemy: $0) },
            ),
            item.setFlag(.isTouched)
        )
    }
}
