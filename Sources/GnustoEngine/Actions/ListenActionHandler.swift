import Foundation

/// Action handler for the LISTEN verb (default behavior).
struct ListenActionHandler: ActionHandler {
    func perform(command: Command, engine: GameEngine) async throws {
        await engine.output("You hear nothing unusual.")
        // TODO: Could check for specific sounds defined in the room/location?
    }
}
