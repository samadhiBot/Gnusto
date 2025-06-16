import Foundation

/// Handles the SCREAM verb for screaming, shrieking, or expressing alarm.
///
/// This is a humorous atmospheric command that provides entertaining responses
/// to player attempts to scream or shriek. Based on ZIL tradition.
public struct ScreamActionHandler: ActionHandler {
    public init() {}

    public func process(
        context: ActionContext
    ) async throws -> ActionResult {
        ActionResult(
            context.message.screamResponse()
        )
    }
}
