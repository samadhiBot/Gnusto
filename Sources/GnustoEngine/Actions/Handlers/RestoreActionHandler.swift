import Foundation

/// Handles the "RESTORE" command for restoring saved game state.
/// Provides game restore functionality following ZIL traditions.
public struct RestoreActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb)
    ]

    public let verbs: [Verb] = [.restore, .load]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods
    public init() {}

    /// Processes the "RESTORE" command.
    ///
    /// Attempts to restore a previously saved game state. The actual restore mechanism
    /// is handled by the GameEngine's restore functionality.
    public func process(
        command: Command,
        engine: GameEngine
    ) async throws -> ActionResult {
        do {
            // Request the engine to restore the game
            try await engine.restoreGame()
            return ActionResult(
                engine.messenger.gameRestored()
            )
        } catch {
            // If restore fails, provide appropriate error message
            return ActionResult(
                engine.messenger.restoreFailed(error: error.localizedDescription)
            )
        }
    }
}
