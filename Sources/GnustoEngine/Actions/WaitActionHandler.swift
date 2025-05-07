import Foundation

/// Action handler for the WAIT verb.
struct WaitActionHandler: ActionHandler {

    // Removed original perform method
    // func perform(context: ActionContext) async throws {
    //     await context.engine.output("Time passes.")
    //     // Waiting usually just consumes a turn, no further state change needed here.
    // }

    // Implement the required process method
    func process(context: ActionContext) async throws -> ActionResult {
        // Waiting is always successful and produces a standard message.
        // It doesn't change state or cause side effects directly.
        return ActionResult(
            success: true,
            message: "Time passes.",
            stateChanges: []
        )
    }

    // We rely on the default implementations for validate() and postProcess().
    // The default postProcess will print the message from the ActionResult.
}
