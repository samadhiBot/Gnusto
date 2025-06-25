import Foundation

/// Handles the "BREATHE" command, an atmospheric command that provides varied responses.
/// In ZIL traditions, this is a simple command that doesn't require objects.
public struct BreatheActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb),
        .match(.verb, .on, .directObject),
    ]

    public let verbs: [VerbID] = [.breathe]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Validates the "BREATHE" command.
    ///
    /// This method ensures that no direct or indirect objects are specified,
    /// as breathing is a standalone atmospheric action.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: `ActionResponse.prerequisiteNotMet` if objects are specified.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {

        // Breathe should not take any objects
        if command.directObject != nil {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotDoThat(verb: "breathe")
            )
        }

        if command.indirectObject != nil {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotDoThat(verb: "breathe")
            )
        }
    /// Processes the "BREATHE" command.
    ///
    /// Provides varied atmospheric responses based on the current game state.
    /// No state changes are made - this is purely a flavor command.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with an atmospheric message.
        // Get random response from message provider
        return ActionResult(
            engine.messenger.breatheResponse()
        )
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
