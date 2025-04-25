import Foundation

/// Action handler for the WAIT verb.
struct WaitActionHandler: ActionHandler {
    func perform(command: Command, engine: GameEngine) async throws {
        await engine.output("Time passes.")
        // Waiting usually just consumes a turn, no further state change needed here.
    }
}
