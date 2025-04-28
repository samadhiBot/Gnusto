import Foundation

/// Action handler for the QUIT verb.
struct QuitActionHandler: ActionHandler {
    func perform(command: Command, engine: GameEngine) async throws {
        // TODO: Implement confirmation? ("Are you sure you want to quit?")
        await engine.ioHandler.print("Goodbye!")
        await engine.requestQuit()
    }
}
