import Foundation

/// Handles the "UNSCRIPT" command for stopping transcript recording.
/// Implements transcript recording mechanics following ZIL patterns.
public struct UnscriptActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.unscript)
    ]

    public let requiresLight: Bool = false

    public let consumesTurn: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "UNSCRIPT" command.
    ///
    /// Stops recording the transcript of the game session.
    /// Closes the transcript file and stops recording all game I/O.
    ///
    /// - Parameter context: The action context containing the command and engine.
    /// - Returns: An `ActionResult` containing confirmation message and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Check if scripting is currently active
        guard await context.engine.hasFlag(.isScripting) else {
            throw ActionResponse.feedback(
                context.msg.transcriptNotOn()
            )
        }

        // Get the transcript URL before stopping (it will be cleared)
        guard let url = await context.engine.transcriptURL else {
            throw ActionResponse.feedback(
                context.msg.transcriptError("Transcript URL not available")
            )
        }

        // Stop recording transcript
        await context.engine.stopTranscript()

        return ActionResult(
            context.msg.transcriptEnded(url.gnustoPath),
            await context.engine.clearGlobal(.isScripting)
        )
    }
}
