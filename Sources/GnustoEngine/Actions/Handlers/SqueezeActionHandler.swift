import Foundation

/// Handles the "SQUEEZE" command for squeezing objects.
/// Implements squeezing mechanics following ZIL patterns for physical interactions.
public struct SqueezeActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject)
    ]

    public let synonyms: [Verb] = [.squeeze, .compress, .hug]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "SQUEEZE" command.
    ///
    /// This action validates prerequisites and handles squeezing attempts on different types
    /// of objects. Generally provides descriptive responses following ZIL traditions.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Squeeze requires a direct object (what to squeeze)
        guard
            let item = try await context.itemDirectObject(
                playerMessage: context.msg.squeezeSelf(context.command)
            )
        else {
            throw ActionResponse.doWhat(context)
        }

        return try await ActionResult(
            item.response(
                object: { context.msg.squeezeObject(context.command, item: $0) },
                character: { context.msg.squeezeCharacter(context.command, character: $0) },
                enemy: { context.msg.squeezeEnemy(context.command, enemy: $0) },
            ),
            item.setFlag(.isTouched)
        )
    }
}
