import Foundation

/// Handles the "SAVE" command for saving game state.
/// Provides game save functionality following ZIL traditions.
public struct SaveActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb)
    ]

    public let synonyms: [Verb] = [.save]

    public let requiresLight: Bool = false

    public let consumesTurn: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "SAVE" command.
    ///
    /// Attempts to save the current game state. The actual save mechanism
    /// is handled by the GameEngine's save functionality.
    public func process(context: ActionContext) async throws -> ActionResult {
        do {
            // Request the engine to save the game
            let saveURL = try await context.engine.saveGame()
            return ActionResult(
                context.msg.gameSaved(saveURL.gnustoPath)
            )
        } catch {
            // If save fails, provide appropriate error message
            return ActionResult(
                context.msg.saveFailed(error.localizedDescription)
            )
        }
    }
}
