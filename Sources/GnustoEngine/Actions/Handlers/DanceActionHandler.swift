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

    public let verbs: [VerbID] = [.dance]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    public func process(
        context: ActionContext
    ) async throws -> ActionResult {
        // Get random response from message provider
        ActionResult(
            context.message.danceResponse()
        )
    }
}
