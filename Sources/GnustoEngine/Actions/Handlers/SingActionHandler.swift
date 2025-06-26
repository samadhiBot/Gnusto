import Foundation

/// Handles the SING verb for singing, humming, or making musical sounds.
///
/// This is a humorous atmospheric command that provides entertaining responses
/// to player attempts to sing or make music. Based on ZIL tradition.
public struct SingActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb)
    ]

    public let verbs: [VerbID] = [.sing]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "SING" command.
    ///
    /// This action provides humorous responses to player attempts to sing or make music.
    /// A classic atmospheric command from ZIL traditions.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        return ActionResult(
            engine.messenger.singResponse()
        )
    }
}
