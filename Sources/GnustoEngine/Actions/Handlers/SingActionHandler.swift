import Foundation

/// Handles the SING verb for singing, humming, or making musical sounds.
///
/// This is a humorous atmospheric command that provides entertaining responses
/// to player attempts to sing or make music. Based on ZIL tradition.
public struct SingActionHandler: ActionHandler {
    public init() {}

    public func process(
        context: ActionContext
    ) async throws -> ActionResult {
        ActionResult(
            context.message.singResponse()
        )
    }
}
