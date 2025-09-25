import Foundation

/// Handles the "VERBOSE" command for setting verbose description mode.
/// Controls verbosity of location descriptions following ZIL traditions.
public struct VerboseActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb)
    ]

    public let synonyms: [Verb] = [.verbose]

    public let requiresLight: Bool = false

    public let consumesTurn: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "VERBOSE" command.
    ///
    /// Sets the game to verbose mode, where full location descriptions are shown
    /// every time the player enters a location.
    public func process(context: ActionContext) async throws -> ActionResult {
        await ActionResult(
            context.msg.maximumVerbosity(),
            context.engine.setFlag(.isVerboseMode)
        )
    }
}
