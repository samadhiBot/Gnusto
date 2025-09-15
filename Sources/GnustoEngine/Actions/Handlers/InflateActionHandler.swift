import Foundation

/// Handles the "INFLATE" command for inflating objects like balloons, rafts, life preservers, etc.
/// Implements inflation mechanics following ZIL patterns.
public struct InflateActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb, .directObject, .with, .indirectObject),
        .match(.blow, .up, .directObject),
        .match(.blow, .up, .directObject, .with, .indirectObject),
    ]

    public let synonyms: [Verb] = [.inflate]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "INFLATE" command.
    ///
    /// Handles inflating objects. If the object is already inflated, provides
    /// an appropriate message. If it can be inflated, sets the `.isInflated` flag
    /// and provides confirmation.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let item = try await context.itemDirectObject() else {
            // Deflate requires a direct object (what to deflate)
            throw ActionResponse.doWhat(context)
        }

        // Check if item is inflatable (which means it can also be deflated)
        guard await item.hasFlag(.isInflatable) else {
            throw ActionResponse.cannotDo(context, item)
        }

        // Check if currently inflated
        let message =
            if await item.hasFlag(.isInflated) {
                await context.msg.alreadyDone(
                    context.command,
                    item: item.withDefiniteArticle
                )
            } else {
                await context.msg.inflateSuccess(item.withDefiniteArticle)
            }

        return try await ActionResult(
            message,
            item.setFlag(.isTouched),
            item.setFlag(.isInflated)
        )
    }
}
