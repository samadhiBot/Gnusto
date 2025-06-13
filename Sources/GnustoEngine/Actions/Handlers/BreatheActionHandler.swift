import Foundation

/// Handles the "BREATHE" command, an atmospheric command that provides varied responses.
/// In ZIL traditions, this is a simple command that doesn't require objects.
public struct BreatheActionHandler: ActionHandler {
    public init() {}

    /// Validates the "BREATHE" command.
    ///
    /// This method ensures that no direct or indirect objects are specified,
    /// as breathing is a standalone atmospheric action.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: `ActionResponse.prerequisiteNotMet` if objects are specified.
    public func validate(context: ActionContext) async throws {
        // Breathe should not take any objects
        if let _ = context.command.directObject {
            throw ActionResponse.prerequisiteNotMet("You can't breathe that.")
        }

        if let _ = context.command.indirectObject {
            throw ActionResponse.prerequisiteNotMet("You can't breathe that.")
        }
    }

    /// Processes the "BREATHE" command.
    ///
    /// Provides varied atmospheric responses based on the current game state.
    /// No state changes are made - this is purely a flavor command.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with an atmospheric message.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Provide varied responses for atmospheric effect
        let responses = [
            "You breathe in deeply, feeling refreshed.",
            "You take a slow, calming breath.",
            "The air fills your lungs. You're glad that you can breathe.",
            "You inhale deeply, then exhale slowly.",
            "You breathe in the love... and blow out the jive.",
        ]

        let selectedResponse = await context.engine.randomElement(in: responses) ?? responses[0]
        return ActionResult(selectedResponse)
    }

    /// Performs any post-processing after the "BREATHE" command.
    ///
    /// Currently no post-processing is needed for breathing.
    ///
    /// - Parameter context: The processed `ActionContext`.
    /// - Returns: The context unchanged.
    public func postProcess(context: ActionContext) async -> ActionContext {
        return context
    }
}
