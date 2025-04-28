import Foundation

/// Action handler for the TASTE verb (default behavior).
struct TasteActionHandler: ActionHandler {
    func perform(command: Command, engine: GameEngine) async throws {
        guard command.directObject != nil else {
            await engine.ioHandler.print("Taste what?")
            return
        }
        // Generic response. Tasting specific items (like food) would need custom logic.
        await engine.ioHandler.print("That tastes about average.")
    }
}
