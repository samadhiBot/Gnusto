import Foundation

/// Action handler for the SMELL verb (default behavior).
struct SmellActionHandler: ActionHandler {
    func validate(context: ActionContext) async throws {
        // No validation needed for default SMELL.
    }

    func process(context: ActionContext) async throws -> ActionResult {
        if context.command.directObject == nil {
            ActionResult("You smell nothing unusual.")
        } else {
            // If smelling a specific item, give a generic response.
            // Specific items could be handled by ItemActionHandler or custom handlers.
            ActionResult("That smells about average.")
        }
    }
}
