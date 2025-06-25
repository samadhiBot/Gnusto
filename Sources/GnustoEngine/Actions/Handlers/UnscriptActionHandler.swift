import Foundation

/// Handles the "UNSCRIPT" command for stopping transcript recording.
/// Implements transcript recording mechanics following ZIL patterns.
public struct UnscriptActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.unscript)
    ]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Validates the "UNSCRIPT" command.
    ///
    /// UNSCRIPT requires that scripting is currently active.
        public func process(
        command: Command,
        engine: GameEngine
    ) async throws -> ActionResult {

        // Check if scripting is currently active
        if !(await engine.hasGlobal(.isScripting)) {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.scriptNotOn()
            )
        }
    /// Processes the "UNSCRIPT" command.
    ///
    /// Stops recording the transcript of the game session.
    /// In a full implementation, this would close the transcript file and stop recording.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing confirmation message and state changes.
        // In a full implementation, this would:
        // 1. Close the transcript file
        // 2. Stop recording input/output
        // 3. Provide feedback about the saved transcript
        // For now, we just clear the flag and provide feedback

        return ActionResult(
            "🤡 [Transcript recording ended]",
            await engine.clearGlobal(.isScripting)
        )
    }
}
