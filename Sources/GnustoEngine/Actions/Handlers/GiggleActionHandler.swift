import Foundation

/// Handles the GIGGLE verb for giggling, chuckling, or expressing amusement.
///
/// This is a humorous atmospheric command that provides entertaining responses
/// to player attempts to giggle or chuckle. Based on ZIL tradition.
public struct GiggleActionHandler: ActionHandler {
    public init() {}

    public func process(
        context: ActionContext
    ) async throws -> ActionResult {
        ActionResult(
            context.message.giggleResponse()
        )
    }
}
