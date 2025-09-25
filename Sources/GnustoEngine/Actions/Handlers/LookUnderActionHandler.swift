import Foundation

/// Handles the LOOK UNDER verb.
///
/// The ZIL equivalent is the `V-LOOK-UNDER` routine. This action represents the player
/// attempting to look underneath an object.
public struct LookUnderActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .under, .directObject),
        .match(.verb, .beneath, .directObject),
        .match(.verb, .below, .directObject),
    ]

    public let synonyms: [Verb] = [.look, .peek]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "LOOK UNDER" command.
    ///
    /// This action validates prerequisites and handles looking underneath objects.
    /// Checks that the item exists and is accessible, then provides appropriate messaging.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Get direct object (with automatic reachability checking)
        guard let targetItem = try await context.itemDirectObject() else {
            throw ActionResponse.doWhat(context)
        }

        // Determine appropriate message - for now, use generic message for all objects
        let message = await context.msg.nothingOfInterestUnder(
            targetItem.withDefiniteArticle
        )

        return await ActionResult(
            message,
            targetItem.setFlag(.isTouched)
        )
    }
}
