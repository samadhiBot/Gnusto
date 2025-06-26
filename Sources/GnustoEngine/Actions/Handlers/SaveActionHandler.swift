import Foundation

/// Handles the "SAVE" command for saving game state.
/// Provides game save functionality following ZIL traditions.
public struct SaveActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb)
    ]

    public let verbs: [VerbID] = [.save]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "SAVE" command.
    ///
    /// Attempts to save the current game state. The actual save mechanism
    /// is handled by the GameEngine's save functionality.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        do {
            // Request the engine to save the game
            try await engine.saveGame()
            return ActionResult(
                engine.messenger.gameSaved()
            )
        } catch {
            // If save fails, provide appropriate error message
            return ActionResult(
                engine.messenger.saveFailed(error: error.localizedDescription)
            )
        }
    }
}
