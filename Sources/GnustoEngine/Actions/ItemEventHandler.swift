import Foundation

/// An item event handler.
public struct ItemEventHandler: Sendable {
    let handle: @Sendable (GameEngine, ItemEvent) async throws -> ActionResult?

    public init(
        _ handler: @Sendable @escaping (GameEngine, ItemEvent) async throws -> ActionResult?
    ) {
        self.handle = handler
    }
}

/// Represents the different events that can trigger an ItemEventHandler.
public enum ItemEvent: Sendable {
    /// Called before processing the player's command for the turn.
    /// The handler can potentially prevent the default command execution by returning an `ActionResult`.
    case beforeTurn(Command)

    /// Called after processing the player's command for the turn.
    case afterTurn(Command)

    /*
    /// Called when the item is first created or loaded into the game.
    case onInitialize

    /// Called when the item is destroyed or removed from the game.
    case onDestroy
     */
}
