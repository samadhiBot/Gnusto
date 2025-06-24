import Foundation

/// Handles the "xyzzy" command, a classic adventure game easter egg.
public struct XyzzyActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb)
    ]

    public let synonyms: [VerbID] = [.xyzzy]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    // No 'validate' or 'postProcess' needed, default implementations are sufficient.

    public func process(
        context: ActionContext
    ) async throws -> ActionResult {
        // The "xyzzy" command traditionally does not print via the IOHandler directly
        // in the handler, but rather returns an ActionResult with the message.
        // It also doesn't consume a turn, which is handled by the GameEngine based on
        // the ActionResult (implicitly, if no state changes/side effects that imply a turn).
        // For now, we'll return an action result with the message.
        // The 'tookTurn: false' aspect will be inherently handled if the ActionResult
        // doesn't lead to game time advancement.
        return ActionResult(
            message: "A hollow voice says \"Fool.\"",
            changes: [],
            effects: []
        )
    }
}
