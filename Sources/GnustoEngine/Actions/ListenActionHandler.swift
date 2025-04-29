import Foundation

/// Action handler for the LISTEN verb (default behavior).
struct ListenActionHandler: EnhancedActionHandler {

    func validate(command: Command, engine: GameEngine) async throws {
        // No validation needed for LISTEN.
    }

    func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // TODO: Could check for specific sounds defined in the room/location?
        return ActionResult(
            success: true,
            message: "You hear nothing unusual."
        )
    }
}
