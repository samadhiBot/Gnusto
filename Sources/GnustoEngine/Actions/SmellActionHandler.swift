import Foundation

/// Action handler for the SMELL verb (default behavior).
struct SmellActionHandler: EnhancedActionHandler {

    func validate(command: Command, engine: GameEngine) async throws {
        // No validation needed for default SMELL.
    }

    func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        let message: String
        if command.directObject == nil {
            message = "You smell nothing unusual."
        } else {
            // If smelling a specific item, give a generic response.
            // Specific items could be handled by ObjectActionHandler or custom handlers.
            message = "That smells about average."
        }

        return ActionResult(
            success: true,
            message: message
        )
    }
}
