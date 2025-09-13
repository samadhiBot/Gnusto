import Foundation

/// Handles the "POUR" command for pouring liquids on or into objects.
/// Implements pouring mechanics following ZIL patterns for liquid manipulation.
public struct PourActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb),
        .match(.verb, .directObject),
        .match(.verb, .directObject, .on, .indirectObject),
    ]

    public let synonyms: [Verb] = [.pour, .spill]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "POUR" command.
    ///
    /// Handles pouring attempts with different types of liquids and targets.
    /// Provides appropriate responses following ZIL traditions.
    ///
    /// - Parameter command: The command being processed.
    /// - Parameter engine: The game context.engine.
    /// - Returns: An `ActionResult` with appropriate pouring message and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Pour requires a direct object (what to pour)
        guard let source = try await context.itemDirectObject(
            failureMessage: context.msg.pourFail()
        ) else {
            throw ActionResponse.doWhat(context)
        }

        // Pour requires an indirect object (what to pour on)
        guard let targetItem = try await context.itemIndirectObject(
            playerMessage: context.msg.pourItemOnSelf(source.withDefiniteArticle),
            failureMessage: context.msg.pourTargetFail()
        ) else {
            throw ActionResponse.feedback(
                await context.msg.pourItemOnWhat(source.withDefiniteArticle)
            )
        }

        // Cannot pour something on itself
        if source.id == targetItem.id {
            throw ActionResponse.feedback(
                context.msg.pourCannotPourItself()
            )
        }

        return ActionResult(
            await context.msg.pourItemOn(
                source.withDefiniteArticle,
                target: targetItem.withDefiniteArticle
            ),
            try await source.setFlag(.isTouched),
            try await targetItem.setFlag(.isTouched)
        )
    }
}
