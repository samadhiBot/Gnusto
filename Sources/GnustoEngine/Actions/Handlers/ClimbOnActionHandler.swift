import Foundation

/// Handles the CLIMB ON verb (synonyms: SIT ON, STAND ON).
///
/// The ZIL equivalent is the `V-CLIMB-ON` routine. This action represents the player
/// attempting to climb onto or sit on an object.
public struct ClimbOnActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.climb, .on, .directObject),
        .match(.get, .on, .directObject),
        .match(.sit, .on, .directObject),
        .match(.mount, .directObject),
    ]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the climb on action for the given context.
    ///
    /// This method handles attempts to climb onto, sit on, or mount objects. It first
    /// validates that a target object is specified, then applies the default behavior
    /// of preventing climbing on most objects unless specifically overridden.
    ///
    /// - Parameter context: The action context containing the command and target object
    /// - Returns: An `ActionResult` with the action outcome
    /// - Throws: `ActionResponse.doWhat` if no target object is specified
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let targetItem = try await context.itemDirectObject() else {
            // General climbing (no object)
            throw ActionResponse.doWhat(context)
        }

        // Default behavior: You can't climb on most things
        return await ActionResult(
            await context.msg.cannotDo(
                context.command,
                item: targetItem.withDefiniteArticle
            ),
            targetItem.setFlag(.isTouched)
        )
    }
}
