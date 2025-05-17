import Foundation

/// Action handler for the SMELL verb (default behavior).
struct SmellActionHandler: ActionHandler {
    func validate(context: ActionContext) async throws {
        // If a direct object is provided, it should be an item.
        if let directObjectRef = context.command.directObject {
            guard case .item(_) = directObjectRef else {
                throw ActionResponse.prerequisiteNotMet("You can only smell items directly.")
            }
            // Further validation (existence, reachability) could be added if desired,
            // but default SMELL is often lenient.
        }
    }

    func process(context: ActionContext) async throws -> ActionResult {
        if let directObjectRef = context.command.directObject {
            // Validate should have ensured this is an .item if directObjectRef is not nil.
            // We don't need the itemID itself for the generic response.
            guard case .item(_) = directObjectRef else {
                // This case should ideally be caught by validate.
                return ActionResult("You can't smell that.")
            }
            // If smelling a specific item, give a generic response.
            // Specific items could be handled by ItemActionHandler or custom handlers.
            return ActionResult("That smells about average.")
        } else {
            return ActionResult("You smell nothing unusual.")
        }
    }
}
