import Foundation

/// Handles the "BRIEF" command for setting brief description mode.
/// Controls verbosity of location descriptions following ZIL traditions.
public struct BriefActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb)
    ]

    public let synonyms: [Verb] = [.brief]

    public let requiresLight: Bool = false

    public let consumesTurn: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "BRIEF" command.
    ///
    /// Sets the game to brief mode, where location descriptions are only shown
    /// when entering a location for the first time or when explicitly looking.
    public func process(context: ActionContext) async throws -> ActionResult {
        await ActionResult(
            context.msg.briefMode(),
            context.engine.clearFlag(.isVerboseMode)
        )
    }
}
