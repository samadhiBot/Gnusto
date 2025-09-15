import Foundation

/// Handles the "xyzzy" command, a classic adventure game easter egg.
public struct XyzzyActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb)
    ]

    public let synonyms: [Verb] = [.xyzzy]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "XYZZY" command.
    ///
    /// This classic adventure game easter egg provides a nostalgic response to players
    /// who remember the original Adventure/Colossal Cave game.
    public func process(context: ActionContext) async throws -> ActionResult {
        return ActionResult(
            context.msg.xyzzyResponse()
        )
    }
}
