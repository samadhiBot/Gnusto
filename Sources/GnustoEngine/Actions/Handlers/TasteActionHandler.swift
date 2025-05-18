import Foundation

/// Action handler for the TASTE verb (default behavior).
struct TasteActionHandler: ActionHandler {

    func validate(context: ActionContext) async throws {
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.custom("Taste what?")
        }
        guard case .item(_) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can only taste items.")
        }
        // Basic TASTE doesn't need further validation like reachability by default.
    }

    func process(context: ActionContext) async throws -> ActionResult {
        // Validate ensures directObject is an item if present.
        // Generic response. Tasting specific items (like food) would need custom logic.
        return ActionResult("That tastes about average.")
    }
}
