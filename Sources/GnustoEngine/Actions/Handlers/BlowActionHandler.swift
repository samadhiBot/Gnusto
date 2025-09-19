import Foundation

/// Handles the "BLOW" command for blowing on objects like candles, fires, wind instruments, etc.
/// Implements blowing mechanics following ZIL patterns.
public struct BlowActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb, .on, .directObject),
    ]

    public let synonyms: [Verb] = [.blow, .puff]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "BLOW" command.
    ///
    /// Handles blowing on objects or general blowing. Special items like candles,
    /// fires, or wind instruments can have custom behavior via ItemEventHandlers.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let target = try await context.itemDirectObject() else {
            return ActionResult(
                context.msg.blow()
            )
        }

        return await ActionResult(
            context.msg.blowOn(
                target.withDefiniteArticle
            ),
            target.setFlag(.isTouched)
        )
    }
}
