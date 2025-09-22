import Foundation

/// Handles the RAISE verb (synonym: LIFT).
///
/// The ZIL equivalent is the `V-RAISE` routine. This action represents the player
/// attempting to lift or raise an object.
public struct RaiseActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject)
    ]

    public let synonyms: [Verb] = [.raise, .lift, .hoist]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the raise action.
    ///
    /// - Parameter context: The action context containing the command and game state.
    /// - Returns: An `ActionResult` with the action outcome.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Raise requires a direct object (what to raise)
        guard let item = try await context.itemDirectObject() else {
            throw ActionResponse.doWhat(context)
        }

        // Default behavior: You can't raise most things
        return await ActionResult(
            context.msg.almostDo(
                context.verb,
                item: item.withDefiniteArticle
            ),
            item.setFlag(.isTouched)
        )
    }
}
