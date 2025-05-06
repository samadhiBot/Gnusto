import Foundation

/// Action handler for the TASTE verb (default behavior).
struct TasteActionHandler: EnhancedActionHandler {

    func validate(context: ActionContext) async throws {
        guard context.command.directObject != nil else {
            throw ActionError.customResponse("Taste what?")
        }
        // Basic TASTE doesn't need reachability check by default.
    }

    func process(context: ActionContext) async throws -> ActionResult {
        // Generic response. Tasting specific items (like food) would need custom logic.
        return ActionResult(
            success: true,
            message: "That tastes about average."
        )
    }
}
