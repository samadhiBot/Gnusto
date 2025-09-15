import Foundation

/// Handles the "WAVE" command for waving objects.
/// Implements waving mechanics following ZIL patterns for physical interactions.
public struct WaveActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.wave),
        .match(.verb, .directObject),
        .match(.wave, .at, .directObject),
        .match(.wave, .to, .directObject),
        .match(.verb, .directObject, .at, .indirectObject),
    ]

    public let synonyms: [Verb] = [.wave, .brandish]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "WAVE" command.
    ///
    /// This action validates prerequisites and handles waving attempts on different types
    /// of objects. Generally provides descriptive responses following ZIL traditions.
    /// Can optionally wave at a target specified in the indirect object.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Wave requires a direct object (what to wave)
        guard let object = try await context.itemDirectObject() else {
            throw ActionResponse.feedback(
                context.msg.wave()
            )
        }

        guard context.hasPreposition(.at, .to) else {
            throw await ActionResponse.feedback(
                context.msg.waveObject(object.withDefiniteArticle)
            )
        }

        if let recipient = try await context.itemIndirectObject() {
            return await ActionResult(
                context.msg.waveObjectAt(
                    object.withDefiniteArticle,
                    target: recipient.withDefiniteArticle
                )
            )
        }

        return try await ActionResult(
            object.response(
                object: context.msg.waveAtObject,
                character: context.msg.waveAtCharacter,
                enemy: context.msg.waveAtEnemy
            ),
            object.setFlag(.isTouched)
        )
    }
}
