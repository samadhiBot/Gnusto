import Foundation

/// Handles the "HELP" command for displaying game help information.
/// Provides basic interactive fiction command guidance following ZIL traditions.
public struct HelpActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb)
    ]

    public let synonyms: [Verb] = [.help]

    public let requiresLight: Bool = false

    public let consumesTurn: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "HELP" command.
    ///
    /// Displays basic help information about common interactive fiction commands.
    /// Games can override this with custom help via ItemEventHandlers or custom handlers.
    public func process(context: ActionContext) async throws -> ActionResult {
        ActionResult(
            context.msg.help()
        )
    }
}
