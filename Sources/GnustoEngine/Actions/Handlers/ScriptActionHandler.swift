import Foundation

/// Handles the "SCRIPT" command for starting transcript recording.
/// Implements transcript recording mechanics following ZIL patterns.
public struct ScriptActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb)
    ]

    public let synonyms: [Verb] = [.script]

    public let requiresLight: Bool = false

    public let consumesTurn: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "SCRIPT" command.
    ///
    /// Starts recording a transcript of the game session.
    /// Prompts for a filename and begins recording all game I/O to the transcript file.
    ///
    /// - Parameter context: The action context containing the command and engine.
    /// - Returns: An `ActionResult` containing confirmation message and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Check if scripting is already active
        if await context.engine.hasFlag(.isScripting) {
            guard let url = await context.engine.transcriptURL else {
                throw ActionResponse.feedback(
                    context.msg.transcriptError("Transcript URL not available")
                )
            }

            throw ActionResponse.feedback(
                context.msg.transcriptAlreadyOn(url.gnustoPath)
            )
        }

        // Start recording transcript
        do {
            try await context.engine.startTranscript()
            guard let url = await context.engine.transcriptURL else {
                throw ActionResponse.feedback(
                    context.msg.transcriptError("Failed to create transcript URL")
                )
            }

            return ActionResult(
                context.msg.transcriptStarted(url.gnustoPath),
                await context.engine.setFlag(.isScripting)
            )
        } catch {
            throw ActionResponse.feedback(
                context.msg.transcriptError(error.localizedDescription)
            )
        }
    }
}

extension URL {
    /// Returns a user-friendly path representation for Gnusto app files.
    ///
    /// This computed property extracts the portion of the file path that comes after
    /// "/Gnusto/" and presents it as a tilde-prefixed path for display purposes.
    ///
    /// - Returns: A string representing the path in the format "~/Gnusto/..."
    ///   If no "/Gnusto/" component is found, returns "~/Gnusto/" with an empty suffix.
    var gnustoPath: String {
        let path = path().split(separator: "/Gnusto/").last ?? ""
        return "~/Gnusto/\(path)"
    }
}
