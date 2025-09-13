import Foundation

/// Handles the "DEFLATE" command for deflating previously inflated objects like balloons, rafts, etc.
/// Implements deflation mechanics following ZIL patterns.
public struct DeflateActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject)
    ]

    public let synonyms: [Verb] = [.deflate]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "DEFLATE" command.
    ///
    /// Handles deflating objects. If the object is not currently inflated, provides
    /// an appropriate message. If it is inflated, clears the `.isInflated` flag
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
                context.msg.deflateSuccess(await item.withDefiniteArticle)
            } else {
                context.msg.itemNotInflated(await item.withDefiniteArticle)
            }

        return try await ActionResult(
            message,
            item.setFlag(.isTouched),
            item.clearFlag(.isInflated)
        )
    }
}
