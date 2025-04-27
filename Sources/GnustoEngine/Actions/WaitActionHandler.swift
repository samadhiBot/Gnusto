import Foundation

/// Action handler for the WAIT verb.
struct WaitActionHandler: EnhancedActionHandler {

    // Removed original perform method
    // func perform(command: Command, engine: GameEngine) async throws {
    //     await engine.output("Time passes.")
    //     // Waiting usually just consumes a turn, no further state change needed here.
    // }

    // Implement the required process method
    func process(
        command: Command,
        engine: GameEngine
    ) async throws -> ActionResult {
        // Waiting is always successful and produces a standard message.
        // It doesn't change state or cause side effects directly.
        return ActionResult(
            success: true,
            message: "Time passes.",
            stateChanges: [],
            sideEffects: []
        )
    }

    // We rely on the default implementations for validate() and postProcess().
    // The default postProcess will print the message from the ActionResult.
}
