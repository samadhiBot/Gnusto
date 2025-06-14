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
        if context.command.directObject != nil {
            let message = context.message(.cannotActOnThat(verb: "breathe"))
            throw ActionResponse.prerequisiteNotMet(message)
        }

        if context.command.indirectObject != nil {
            let message = context.message(.cannotActOnThat(verb: "breathe"))
            throw ActionResponse.prerequisiteNotMet(message)
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
        // Get random response from message provider
        let message = await context.engine.randomMessage(for: .breatheResponses)
        return ActionResult(message)
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
