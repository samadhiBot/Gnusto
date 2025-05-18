import Foundation

/// Action handler for the LISTEN verb (default behavior).
struct ListenActionHandler: ActionHandler {

    func validate(context: ActionContext) async throws {
        // No validation needed for LISTEN.
    }

    func process(context: ActionContext) async throws -> ActionResult {
        // TODO: Could check for specific sounds defined in the room/location?
        return ActionResult("You hear nothing unusual.")
    }
}
