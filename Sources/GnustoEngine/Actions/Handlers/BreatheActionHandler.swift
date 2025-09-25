import Foundation

/// Handles the "BREATHE" command, an atmospheric command that provides varied responses.
/// In ZIL traditions, this is a simple command that doesn't require objects.
public struct BreatheActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb),
        .match(.verb, .directObject),
        .match(.verb, .on, .directObject),
    ]

    public let synonyms: [Verb] = [.breathe]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "BREATHE" command.
    ///
    /// This action provides atmospheric responses to breathing. Can be used without objects
    /// for general breathing, or with objects for breathing on specific items.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let targetItem = try await context.itemDirectObject(
            universalMessage: { universal in
                // Can breathe air, but not other universals
                universal == .air ? context.msg.breatheResponse()
                                  : context.msg.cannotDoThat(context.command)
            }
        ) else {
            // Can breathe in general (usually)
            return ActionResult(
                context.msg.breatheResponse()
            )
        }

        // Can breathe on other items
        if context.hasPreposition(.on) {
            return await ActionResult(
                context.msg.breatheOnResponse(targetItem.withDefiniteArticle),
                targetItem.setFlag(.isTouched)
            )
        }

        // Generally cannot breathe other items
        throw ActionResponse.cannotDoThat(context)
    }
}
