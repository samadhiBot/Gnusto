import Foundation

/// Represents an effect that should be rendered to the player.
///
/// Effects are the output of action processing and are rendered by the UI.
public enum Effect: Equatable, Sendable {
    /// Display text to the player
    case showText(String)

    /// Update the status line with the current game state
    case updateStatusLine(location: String, score: Int, moves: Int)

    /// Play a sound effect
    case playSound(String)

    /// Indicate the game has ended
    case endGame

    /// Request input from the player
    case requestInput(prompt: String)

    /// Update the player's inventory to show a new item
    case showInventoryChange(item: String, added: Bool)

    /// Highlight an object to draw attention to it
    case highlightObject(name: String)

    /// Instructs the dispatcher to perform an implicit look after this action completes.
    case triggerImplicitLook
}
