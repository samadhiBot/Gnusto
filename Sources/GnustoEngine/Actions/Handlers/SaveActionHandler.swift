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

    /// Validates the "SAVE" command.
    /// Save requires no specific validation and always proceeds.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {

        // No validation needed for SAVE
    /// Processes the "SAVE" command.
    ///
    /// Attempts to save the current game state. The actual save mechanism
    /// is handled by the GameEngine's save functionality.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing save confirmation or error message.
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

    /// Performs any post-processing after the save action completes.
    ///
    /// Currently no post-processing is needed for save.
    ///
    /// - Parameter context: The action context for the current action.
    public func postProcess(context: ActionContext) async throws {
        // No post-processing needed for save
    }
}
