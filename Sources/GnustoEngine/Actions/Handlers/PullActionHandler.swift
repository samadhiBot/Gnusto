import Foundation

/// Handles the "PULL" command for pulling objects.
/// Implements pulling mechanics following ZIL patterns, as a complement to PUSH.
public struct PullActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject)
    ]

    public let synonyms: [Verb] = [.pull]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "PULL" command.
    ///
    /// This action validates prerequisites and handles pulling objects. Most objects cannot
    /// be pulled effectively, but some specific items may have special pull behavior.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let item = try await context.itemDirectObject() else {
            throw ActionResponse.doWhat(context)
        }

        return try await ActionResult(
            item.response(
                object: context.msg.pullObject,
                character: context.msg.pullCharacter,
                enemy: context.msg.pullEnemy
            ),
            item.setFlag(.isTouched)
        )
    }
}
