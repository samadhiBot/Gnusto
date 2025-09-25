import Foundation

/// Handles the "WAIT" command, allowing the player to pass a turn without performing
/// any specific action other than advancing game time.
public struct WaitActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb)
    ]

    public let synonyms: [Verb] = [.wait, "z"]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "WAIT" command.
    ///
    /// This action always succeeds and results in a generic message indicating that time
    /// has passed. It does not directly cause any state changes or side effects beyond
    /// advancing the game turn, which is handled by the `GameEngine`.
    public func process(context: ActionContext) async throws -> ActionResult {
        ActionResult(
            context.msg.timePasses()
        )
    }
}
