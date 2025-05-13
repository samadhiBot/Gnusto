import Foundation

/// Action handler for the QUIT verb.
struct QuitActionHandler: ActionHandler {

    // MARK: - ActionHandler Methods

    func validate(context: ActionContext) async throws {
        // No validation needed for QUIT.
    }

    func process(context: ActionContext) async throws -> ActionResult {
        // TODO: Implement confirmation? ("Are you sure you want to quit?")
        await context.engine.requestQuit()

        return ActionResult("Goodbye!")
    }
}
