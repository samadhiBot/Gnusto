import Foundation

/// Action handler for the SMELL verb (default behavior).
struct SmellActionHandler: ActionHandler {
    func perform(command: Command, engine: GameEngine) async throws {
        if command.directObject == nil {
            await engine.output("You smell nothing unusual.")
        } else {
            // If smelling a specific item, give a generic response.
            // Specific items could be handled by onExamineItem or custom ActionHandlers.
            await engine.output("That smells about average.")
        }
    }
}
