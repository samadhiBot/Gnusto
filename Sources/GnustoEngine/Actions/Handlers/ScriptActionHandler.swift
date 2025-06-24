import Foundation

/// Handles the "SCRIPT" command for starting transcript recording.
/// Implements transcript recording mechanics following ZIL patterns.
public struct ScriptActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let verbID: VerbID = .script

    public let syntax: [SyntaxRule] = [
        .match(.verb)
    ]

    public let synonyms: [VerbID] = []

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Validates the "SCRIPT" command.
    ///
    /// SCRIPT requires no specific validation and can generally be executed.
    public func validate(context: ActionContext) async throws {
        // Check if scripting is already active
        if await context.engine.hasGlobal(.isScripting) {
            throw ActionResponse.prerequisiteNotMet(
                context.message.scriptAlreadyOn()
            )
        }
    }

    /// Processes the "SCRIPT" command.
    ///
    /// Starts recording a transcript of the game session.
    /// In a full implementation, this would prompt for a filename and begin recording.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing confirmation message and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        // In a full implementation, this would:
        // 1. Prompt for filename
        // 2. Open transcript file
        // 3. Begin recording all input/output
        // For now, we just set the flag and provide feedback

        return ActionResult(
            message: """
                Enter a file name.
                Default is "transcript":
                [Transcript recording started]
                """,
            changes: [
                await context.engine.setGlobal(.isScripting, to: true)
            ]
        )
    }

    /// Performs any post-processing after the script command.
    ///
    /// Currently no post-processing is needed for script.
    ///
    /// - Parameter context: The action context for the current action.
    public func postProcess(context: ActionContext, result: ActionResult) async throws {
        // No post-processing needed for script
    }
}
