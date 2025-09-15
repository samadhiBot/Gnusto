import Foundation

/// Handles the DANCE verb for dancing, boogieing, or expressing joy through movement.
///
/// This is a humorous atmospheric command that provides entertaining responses
/// to player attempts to dance. Based on ZIL tradition, including the classic
/// "Dancing is forbidden" response from Cloak of Darkness.
public struct DanceActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb),
        .match(.verb, .with, .directObject),
    ]

    public let synonyms: [Verb] = [.dance]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "DANCE" command.
    ///
    /// This action provides humorous responses to player attempts to dance.
    /// Can be used with or without a dance partner.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let other = try await context.itemDirectObject() else {
            // General dancing (no object)
            return ActionResult(
                context.msg.danceResponse()
            )
        }

        return try await ActionResult(
            other.response(
                object: context.msg.danceWith,
                character: context.msg.danceWithPartner,
                enemy: context.msg.danceWithEnemy
            ),
            other.setFlag(.isTouched)
        )
    }
}
