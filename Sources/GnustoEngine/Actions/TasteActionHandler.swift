import Foundation

/// Action handler for the TASTE verb (default behavior).
struct TasteActionHandler: EnhancedActionHandler {

    func validate(command: Command, engine: GameEngine) async throws {
        guard command.directObject != nil else {
            throw ActionError.customResponse("Taste what?")
        }
        // Basic TASTE doesn't need reachability check by default.
    }

    func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Generic response. Tasting specific items (like food) would need custom logic.
        return ActionResult(
            success: true,
            message: "That tastes about average."
        )
    }
}
