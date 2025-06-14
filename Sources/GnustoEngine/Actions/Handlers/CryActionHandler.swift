import Foundation

/// Handles the CRY verb for weeping, sobbing, or expressing sadness.
///
/// This is a humorous atmospheric command that provides entertaining responses
/// to player attempts to cry or weep. Based on ZIL tradition.
public struct CryActionHandler: ActionHandler {
    public init() {}

    public func process(
        context: ActionContext
    ) async throws -> ActionResult {
        // Get random response from message provider
        let message = await context.engine.randomMessage(for: .cryResponses)
        return ActionResult(message)
    }
}
