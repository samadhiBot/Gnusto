import Foundation

/// Represents an action that can be taken in the game.
///
/// Actions are dispatched to the engine for processing and may result in state changes
/// and effects.
public enum Action: Equatable {
    /// A standard game command, mapped to the engine's UserInput structure.
    case command(UserInput)

    /// A scheduled event that should be triggered
    case event(String)

    /// A custom action defined by the game
    case custom(String, ActionContext)

    /// End the game with the specified state
    case gameOver(World.State)

    /// Wait/pass time for the specified number of turns
    case wait(Int)
}
