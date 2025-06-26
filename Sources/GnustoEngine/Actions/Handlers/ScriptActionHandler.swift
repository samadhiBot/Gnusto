import Foundation

/// Handles the "SCRIPT" command for starting transcript recording.
/// Implements transcript recording mechanics following ZIL patterns.
public struct ScriptActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb)
    ]

    public let verbs: [VerbID] = [.script]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "SCRIPT" command.
    ///
    /// Starts recording a transcript of the game session.
    /// In a full implementation, this would prompt for a filename and begin recording.
    ///
    /// - Parameter command: The command being processed.
    /// - Parameter engine: The game engine.
    /// - Returns: An `ActionResult` containing confirmation message and state changes.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Check if scripting is already active
        if await engine.hasGlobal(.isScripting) {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.scriptAlreadyOn()
            )
        }

        // In a full implementation, this would:
        // 1. Prompt for filename
        // 2. Open transcript file
        // 3. Begin recording all input/output
        // For now, we just set the flag and provide feedback

        return ActionResult(
            """
            🤡 Enter a file name.
            Default is "transcript":
            [Transcript recording started]
            """,
            await engine.setGlobal(.isScripting, to: true)
        )
    }
}
