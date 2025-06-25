import Foundation

/// Handles the "LISTEN" command, providing a generic response.
///
/// By default, listening doesn't produce any specific information. Game developers can
/// customize listening behavior by providing custom `ItemEventHandler` or
/// `LocationEventHandler` implementations for specific items or locations if special
/// sounds should be heard.
public struct ListenActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb),
        .match(.verb, .to, .directObject),
    ]

    public let verbs: [VerbID] = [.listen]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Validates the "LISTEN" command.
    /// Currently, listen requires no specific validation.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {

        // No validation needed for LISTEN.
    /// Processes the "LISTEN" command.
    ///
    /// This action typically results in a message indicating that nothing unusual is heard.
    /// Game-specific sounds can be implemented via more specific handlers.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with a default message.
        return ActionResult(
            engine.messenger.youHearNothingUnusual()
        )
    }
}
