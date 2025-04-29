import Foundation

/// Action handler for the QUIT verb.
struct QuitActionHandler: EnhancedActionHandler {

    // MARK: - EnhancedActionHandler Methods

    func validate(command: Command, engine: GameEngine) async throws {
        // No validation needed for QUIT.
    }

    func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // TODO: Implement confirmation? ("Are you sure you want to quit?")
        await engine.requestQuit()

        return ActionResult(
            success: true,
            message: "Goodbye!"
        )
    }
}
